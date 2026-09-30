//
//  OTLAPI.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 17/08/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import Foundation
import Alamofire

struct URLs {
    static let base = "https://otl.kaist.ac.kr/"

    static var sessionRefresh: String { base + "session/refresh" }
    static var apiMyTimetable: String { base + "api/v2/timetables/my-timetable" }
    static var apiTimetables: String { base + "api/v2/timetables" }
    static var apiTimetable: String { base + "api/v2/timetables/{timetable_id}"}
    static var apiSemesterCurrent: String { base + "api/v2/semesters/current" }
}

struct TimetablesResponse: Codable, Hashable {
    let timetables: [Timetables]
}

struct Timetables: Codable, Hashable {
    let id: Int
    let name: String
    let year: Int
    let semester: Int
    let timeTableOrder: Int
}

struct Timetable: Codable, Hashable {
    var lectures: [Lecture]
    var customBlocks: [WidgetCustomBlock] = []
    var hasCustomItems = true

    enum CodingKeys: String, CodingKey { case lectures, timetableItems, customBlocks = "custom_blocks" }
    init(lectures: [Lecture], customBlocks: [WidgetCustomBlock] = []) {
        self.lectures = lectures
        self.customBlocks = customBlocks
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lectures = try container.decode([Lecture].self, forKey: .lectures)
        hasCustomItems = container.contains(.timetableItems) || container.contains(.customBlocks)
        if container.contains(.timetableItems) {
            let items = try container.decodeIfPresent([WidgetCustomItem].self, forKey: .timetableItems) ?? []
            customBlocks = items.compactMap(\.data)
        } else {
            customBlocks = try container.decodeIfPresent([WidgetCustomBlock].self, forKey: .customBlocks) ?? []
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lectures, forKey: .lectures)
        try container.encode(customBlocks.map { WidgetCustomItem(kind: "custom", data: $0) }, forKey: .timetableItems)
    }
    var scheduleItems: [WidgetScheduleItem] {
        let lectureItems = lectures.map { WidgetScheduleItem(name: $0.name, subtitle: $0.subtitle, courseId: $0.courseId % 16, professors: $0.professors, classes: $0.classes.filter { $0.isValid }) }
        let customItems = customBlocks.map { block in
            WidgetScheduleItem(name: block.blockName, subtitle: "", courseId: (block.id % 16 * 3 + 7) % 16, professors: [], classes: block.times.filter { $0.isValid }.map {
                Classtime(day: $0.day, begin: $0.begin, end: $0.end, buildingCode: "", buildingName: "", roomName: block.place)
            })
        }
        return (lectureItems + customItems).filter { !$0.classes.isEmpty }
    }
}

struct WidgetCustomTime: Codable, Hashable {
    let day: Int
    let begin: Int
    let end: Int
    var isValid: Bool { (0...6).contains(day) && begin >= 0 && begin < end && end <= 1440 }
}
struct WidgetCustomBlock: Codable, Hashable {
    let id: Int
    let blockName: String
    let place: String
    let times: [WidgetCustomTime]
    enum CodingKeys: String, CodingKey { case id, blockName = "block_name", place, times, day, begin, end }
    init(id: Int, blockName: String, place: String, times: [WidgetCustomTime]) {
        self.id = id; self.blockName = blockName; self.place = place; self.times = times
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        blockName = try container.decode(String.self, forKey: .blockName)
        place = try container.decodeIfPresent(String.self, forKey: .place) ?? ""
        let decodedTimes = try container.decodeIfPresent([WidgetCustomTime].self, forKey: .times) ?? []
        if decodedTimes.isEmpty {
            times = [WidgetCustomTime(day: try container.decode(Int.self, forKey: .day),
                begin: try container.decode(Int.self, forKey: .begin), end: try container.decode(Int.self, forKey: .end))]
        } else {
            times = decodedTimes
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(blockName, forKey: .blockName)
        try container.encode(place, forKey: .place)
        try container.encode(times, forKey: .times)
    }
}
private struct WidgetCustomBlocksResponse: Decodable {
    let custom_blocks: [WidgetCustomBlock]
}
private struct WidgetCustomItem: Codable, Hashable {
    let kind: String
    let data: WidgetCustomBlock?
    enum CodingKeys: String, CodingKey { case kind, data }
    init(kind: String, data: WidgetCustomBlock?) { self.kind = kind; self.data = data }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(String.self, forKey: .kind)
        data = kind == "custom" ? try? container.decode(WidgetCustomBlock.self, forKey: .data) : nil
    }
}

