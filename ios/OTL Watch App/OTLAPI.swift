//
//  OTLAPI.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/16/23.
//

import Foundation
import Alamofire
import SwiftUI

struct URLs {
    static let base = "https://otl.kaist.ac.kr/"

    static var sessionInfo: String { base + "session/info" }
    static var apiTimetable: String { base + "api/users/{user_id}/timetables" }
    static var apiSemester: String { base + "api/semesters" }
}

enum Days: Int {
    case mon = 0
    case tue = 1
    case wed = 2
    case thu = 3
    case fri = 4
    case sat = 5
    case sun = 6
}

struct LectureElement: Identifiable, Hashable {
    let id: Int
    let title: String
    let title_en: String
    let course: Int
    let old_code: String
    let class_no: String
    let year: Int
    let semester: Int
    let code: String
    let department: Int
    let department_code: String
    let department_name: String
    let department_name_en: String
    let type: String
    let type_en: String
    let limit: Int
    let num_people: Int
    let is_english: Bool
    let credit: Int
    let credit_au: Int
    let common_title: String
    let common_title_en: String
    let class_title: String
    let class_title_en: String
    let review_total_weight: Double
    let grade: Double
    let speech: Double
    let professors: [Professor]
    let classtime: Classtime
    let examtimes: [Examtime]
}

struct SemesterElement: Hashable, Codable {
    var year: Int
    var semester: Int
}

struct Timetable: Codable, Hashable {
    let id: Int
    var lectures: [Lecture]
}

struct Lecture: Codable, Hashable {
    let id: Int
    let title: String
    let title_en: String
    let course: Int
    let old_code: String
    let class_no: String
    let year: Int
    let semester: Int
    let code: String
    let department: Int
    let department_code: String
    let department_name: String
    let department_name_en: String
    let type: String
    let type_en: String
    let limit: Int
    let num_people: Int
    let is_english: Bool
    let credit: Int
    let credit_au: Int
    let common_title: String
    let common_title_en: String
    let class_title: String
    let class_title_en: String
    let review_total_weight: Double
    let grade: Double
    let speech: Double
    let professors: [Professor]
    let classtimes: [Classtime]
    let examtimes: [Examtime]
}

struct Professor: Codable, Hashable {
    let name: String
    let name_en: String
    let professor_id: Int
    let review_total_weight: Double
}

struct Classtime: Codable, Hashable {
    let building_code: String
    let classroom: String
    let classroom_en: String
    let classroom_short: String
    let classroom_short_en: String
    let room_name: String
    let day: Int
    let begin: Int
    let end: Int
}

struct Examtime: Codable, Hashable {
    let str: String
    let str_en: String
    let day: Int
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

struct UserInfo: Codable, Hashable {
    let id: Int
    let email: String
    let student_id: String
    let firstName: String
    let lastName: String
    let department: Department?
    let majors: [Department]
    let departments: [Department]
    let favorite_departments: [Department]
    let review_writable_lectures: [Lecture]
    let my_timetable_lectures: [Lecture]
}

struct Department: Codable, Hashable {
    let id: Int
    let name: String
    let name_en: String
    let code: String
}

@available(iOS 13.0, *)
func getColourForCourse(course: Int) -> Color {
    let colours = [
        [242.0, 206.0, 206.0],
        [244.0, 179.0, 174.0],
        [242.0, 188.0, 160.0],
        [240.0, 211.0, 171.0],
        [241.0, 225.0, 169.0],
        [244.0, 242.0, 179.0],
        [219.0, 244.0, 190.0],
        [190.0, 237.0, 215.0],
        [183.0, 226.0, 222.0],
        [201.0, 234.0, 244.0],
        [180.0, 211.0, 237.0],
        [185.0, 197.0, 237.0],
        [204.0, 198.0, 237.0],
        [216.0, 193.0, 240.0],
        [235.0, 202.0, 239.0],
        [244.0, 186.0, 219.0]
    ]
    
    return Color(red: Double(colours[course % 16][0]/255), green:Double(colours[course % 16][1]/255), blue:Double(colours[course % 16][2]/255))
}


enum WatchOTLAPIError: Error {
    case unauthorized
    case httpStatus(Int)
    case missingAccessToken
}

class OTLAPI {
    static let shared = OTLAPI()

    private var accessToken: String?

    private init() {
        loadStoredAccessToken()
    }

    private func loadStoredAccessToken() {
        accessToken = try? WatchTokenVault.read()?.accessToken
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

    func getTimetables(userID: String, year: Int, semester: Int, completion: @escaping (Result<[Timetable], Error>) -> Void) {
        let url = URLs.apiTimetable.replacingOccurrences(of: "{user_id}", with: userID)
        let parameters: [String: Any] = ["year": year, "semester": semester]
        request(url, parameters: parameters, completion: completion)
    }

    func getSemesters(completion: @escaping (Result<[Semester], Error>) -> Void) {
        request(URLs.apiSemester, completion: completion)
    }

    func getActualTimetable(userID: String, year: Int, semester: Int, completion: @escaping (Result<[Timetable], Error>) -> Void) {
        request(URLs.sessionInfo) { (result: Result<UserInfo, Error>) in
            completion(result.map { userInfo in
                let lectures = userInfo.my_timetable_lectures.filter {
                    $0.year == year && $0.semester == semester
                }
                return [Timetable(id: 0, lectures: lectures)]
            })
        }
    }

    func getActualSemesters(userID: String, completion: @escaping (Result<[SemesterElement], Error>) -> Void) {
        request(URLs.sessionInfo) { (result: Result<UserInfo, Error>) in
            completion(result.map { userInfo in
                let semesters = Set(userInfo.my_timetable_lectures.map {
                    SemesterElement(year: $0.year, semester: $0.semester)
                })
                return semesters.sorted { lhs, rhs in
                    lhs.year == rhs.year ? lhs.semester > rhs.semester : lhs.year > rhs.year
                }
            })
        }
    }

    private func request<T: Decodable>(
        _ url: String,
        parameters: Parameters? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        loadStoredAccessToken()
        guard accessToken != nil else {
            completion(.failure(WatchOTLAPIError.missingAccessToken))
            return
        }

        AF.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: authHeaders
        ).responseData { response in
            guard let statusCode = response.response?.statusCode else {
                if let error = response.error {
                    completion(.failure(error))
                } else {
                    completion(.failure(WatchOTLAPIError.httpStatus(-1)))
                }
                return
            }
            guard (200..<300).contains(statusCode) else {
                completion(.failure(
                    statusCode == 401
                        ? WatchOTLAPIError.unauthorized
                        : WatchOTLAPIError.httpStatus(statusCode)
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

}
