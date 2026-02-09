//
//  OTLWidgetBundle.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 28/03/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    typealias Entry = WidgetEntry
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let sharedDefaults = UserDefaults.init(suiteName: "group.org.sparcs.otl")
        
        let accessToken = sharedDefaults?.string(forKey: "accessToken")
        let refreshToken = sharedDefaults?.string(forKey: "refreshToken")
        let uid = sharedDefaults?.string(forKey: "uid")
        
        if (accessToken == nil || refreshToken == nil || uid == nil) {
            // Tokens or uid not found. Requires login.
            completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
            return
        }
        
        let API: OTLAPI = OTLAPI.shared
        API.setTokens(accessToken: accessToken, refreshToken: refreshToken)
        
        API.getSemesters() { result in
            switch result {
            case .success(let semesters):
                var semester: Semester {
                    var t: Semester? = nil
                    for s in semesters {
                        let now = Date()
                        t = (s.beginning! <= now && s.end! >= now) ? s : nil
                    }
                    
                    if (t == nil) {
                        let last: Semester = semesters.last!
                        t = Semester(year: last.year, semester: last.semester + 1, beginning: nil, end: nil, courseDesciptionSubmission: nil, courseRegistrationPeriodStart: nil, courseRegistrationPeriodEnd: nil, courseAddDropPeriodEnd: nil, courseDropDeadline: nil, courseEvaluationDeadline: nil, gradePosting: nil)
                    }

                    return t!
                }

                API.getActualTimetable(userID: uid!, year: semester.year, semester: semester.semester) { result in
                    switch result {
                    case .success(let timetable):
                        // handle my table data
                        API.getTimetables(userID: uid!, year: semester.year, semester: semester.semester) { result in
                            switch result {
                            case .success(var timetables):
                                // save timetable data
                                timetables.insert(contentsOf: timetable, at: 0)
                                let encoder = JSONEncoder()
                                encoder.outputFormatting = .withoutEscapingSlashes
                                do {
                                    let data = try encoder.encode(timetables)
                                    sharedDefaults?.set(String(data: data, encoding: .utf8), forKey: "timetables")
                                } catch {
                                    print(error)
                                }
                                let entryDate = Date()
                                let entry = WidgetEntry(date: entryDate, timetableData: timetables, configuration: configuration)
                                completion(entry)
                            case .failure(_):
                                // request failed, mostly network issue or needing of a new sessionid
                                completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
                            }
                        }
                    case .failure(_):
                        // request failed, mostly network issue or needing of a new sessionid
                        completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
                    }
                }
            case .failure(_):
                let decoder = JSONDecoder()
                do {
                    let data = try decoder.decode([Timetable].self, from: (sharedDefaults?.string(forKey: "timetables")?.data(using: .utf8)) ?? Data())
                    completion(WidgetEntry(date: Date(), timetableData: data, configuration: configuration))
                } catch {
                    completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
                }
            }
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        var entries: [WidgetEntry] = [WidgetEntry]()
        let sharedDefaults = UserDefaults.init(suiteName: "group.org.sparcs.otl")
        
        let accessToken = sharedDefaults?.string(forKey: "accessToken")
        let refreshToken = sharedDefaults?.string(forKey: "refreshToken")
        let uid = sharedDefaults?.string(forKey: "uid")
        
        if (accessToken == nil || refreshToken == nil || uid == nil) {
            // Tokens or uid not found. Requires login.
            let currentDate = Date()
            entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
            
            let timeline = Timeline(entries: entries, policy: .never)
            completion(timeline)
            return
        }
        
        let API: OTLAPI = OTLAPI.shared
        API.setTokens(accessToken: accessToken, refreshToken: refreshToken)
        
        API.getSemesters() { result in
            switch result {
            case .success(let semesters):
                var semester: Semester {
                    var t: Semester? = nil
                    for s in semesters {
                        let now = Date()
                        t = (s.beginning! <= now && s.end! >= now) ? s : nil
                    }
                    
                    if (t == nil) {
                        let last: Semester = semesters.last!
                        t = Semester(year: last.year, semester: last.semester + 1, beginning: nil, end: nil, courseDesciptionSubmission: nil, courseRegistrationPeriodStart: nil, courseRegistrationPeriodEnd: nil, courseAddDropPeriodEnd: nil, courseDropDeadline: nil, courseEvaluationDeadline: nil, gradePosting: nil)
                    }

                    return t!
                }
                
                API.getActualTimetable(userID: uid!, year: semester.year, semester: semester.semester) { result in
                    switch result {
                    case .success(let timetable):
                        API.getTimetables(userID: uid!, year: semester.year, semester: semester.semester) { result in
                            switch result {
                            case .success(var timetables):
                                // save timetable data
                                timetables.insert(contentsOf: timetable, at: 0)
                                let encoder = JSONEncoder()
                                encoder.outputFormatting = .withoutEscapingSlashes
                                do {
                                    let data = try encoder.encode(timetables)
                                    sharedDefaults?.set(String(data: data, encoding: .utf8), forKey: "timetables")
                                } catch {
                                    print(error)
                                }
                                
                                let currentDate = Date()
                                for minutesOffset in 0..<5 {
                                    let entryDate = Calendar.current.date(byAdding: .minute, value: minutesOffset*12, to: currentDate)!
                                    let entry = WidgetEntry(date: entryDate, timetableData: timetables, configuration: configuration)
                                    entries.append(entry)
                                }
                                
                                let timeline = Timeline(entries: entries, policy: .atEnd)
                                completion(timeline)
                            case .failure(_):
                                // request failed, mostly network issue or needing of a new sessionid
                                let currentDate = Date()
                                entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
                                
                                let timeline = Timeline(entries: entries, policy: .never)
                                completion(timeline)
                            }
                        }
                    case .failure(_):
                        let currentDate = Date()
                        entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
                        
                        let timeline = Timeline(entries: entries, policy: .never)
                        completion(timeline)
                    }
                }
            case .failure(_):
                let decoder = JSONDecoder()
                do {
                    let data = try decoder.decode([Timetable].self, from: (sharedDefaults?.string(forKey: "timetables")?.data(using: .utf8)) ?? Data())
                    
                    let currentDate = Date()
                    for minutesOffset in 0..<5 {
                        let entryDate = Calendar.current.date(byAdding: .minute, value: minutesOffset*12, to: currentDate)!
                        let entry = WidgetEntry(date: entryDate, timetableData: data, configuration: configuration)
                        entries.append(entry)
                    }
                    
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                } catch {
                    let currentDate = Date()
                    entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
                    
                    let timeline = Timeline(entries: entries, policy: .never)
                    completion(timeline)
                }
            }
        }
        
        
    }
}



struct WidgetEntry: TimelineEntry {
    let date: Date
    let timetableData: [Timetable]?
    let configuration: ConfigurationIntent
}


@main
struct OTLWidgetBundle : WidgetBundle {
    var body: some Widget {
        // Non-interactive widgets for iOS 15+
        NextClassWidget()
        TodayClassesWidget()
        WeekClassesWidget()
        
        // Lock Complications accessories for iOS 16+
        if #available(iOS 16.1, *) {
            NextClassAccessory()
            TimeInlineAccessory()
            LocationInlineAccessory()
        }
    }
}