struct WidgetScheduleItem {
    let name: String
    let subtitle: String
    let courseId: Int
    let professors: [Professor]
    let classes: [Classtime]
}

func widgetItemsForDay(timetable: Timetable?, day: Int) -> [(Int, WidgetScheduleItem)] {
    guard let timetable = timetable else { return [] }
    return timetable.scheduleItems.flatMap { item in
        item.classes.indices.filter { item.classes[$0].day == day }.map { ($0, item) }
    }.sorted { $0.1.classes[$0.0].begin < $1.1.classes[$1.0].begin }
}

func widgetCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    return calendar
}

func nextWidgetItem(timetable: Timetable, date: Date) -> (Int, WidgetScheduleItem)? {
    let calendar = widgetCalendar()
    let today = (calendar.component(.weekday, from: date) + 5) % 7
    let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    for offset in 0...7 {
        if let next = widgetItemsForDay(timetable: timetable, day: (today + offset) % 7).first(where: { offset != 0 || $0.1.classes[$0.0].begin >= minutes }) { return next }
    }
    return nil
}

struct WidgetTimeWindow {
    let startHour: Int
    let endHour: Int
}

func widgetTimeWindow(timetable: Timetable?, date: Date, visibleHours: Int = 8) -> WidgetTimeWindow {
    let hours = min(16, max(2, visibleHours))
    let calendar = widgetCalendar()
    let hour = calendar.component(.hour, from: date)
    let day = (calendar.component(.weekday, from: date) + 5) % 7
    let earliestToday = widgetItemsForDay(timetable: timetable, day: day).map { $0.1.classes[$0.0].begin / 60 }.min() ?? 9
    let preferredStart = hour < 9 ? (earliestToday < 9 ? max(earliestToday, hour - min(2, hours - 1)) : 9) : (hour >= 15 ? hour - min(2, hours - 1) : max(9, hour - (hours - 2)))
    let start = min(24 - hours, max(0, preferredStart))
    return WidgetTimeWindow(startHour: start, endHour: start + hours)
}

func remainingWidgetItems(timetable: Timetable?, date: Date) -> [(Int, WidgetScheduleItem)] {
    let calendar = widgetCalendar()
    let day = (calendar.component(.weekday, from: date) + 5) % 7
    let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    return widgetItemsForDay(timetable: timetable, day: day).filter { $0.1.classes[$0.0].end > minutes }
}

struct Lecture: Codable, Hashable {
    let id: Int
    let courseId: Int
    let classNo: String
    let name: String
    let subtitle: String
    let code: String
    let department: Department
    let type: String
    let limitPeople: Int
    let numPeople: Int
    let credit: Int
    let creditAU: Int
    let averageGrade: Double
    let averageLoad: Double
    let averageSpeech: Double
    let isEnglish: Bool
    let professors: [Professor]
    let classDuration: Int
    let expDuration: Int
    let classes: [Classtime]
    let examTimes: [Examtime]
}

struct Department: Codable, Hashable {
    let id: Int
    let name: String
}

struct Professor: Codable, Hashable {
    let id: Int
    let name: String
}

struct Classtime: Codable, Hashable {
    let day: Int
    let begin: Int
    let end: Int
    let buildingCode: String
    let buildingName: String
    let roomName: String
}

