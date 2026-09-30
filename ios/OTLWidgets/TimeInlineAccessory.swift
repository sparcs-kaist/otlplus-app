//
//  TimeInlineAccessory.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 28/07/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

@available(iOSApplicationExtension 16.0, *)
struct TimeInlineAccessoryEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            HStack {
                Image(systemName: "tablecells")
                if (entry.timetableData != nil && !entry.timetableData!.isEmpty && !entry.timetableData![0].scheduleItems.isEmpty) {
                    Text("\(getBegin(timetable: entry.timetableData![0], date: entry.date)) \(getName(timetable: entry.timetableData![0], date: entry.date))")
                } else {
                    Text(LocalizedStringKey("nextclasswidget.nodata"))
                }
            }
            
        default:
            Text("Not Implemented")
        }
    }
    
    func getName(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let lecture: WidgetScheduleItem = c.1
        
        return lecture.name + lecture.subtitle
    }
    
    func getBegin(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let index = c.0
        let lecture: WidgetScheduleItem = c.1
        
        return String(format:"%02d:%02d", lecture.classes[index].begin/60, lecture.classes[index].begin%60)
    }
}


@available(iOSApplicationExtension 16.0, *)
struct TimeInlineAccessory: Widget {
    let kind: String = "TimeInlineAccessory"
    private let title: LocalizedStringKey = "timeinlineaccessory.title"
    private let description: LocalizedStringKey = "timeinlineaccessory.description"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TimeInlineAccessoryEntryView(entry: entry)
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies([.accessoryInline])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct TimeInlineAccessoryPreviews: PreviewProvider {
    static var previews: some View {
        TimeInlineAccessoryEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
