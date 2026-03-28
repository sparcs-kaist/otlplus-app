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
    static let base = "https://otl.sparcs.org/"

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

class OTLAPI {
    static let shared = OTLAPI()
    
    private var accessToken: String?
    private var refreshToken: String?
        
    private init() {}
    
    func setTokens(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    private var authHeaders: HTTPHeaders {
        var headers: HTTPHeaders = []
        if let token = accessToken {
            headers.add(.authorization(bearerToken: token))
        }
        return headers
    }
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        // Create a date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Replace this with the exact format you expect
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return decoder
    }()
    
    func getTimetables(year: Int, semester: Int, completion: @escaping (Result<[Timetables], Error>) -> Void) {
        let parameters: [String: Any] = ["year": year, "semester": semester]
        
        AF.request(URLs.apiTimetables, method: .get, parameters: parameters, headers: authHeaders).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let timetableData = try self.jsonDecoder.decode(TimetablesResponse.self, from: data)
                        completion(.success(timetableData.timetables))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func getTimetable(timetableId: Int, completion: @escaping (Result<Timetable, Error>) -> Void) {
        let url = URLs.apiTimetable.replacingOccurrences(of: "{timetable_id}", with: String(timetableId))
        
        AF.request(url, method: .get, headers: authHeaders).responseData { response in
            self.handleResponse(response, completion: completion)
        }
    }
    
    func getCurrentSemester(completion: @escaping (Result<Semester, Error>) -> Void) {
        AF.request(URLs.apiSemesterCurrent, method: .get, headers: authHeaders).responseData { response in
            self.handleResponse(response, completion: completion)
        }
    }

    func getMyTimetable(year: Int, semester: Int, completion: @escaping (Result<Timetable, Error>) -> Void) {
        let parameters: [String: Any] = ["year": year, "semester": semester]
                                                           
        AF.request(URLs.apiMyTimetable, method: .get, parameters: parameters, headers: authHeaders).responseData { response in
            self.handleResponse(response, completion: completion)
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