extension Classtime {
    var isValid: Bool { (0...6).contains(day) && begin >= 0 && begin < end && end <= 1440 }
    var place: String { [buildingCode.isEmpty ? nil : "(\(buildingCode))", roomName.isEmpty ? nil : roomName].compactMap { $0 }.joined(separator: " ") }
}

struct Examtime: Codable, Hashable {
    let day: Int
    let str: String
    let begin: Int
    let end: Int
}

struct Semester: Codable, Hashable {
    let year: Int
    let semester: Int
    let beginning: Date?
    let end: Date?
    let courseDesciptionSubmission: Date?
    let courseRegistrationPeriodStart: Date?
    let courseRegistrationPeriodEnd: Date?
    let courseAddDropPeriodEnd: Date?
    let courseDropDeadline: Date?
    let courseEvaluationDeadline: Date?
    let gradePosting: Date?
}

enum OTLAPIError: Error {
    case unauthorized
    case httpStatus(Int)
    case missingTokenPair
}

class OTLAPI {
    static let shared = OTLAPI()

    private var accessToken: String?
    private var refreshToken: String?
    private var isRefreshing = false
    private var refreshLeaseDescriptor: Int32?
    private var refreshCompletions: [(Bool) -> Void] = []

    private init() {}

    func setTokens(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    private var authHeaders: HTTPHeaders {
        var headers: HTTPHeaders = []
        headers.add(name: "Accept-Language", value: Locale.preferredLanguages.first ?? "ko")
        if let accessToken = accessToken {
            headers.add(.authorization(bearerToken: accessToken))
        }
        return headers
    }

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()

    func getTimetables(year: Int, semester: Int, completion: @escaping (Result<[Timetables], Error>) -> Void) {
        let parameters: [String: Any] = ["year": year, "semester": semester]
        request(URLs.apiTimetables, parameters: parameters) { (result: Result<TimetablesResponse, Error>) in
            completion(result.map(\.timetables))
        }
    }

    func getTimetable(timetableId: Int, completion: @escaping (Result<Timetable, Error>) -> Void) {
        let url = URLs.apiTimetable.replacingOccurrences(
            of: "{timetable_id}",
            with: String(timetableId)
        )
        request(url) { (result: Result<Timetable, Error>) in
            switch result {
            case .success(let timetable) where !timetable.hasCustomItems:
                self.request(url + "/custom-blocks") { (blocks: Result<WidgetCustomBlocksResponse, Error>) in
                    switch blocks {
                    case .success(let response):
                        var updated = timetable
                        updated.customBlocks = response.custom_blocks
                        updated.hasCustomItems = true
                        completion(.success(updated))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            default:
                completion(result)
            }
        }
    }

    func getCurrentSemester(completion: @escaping (Result<Semester, Error>) -> Void) {
        request(URLs.apiSemesterCurrent, completion: completion)
    }

    func getMyTimetable(year: Int, semester: Int, completion: @escaping (Result<Timetable, Error>) -> Void) {
        let parameters: [String: Any] = ["year": year, "semester": semester]
        request(URLs.apiMyTimetable, parameters: parameters, completion: completion)
    }

    private func request<T: Decodable>(
        _ url: String,
        parameters: Parameters? = nil,
        retriedAfterRefresh: Bool = false,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: authHeaders
        ).responseData { response in
            if response.response?.statusCode == 401 && !retriedAfterRefresh {
                self.refreshTokens { refreshed in
                    guard refreshed else {
                        completion(.failure(OTLAPIError.unauthorized))
                        return
                    }
                    self.request(
                        url,
                        parameters: parameters,
                        retriedAfterRefresh: true,
                        completion: completion
                    )
                }
                return
            }

            guard let statusCode = response.response?.statusCode else {
                if let error = response.error {
                    completion(.failure(error))
                } else {
                    completion(.failure(OTLAPIError.httpStatus(-1)))
                }
                return
            }
            guard (200..<300).contains(statusCode) else {
                completion(.failure(
                    statusCode == 401 ? OTLAPIError.unauthorized : OTLAPIError.httpStatus(statusCode)
                ))
                return
            }

            switch response.result {
            case .success(let data):
                do {
                    completion(.success(try self.jsonDecoder.decode(T.self, from: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func refreshTokens(completion: @escaping (Bool) -> Void) {
        refreshCompletions.append(completion)
        guard !isRefreshing else {
            return
        }
        isRefreshing = true

        guard let initialRefreshToken = refreshToken, !initialRefreshToken.isEmpty else {
            finishRefresh(success: false)
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let descriptor = WidgetRefreshLease.acquire()
            DispatchQueue.main.async {
                guard let descriptor = descriptor else {
                    self.finishRefresh(success: false)
                    return
                }
                self.refreshLeaseDescriptor = descriptor
                do {
                    guard let currentPair = try WidgetTokenVault.read() else {
                        self.finishRefresh(success: false)
                        return
                    }
                    if currentPair.refreshToken != initialRefreshToken {
                        self.accessToken = currentPair.accessToken
                        self.refreshToken = currentPair.refreshToken
                        self.finishRefresh(success: true)
                        return
                    }
                    self.performRefresh(attemptedRefreshToken: currentPair.refreshToken)
                } catch {
                    self.finishRefresh(success: false)
                }
            }
        }
    }

    private func performRefresh(attemptedRefreshToken: String) {
        var headers: HTTPHeaders = []
        headers.add(name: "Accept-Language", value: Locale.preferredLanguages.first ?? "ko")
        AF.request(
            URLs.sessionRefresh,
            method: .post,
            parameters: ["token": attemptedRefreshToken],
            encoding: JSONEncoding.default,
            headers: headers
        ).responseData { response in
            let statusCode = response.response?.statusCode
            guard statusCode == 200, case .success(let data) = response.result else {
                if let statusCode = statusCode, (400..<500).contains(statusCode) {
                    do {
                        let cleared = try WidgetTokenVault.clearIfRefreshTokenMatches(
                            attemptedRefreshToken
                        )
                        if cleared {
                            self.accessToken = nil
                            self.refreshToken = nil
                            self.finishRefresh(success: false)
                        } else {
                            self.useCurrentVaultPairAfterSupersededRefresh()
                        }
                    } catch {
                        self.finishRefresh(success: false)
                    }
                    return
                }
                self.finishRefresh(success: false)
                return
            }

            do {
                let pair = try self.jsonDecoder.decode(WidgetTokenPair.self, from: data)
                guard pair.isValid else {
                    let cleared = try WidgetTokenVault.clearIfRefreshTokenMatches(
                        attemptedRefreshToken
                    )
                    if cleared {
                        self.accessToken = nil
                        self.refreshToken = nil
                        self.finishRefresh(success: false)
                    } else {
                        self.useCurrentVaultPairAfterSupersededRefresh()
                    }
                    return
                }
                let written = try WidgetTokenVault.writeIfRefreshTokenMatches(
                    expectedRefreshToken: attemptedRefreshToken,
                    pair: pair
                )
                if written {
                    self.accessToken = pair.accessToken
                    self.refreshToken = pair.refreshToken
                    self.finishRefresh(success: true)
                } else {
                    self.useCurrentVaultPairAfterSupersededRefresh()
                }
            } catch {
                self.finishRefresh(success: false)
            }
        }
    }

    private func useCurrentVaultPairAfterSupersededRefresh() {
        do {
            guard let currentPair = try WidgetTokenVault.read() else {
                finishRefresh(success: false)
                return
            }
            accessToken = currentPair.accessToken
            refreshToken = currentPair.refreshToken
            finishRefresh(success: true)
        } catch {
            finishRefresh(success: false)
        }
    }

    private func finishRefresh(success: Bool) {
        if let descriptor = refreshLeaseDescriptor {
            WidgetRefreshLease.release(descriptor)
            refreshLeaseDescriptor = nil
        }
        let completions = refreshCompletions
        refreshCompletions.removeAll()
        isRefreshing = false
        completions.forEach { $0(success) }
    }
}
