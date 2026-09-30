//
//  NextClassWidget.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 28/03/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct NextClassWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.showsWidgetContainerBackground) var showsWidgetBackground
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var entry: Provider.Entry
    
    // Helper to get the next class lecture
    private var currentLecture: WidgetScheduleItem? {
        guard
            let timetableData = entry.timetableData,
            !timetableData.isEmpty,
            !timetableData[0].scheduleItems.isEmpty
        else {
            return nil
        }
        
        return getNextClass(timetable: timetableData[0], date: entry.date)?.1
    }
    
    // Helper for background color based on theme
    var widgetBackground: some View {
        colorScheme == .dark ? Color(red: 51.0/255, green: 51.0/255, blue: 51.0/255) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255)
    }

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            ZStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    // Header
                    Text(LocalizedStringKey("nextclasswidget.nextlecture"))
                        .font(.custom("NotoSansKR-Bold", size: showsWidgetBackground ? 12 : 16))
                        .foregroundColor(renderingMode == .vibrant ? .white : Color(red: 229.0/255, green: 76.0/255, blue: 100.0/255))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .widgetAccentable()
                    
                    // Lecture Time Left
                    Text(currentLecture != nil ? getTimeLeft(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                        .font(.custom("NotoSansKR-Bold", size: 20))
                        .offset(y: -2)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Circle Color and Lecture Name
                    HStack {
                        Circle()
                            .fill(currentLecture != nil ? getColour(timetable: entry.timetableData![0], date: entry.date) : getColourForCourse(course: 1))
                            .frame(width: 12, height: 12)
                            .widgetAccentable()
                        Text(currentLecture != nil ? getName(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                            .font(.custom("NotoSansKR-Bold", size: showsWidgetBackground ? 16 : 20))
                            .minimumScaleFactor(0.5)
                            .lineLimit(2)
                    }.offset(y: 6)
                    
                    // Place
                    Text(currentLecture != nil ? getPlace(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                        .font(.custom("NotoSansKR-Regular", size: 12))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    // Professor
                    Text(currentLecture != nil ? getProfessor(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                        .font(.custom("NotoSansKR-Medium", size: 12))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.gray)
                        .widgetAccentable()
                        .opacity(renderingMode == .accented ? 0.5 : 1)
                }.padding(.horizontal, showsWidgetBackground ? 0 : 3)
                
                // If Timetable is nil, show login prompt
                if entry.timetableData == nil {
                    LoginPromptView(showsWidgetBackground: showsWidgetBackground)
                }
            }
            .containerBackground(for: .widget) { widgetBackground }
        } else {
            // Fallback for older iOS versions
            ZStack(alignment: .leading) {
                widgetBackground
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("nextclasswidget.nextlecture"))
                        .font(.custom("NotoSansKR-Bold", size: 12))
                        .foregroundColor(Color(red: 229.0/255, green: 76.0/255, blue: 100.0/255))
                    Text(currentLecture != nil ? getTimeLeft(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                        .font(.custom("NotoSansKR-Bold", size: 20))
                        .offset(y: -2)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack {
                        Circle()
                            .fill(currentLecture != nil ? getColour(timetable: entry.timetableData![0], date: entry.date) : getColourForCourse(course: 1))
                            .frame(width: 12, height: 12)
                        Text(currentLecture != nil ? getName(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                            .font(.custom("NotoSansKR-Bold", size: 16))
                            .minimumScaleFactor(0.5)
                            .lineLimit(2)
                    }.offset(y: 6)
                    Text(currentLecture != nil ? getPlace(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                        .font(.custom("NotoSansKR-Regular", size: 12))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(currentLecture != nil ? getProfessor(timetable: entry.timetableData![0], date: entry.date) : String(localized: "nextclasswidget.nodata"))
                        .font(.custom("NotoSansKR-Medium", size: 12))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.gray)
                }.padding()
                if entry.timetableData == nil {
                    LoginPromptView(showsWidgetBackground: showsWidgetBackground)
                }
            }
        }
    }
    
    func getName(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let lecture: WidgetScheduleItem = c.1
        
        return lecture.name + lecture.subtitle
    }
    
    func getProfessor(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let lecture: WidgetScheduleItem = c.1
        
        guard let professor = lecture.professors.first else { return "" }
        return String(format: String(localized: "nextclasswidget.professor"), professor.name)
    }
    
    func getPlace(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let index = c.0
        let lecture: WidgetScheduleItem = c.1
        
        return lecture.classes[index].place
    }
    
    func getTimeLeft(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let index = c.0
        let lecture: WidgetScheduleItem = c.1
        
        let calendar = widgetCalendar()
        let day = getDayWithWeekDay(weekday: calendar.component(.weekday, from: date))
        
        
        let begin = lecture.classes[index].begin
        let lday = lecture.classes[index].day
        
        let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let daysAway = (lday - day + 7) % 7
        if daysAway == 0 && begin >= minutes {
            return String(format: String(localized: "nextclasswidget.today.timeformat"), begin/60, begin%60)
        } else if daysAway == 1 {
            return String(format: String(localized: "nextclasswidget.tomorrow.timeformat"), begin/60, begin%60)
        } else if daysAway > 1 {
            return String(format: String(localized: "nextclasswidget.day.timeformat"), getDayInString(day: lday), begin/60, begin%60)
        } else {
            return String(format: String(localized: "nextclasswidget.nextweek.timeformat"), getDayInString(day: lday))
        }
    }
    
    func getColour(timetable: Timetable, date: Date) -> Color {
        guard let c = getNextClass(timetable: timetable, date: date) else { return getColourForCourse(course: 1) }
        let course = c.1.courseId
        
        return getColourForCourse(course: course)
    }
}

struct LoginPromptView: View {
    var showsWidgetBackground: Bool
    
    var body: some View {
        ZStack {
            if showsWidgetBackground {
                Color.clear.background(.ultraThinMaterial)
            } else {
                Color.clear
            }
            VStack {
                Image("lock")
                    .resizable()
                    .frame(width: 44, height: 44)
                Text(LocalizedStringKey("widget.login"))
                    .font(.custom("NotoSansKR-Bold", size: 12))
                    .padding(.horizontal, 10.0)
                    .padding(.vertical, 4)
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 30).foregroundColor(Color(red: 229.0/255, green: 76.0/255, blue: 100.0/255)))
            }
        }
    }
}

func getNextClass(timetable: Timetable, date: Date) -> (Int, WidgetScheduleItem)? {
    nextWidgetItem(timetable: timetable, date: date)
}

// Widget definition
struct NextClassWidget: Widget {
    let kind: String = "NextClassWidget"
    private let title: LocalizedStringKey = "nextclasswidget.title"
    private let description: LocalizedStringKey = "nextclasswidget.description"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            NextClassWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies([.systemSmall])
    }
}

struct NextClassWidgetPreviews: PreviewProvider {
    static var previews: some View {
        NextClassWidgetEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
