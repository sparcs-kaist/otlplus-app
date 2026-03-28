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
        
        API.getCurrentSemester() { result in
            switch result {
            case .success(let semester):
                // 1. Fetch all timetables summary to update the list in IntentHandler
                API.getTimetables(year: semester.year, semester: semester.semester) { result in
                    if case .success(let summaries) = result {
                        let encoder = JSONEncoder()
                        if let data = try? encoder.encode(summaries) {
                            sharedDefaults?.set(data, forKey: "timetableSummaries")
                        }
                    }
                    
                    // 2. Fetch the specific selected timetable
                    let identifier = configuration.nextClassTimetable?.identifier ?? "0"
                    let completionWithData: (Result<Timetable, Error>) -> Void = { result in
                        switch result {
                        case .success(let timetable):
                            let timetables = [timetable]
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
                            completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
                        }
                    }
                    
                    if identifier == "0" {
                        API.getMyTimetable(year: semester.year, semester: semester.semester, completion: completionWithData)
                    } else if let timetableId = Int(identifier) {
                        API.getTimetable(timetableId: timetableId, completion: completionWithData)
                    } else {
                        API.getMyTimetable(year: semester.year, semester: semester.semester, completion: completionWithData)
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
        
        API.getCurrentSemester() { result in
            switch result {
            case .success(let currentSemester):
                // 1. Fetch all timetables summary to update the list in IntentHandler
                API.getTimetables(year: currentSemester.year, semester: currentSemester.semester) { result in
                    if case .success(let summaries) = result {
                        let encoder = JSONEncoder()
                        if let data = try? encoder.encode(summaries) {
                            sharedDefaults?.set(data, forKey: "timetableSummaries")
                        }
                    }
                    
                    // 2. Fetch the specific selected timetable
                    let identifier = configuration.nextClassTimetable?.identifier ?? "0"
                    let completionWithData: (Result<Timetable, Error>) -> Void = { result in
                        switch result {
                        case .success(let timetable):
                            let timetables = [timetable]
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
                            let currentDate = Date()
                            entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
                            let timeline = Timeline(entries: entries, policy: .never)
                            completion(timeline)
                        }
                    }

                    if identifier == "0" {
                        API.getMyTimetable(year: currentSemester.year, semester: currentSemester.semester, completion: completionWithData)
                    } else if let timetableId = Int(identifier) {
                        API.getTimetable(timetableId: timetableId, completion: completionWithData)
                    } else {
                        API.getMyTimetable(year: currentSemester.year, semester: currentSemester.semester, completion: completionWithData)
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
