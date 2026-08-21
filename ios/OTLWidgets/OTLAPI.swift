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
        request(url, completion: completion)
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
