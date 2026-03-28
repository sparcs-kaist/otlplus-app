//
//  NextClassAccessory.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 22/07/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

@available(iOSApplicationExtension 16.0, *)
struct NextClassAccessoryEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                if let data = entry.timetableData, !data.isEmpty, !data[0].lectures.isEmpty {
                    VStack {
                        Image(systemName: "tablecells")
                            .font(.caption2)
                            .widgetAccentable()
                        Text(getBeginInTwelveHour(timetable: data[0], date: entry.date).0)
                            .font(.system(size: 15))
                            .fontWeight(.medium)
                        Text(getBeginInTwelveHour(timetable: data[0], date: entry.date).1)
                            .font(.system(size: 9))
                            .fontWeight(.medium)
                    }
                } else {
                    VStack {
                        Image(systemName: "tablecells")
                            .font(.caption2)
                            .widgetAccentable()
                        Text(LocalizedStringKey("nextclasswidget.nodata"))
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .padding(.top, 2)
                        Text("")
                            .font(.system(size: 9))
                            .fontWeight(.medium)
                    }
                }
            }
        case .accessoryRectangular:
            HStack {
                if let data = entry.timetableData, !data.isEmpty, !data[0].lectures.isEmpty {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 4) {
                            Circle()
                                .frame(width: 12, height: 12)
                            Text("\(getBegin(timetable: data[0], date: entry.date)) - \(getEnd(timetable: data[0], date: entry.date))")
                                .font(.headline)
                        }.offset(y: 7)
                            .widgetAccentable()
                        Text(getName(timetable: data[0], date: entry.date))
                            .font(.headline)
                            .widgetAccentable()
                        Text(getPlace(timetable: data[0], date: entry.date))
                            .foregroundColor(.gray)
                    }
                } else {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 4) {
                            Circle()
                                .frame(width: 12, height: 12)
                            Text(LocalizedStringKey("nextclasswidget.nodata"))
                                .font(.headline)
                        }.offset(y: 7)
                            .widgetAccentable()
                        Text("")
                            .font(.headline)
                            .widgetAccentable()
                        Text("")
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }.offset(y: -3)
            
        default:
            Text("Not Implemented")
        }
    }
    
    func getNextClass(timetable: Timetable, date: Date) -> (Int, Lecture) {
        var lecture: Lecture = timetable.lectures[0]
        var begin = 1440
        var index = 0
        
        let calendar = Calendar.current
        let day = getDayWithWeekDay(weekday: calendar.component(.weekday, from: date))
        var minutes = calendar.component(.minute, from: date) + calendar.component(.hour, from: date) * 60
        
        var lectures: [(Int, Lecture)] = getLecturesForDay(timetable: timetable, day: day)
        
        for (i, l) in lectures {
            if l.classes[i].begin >= minutes && begin >= l.classes[i].begin {
                begin = l.classes[i].begin
                index = i
                lecture = l
            }
        }
        
        if begin == 1440 {
            var tmrDate = calendar.date(byAdding: .day, value: 1, to: date)!
            lectures = getLecturesForDay(timetable: timetable, day: getDayWithWeekDay(weekday: calendar.component(.weekday, from: tmrDate)))
            minutes = 0
            
            while lectures.count == 0 {
                tmrDate = calendar.date(byAdding: .day, value: 1, to: tmrDate)!
                lectures = getLecturesForDay(timetable: timetable, day: getDayWithWeekDay(weekday: calendar.component(.weekday, from: tmrDate)))
            }
            
            for (i, l) in lectures {
                if l.classes[i].begin >= minutes && begin >= l.classes[i].begin {
                    begin = l.classes[i].begin
                    index = i
                    lecture = l
                }
            }
        }
        
        return (index, lecture)
    }
    
    func getBeginInTwelveHour(timetable: Timetable, date: Date) -> (String, String) {
        let c = getNextClass(timetable: timetable, date: date)
        let index = c.0
        let lecture: Lecture = c.1
        
        var hour = (lecture.classes[index].begin >= 720) ? (lecture.classes[index].begin-720)/60 : lecture.classes[index].begin/60
        hour = (hour == 0) ? 12 : hour
        
        var am: String {
            return NSLocale.current.language.languageCode?.identifier == "en" ? "AM" : "오전"
        }
        
        var pm: String {
            return NSLocale.current.language.languageCode?.identifier == "en" ? "PM" : "오후"
        }
        
        let apm = (lecture.classes[index].begin >= 720) ? pm : am
        
        return (String(format:"%02d:%02d", hour, lecture.classes[index].begin%60), apm)
    }
    
    func getName(timetable: Timetable, date: Date) -> String {
        let c = getNextClass(timetable: timetable, date: date)
        let lecture: Lecture = c.1
        
        return lecture.name
    }
    
    func getBegin(timetable: Timetable, date: Date) -> String {
        let c = getNextClass(timetable: timetable, date: date)
        let index = c.0
        let lecture: Lecture = c.1
        
        return String(format:"%02d:%02d", lecture.classes[index].begin/60, lecture.classes[index].begin%60)
    }
    
    func getPlace(timetable: Timetable, date: Date) -> String {
        let c = getNextClass(timetable: timetable, date: date)
        let index = c.0
        let lecture: Lecture = c.1
        
        return "(" + lecture.classes[index].buildingCode + ") " + lecture.classes[index].roomName
    }
    
    func getEnd(timetable: Timetable, date: Date) -> String {
        let c = getNextClass(timetable: timetable, date: date)
        let index = c.0
        let lecture: Lecture = c.1
        
        return String(format:"%02d:%02d", lecture.classes[index].end/60, lecture.classes[index].end%60)
    }
}


@available(iOSApplicationExtension 16.0, *)
struct NextClassAccessory: Widget {
    let kind: String = "NextClassAccessory"
    private let title: LocalizedStringKey = "nextclasswidget.title"
    private let description: LocalizedStringKey = "nextclasswidget.description"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            NextClassAccessoryEntryView(entry: entry)
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct NextClassAccessoryPreviews: PreviewProvider {
    static var previews: some View {
        NextClassAccessoryEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")
        NextClassAccessoryEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular")
    }
}
