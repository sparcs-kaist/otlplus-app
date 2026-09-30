//
//  WeekClassesWidget.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 14/05/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct WeekClassesWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    
    var entry: Provider.Entry
    
    var widgetBackground: some View {
        colorScheme == .dark ? Color(red: 51.0/255, green: 51.0/255, blue: 51.0/255) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255)
    }

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            WeekClassesWidgetView(background: false, entry: entry)
                .containerBackground(for: .widget) {
                    widgetBackground
                }
        } else {
            WeekClassesWidgetView(background: true, entry: entry)
        }
    }
}

struct WeekClassesWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    var background: Bool = false
    var entry: Provider.Entry

    private var timetable: Timetable? { entry.timetableData?.first }
    private var daysCount: Int { timetable?.scheduleItems.contains { $0.classes.contains { $0.day >= 5 } } == true ? 7 : 5 }

    var body: some View {
        ZStack {
            if background {
                (colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255))
            }
            GeometryReader { proxy in
                let hours = min(16, max(2, Int((proxy.size.height - 76) / 36)))
                let window = widgetTimeWindow(timetable: timetable, date: entry.date, visibleHours: hours)
                let times = timetable?.scheduleItems.flatMap(\.classes) ?? []
                let earlier = times.filter { $0.begin < window.startHour * 60 }.count
                let later = times.filter { $0.end > window.endHour * 60 }.count
                let columnWidth = max(0, (proxy.size.width - 24 - 24 - CGFloat(daysCount * 2)) / CGFloat(daysCount))
                VStack(spacing: 4) {
                    Text(earlier > 0 ? widgetCountLabel("widget.earlier", count: earlier) : " ")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12, alignment: .trailing)
                    HStack(spacing: 2) {
                        Color.clear.frame(width: 24)
                        ForEach(0..<daysCount, id: \.self) { day in
                            Text(getDayInString(day: day)).font(.system(size: 11))
                                .frame(width: columnWidth)
                        }
                    }.frame(height: 14)
                    HStack(alignment: .top, spacing: 2) {
                        ZStack(alignment: .topTrailing) {
                            ForEach(window.startHour...window.endHour, id: \.self) { hour in
                                Text(String(format: "%02d", hour))
                                    .font(.system(size: 10)).foregroundColor(.secondary)
                                    .frame(width: 24, height: 12, alignment: .trailing)
                                    .offset(y: CGFloat(hour - window.startHour) * 36 - 6)
                            }
                        }.frame(width: 24, height: CGFloat(hours) * 36, alignment: .topTrailing)
                        ForEach(0..<daysCount, id: \.self) { day in
                            ZStack(alignment: .topLeading) {
                                ForEach(0...(hours * 2), id: \.self) { halfHour in
                                    HorizontalLine()
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: halfHour % 2 == 0 ? [] : [2]))
                                        .foregroundColor(Color.primary.opacity(0.15))
                                        .frame(height: 1)
                                        .offset(y: CGFloat(halfHour) * 18)
                                }
                                ForEach(Array(widgetItemsForDay(timetable: timetable, day: day).enumerated()), id: \.offset) { _, occurrence in
                                    let item = occurrence.1
                                    let time = item.classes[occurrence.0]
                                    let begin = max(time.begin, window.startHour * 60)
                                    let end = min(time.end, window.endHour * 60)
                                    if end > begin {
                                        WeekClassesLectureView(lectureName: item.name + item.subtitle,
                                            lecturePlace: time.place, colour: getColourForCourse(course: item.courseId))
                                            .frame(width: columnWidth, height: Double(end - begin) * 0.6)
                                            .offset(y: Double(begin - window.startHour * 60) * 0.6)
                                    }
                                }
                            }.frame(width: columnWidth, height: CGFloat(hours) * 36, alignment: .topLeading).clipped()
                        }
                    }.frame(height: CGFloat(hours) * 36, alignment: .top)
                    Text(later > 0 ? widgetCountLabel("widget.later", count: later) : " ")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12, alignment: .trailing)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
            }
            if entry.timetableData == nil {
                LoginPromptView(showsWidgetBackground: true)
            }
        }
    }
}

struct WeekClassesLectureView: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    
    let lectureName: String
    let lecturePlace: String
    let colour: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(colour)
                .padding(.vertical, 2)
                .widgetAccentable()
                .opacity(renderingMode == .accented ? 0.2 : 1)
            VStack(alignment: .leading, spacing: 0) {
                Text(lectureName)
                    .font(.custom("NotoSansKR-Regular", size: 10))
                    .lineLimit(2)
                if !lecturePlace.isEmpty {
                    Text(lecturePlace)
                        .font(.custom("NotoSansKR-Regular", size: 8))
                        .foregroundColor(.black.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .foregroundColor(.black)
            .padding([.leading, .top, .trailing], 4)
        }
        .clipped()
    }
}


struct WeekClassesWidget: Widget {
    let kind: String = "WeekClassesWidget"
    private let title: LocalizedStringKey = "weekclasseswidget.title"
    private let description: LocalizedStringKey = "weekclasseswidget.description"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WeekClassesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabledIfAvailable()
    }
}

struct WeekClassesWidgetPreviews: PreviewProvider {
    static var previews: some View {
        WeekClassesWidgetEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
