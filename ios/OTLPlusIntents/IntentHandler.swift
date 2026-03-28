//
//  IntentHandler.swift
//  OTLPlusIntents
//
//  Created by Soongyu Kwon on 02/05/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
        
    
    struct Timetable: Decodable, Hashable {
        let lectures: [Lecture]
    }

    struct Lecture: Decodable, Hashable {
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

    struct Department: Decodable, Hashable {
        let id: Int
        let name: String
    }

    struct Professor: Decodable, Hashable {
        let id: Int
        let name: String
    }

    struct Classtime: Decodable, Hashable {
        let day: Int
        let begin: Int
        let end: Int
        let buildingCode: String
        let buildingName: String
        let roomName: String
    }

    struct Examtime: Decodable, Hashable {
        let day: Int
        let str: String
        let begin: Int
        let end: Int
    }
    
    struct TimetableSummary: Decodable {
        let id: Int
        let name: String
    }

    func provideNextClassTimetableOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<NextClassTimetable>?, Error?) -> Void) {
        let sharedDefaults = UserDefaults.init(suiteName: "group.org.sparcs.otl")
        let data: [TimetableSummary]? = try? JSONDecoder().decode([TimetableSummary].self, from: (sharedDefaults?.data(forKey: "timetableSummaries")) ?? Data())
        var tables: [NextClassTimetable] = []
        
        tables.append(NextClassTimetable(identifier: "0", display: NSLocale.current.language.languageCode?.identifier == "en" ? "My Table" : "내 시간표"))
        
        if let summaries = data {
            for summary in summaries {
                tables.append(NextClassTimetable(identifier: "\(summary.id)", display: summary.name))
            }
        }
        
        let collection = INObjectCollection(items: tables)
        completion(collection, nil)
    }
    
}
