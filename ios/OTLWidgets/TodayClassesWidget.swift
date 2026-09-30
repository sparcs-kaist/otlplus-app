//
//  TodayClassesWidget.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 12/05/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct TodayClassesWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    
    var entry: Provider.Entry
    
    var widgetBackground: some View {
        colorScheme == .dark ? Color(red: 51.0/255, green: 51.0/255, blue: 51.0/255) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255)
    }

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            TodayClassesWidgetView(background: false, entry: entry)
                .containerBackground(for: .widget) {
                    widgetBackground
                }
        } else {
            TodayClassesWidgetView(background: true, entry: entry)
        }
    }
}

struct TodayClassesWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    var background: Bool = false
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            if background {
                (colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255))
            }
            GeometryReader { proxy in
                let remaining = remainingWidgetItems(timetable: entry.timetableData?.first, date: entry.date)
                let capacity = max(1, Int((proxy.size.height - 56) / 36))
                let minutes = widgetCalendar().component(.hour, from: entry.date) * 60 + widgetCalendar().component(.minute, from: entry.date)
                VStack(alignment: .leading, spacing: 4) {
                    Text("widget.today").font(.system(size: 12, weight: .semibold))
                    if remaining.isEmpty {
                        Spacer(minLength: 0)
                        Text("widget.today.empty").font(.system(size: 12)).foregroundColor(.secondary)
                        Spacer(minLength: 0)
                    } else {
                        ForEach(Array(remaining.prefix(capacity).enumerated()), id: \.offset) { _, occurrence in
                            let item = occurrence.1
                            let time = item.classes[occurrence.0]
                            let ongoing = time.begin <= minutes
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(getColourForCourse(course: item.courseId)).frame(width: 4)
                                    .widgetAccentable()
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(widgetMinuteLabel(time.begin)).font(.system(size: 11, weight: .medium))
                                    Text(widgetMinuteLabel(time.end)).font(.system(size: 10)).foregroundColor(.secondary)
                                }.frame(width: 38, alignment: .leading)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name + item.subtitle).font(.system(size: 12, weight: ongoing ? .semibold : .regular)).lineLimit(1)
                                    if !time.place.isEmpty {
                                        Text(time.place).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                if ongoing {
                                    Text("widget.ongoing").font(.system(size: 9)).foregroundColor(.secondary)
                                }
                            }.frame(height: 32)
                        }
                        Spacer(minLength: 0)
                        if remaining.count > capacity {
                            Text(widgetCountLabel("widget.more", count: remaining.count - capacity))
                                .font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                }.padding(12)
            }
            if entry.timetableData == nil {
                LoginPromptView(showsWidgetBackground: true)
            }
        }
    }
}

struct TodayClassesWidget: Widget {
    let kind: String = "TodayClassesWidget"
    private let title: LocalizedStringKey = "todayclasseswidget.title"
    private let description: LocalizedStringKey = "todayclasseswidget.description"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TodayClassesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}

struct TodayClassesWidgetPreviews: PreviewProvider {
    static var previews: some View {
        TodayClassesWidgetEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
