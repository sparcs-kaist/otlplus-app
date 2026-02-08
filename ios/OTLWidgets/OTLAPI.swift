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
    
    static var sessionInfo: String { base + "session/info" }
    static var apiTimetable: String { base + "api/users/{user_id}/timetables" }
    static var apiSemester: String { base + "api/semesters" }
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

class OTLAPI {
    static let shared = OTLAPI()
    
    private var refreshToken: String?
    private var accessToken: String?
        
    private init(refreshToken: String? = nil, accessToken: String? = nil) {
        self.refreshToken = refreshToken
        self.accessToken = accessToken
    }
    
    func setTokens(refreshToken: String?, accessToken: String?) {
        self.refreshToken = refreshToken
        self.accessToken = accessToken
    }
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        // Create a date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Replace this with the exact format you expect
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return decoder
    }()
    
    private var authHeaders: HTTPHeaders {
        var headers: HTTPHeaders = []
        if let token = accessToken {
            headers.add(.authorization(bearerToken: token))
        }
        if let refresh = refreshToken {
            headers.add(name: "X-Refresh-Token", value: refresh)
        }
        return headers
    }
    
    func getTimetables(userID: String, year: Int, semester: Int, completion: @escaping (Result<[Timetable], Error>) -> Void) {
        let url = URLs.apiTimetable.replacingOccurrences(of: "{user_id}", with: userID)
        let parameters: [String: Any] = ["year": year, "semester": semester]
        
        AF.request(url, method: .get, parameters: parameters, headers: authHeaders).responseData { response in
            self.handleResponse(response, completion: completion)
        }
    }
    
    func getSemesters(completion: @escaping (Result<[Semester], Error>) -> Void) {
        AF.request(URLs.apiSemester, method: .get, headers: authHeaders).responseData { response in
            self.handleResponse(response, completion: completion)
        }
    }

    func getActualTimetable(userID: String, year: Int, semester: Int, completion: @escaping (Result<[Timetable], Error>) -> Void) {
        AF.request(URLs.sessionInfo, method: .get, headers: authHeaders).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let userInfo = try self.jsonDecoder.decode(UserInfo.self, from: data)
                    let lecturesForSemester = userInfo.my_timetable_lectures.filter { $0.year == year && $0.semester == semester }
                    let timetable = Timetable(id: 0, lectures: lecturesForSemester)
                    completion(.success([timetable]))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func handleResponse<T: Decodable>(_ response: AFDataResponse<Data>, completion: @escaping (Result<T, Error>) -> Void) {
        switch response.result {
        case .success(let data):
            do {
                let decodedData = try jsonDecoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
