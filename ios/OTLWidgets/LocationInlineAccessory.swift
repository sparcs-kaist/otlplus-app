//
//  LocationInlineAccessory.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 28/07/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

@available(iOSApplicationExtension 16.0, *)
struct LocationInlineAccessoryEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            HStack {
                Image(systemName: "tablecells")
                if let data = entry.timetableData, !data.isEmpty, !data[0].scheduleItems.isEmpty {
                    Text("\(getPlace(timetable: data[0], date: entry.date)) \(getName(timetable: data[0], date: entry.date))")
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
    
    func getPlace(timetable: Timetable, date: Date) -> String {
        guard let c = getNextClass(timetable: timetable, date: date) else { return "" }
        let index = c.0
        let lecture: WidgetScheduleItem = c.1
        
        return lecture.classes[index].place
    }
}


@available(iOSApplicationExtension 16.0, *)
struct LocationInlineAccessory: Widget {
    let kind: String = "LocationInlineAccessory"
    private let title: LocalizedStringKey = "locationinlineaccessory.title"
    private let description: LocalizedStringKey = "locationinlineaccessory.description"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            LocationInlineAccessoryEntryView(entry: entry)
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies([.accessoryInline])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LocationInlineAccessoryPreviews: PreviewProvider {
    static var previews: some View {
        LocationInlineAccessoryEntryView(entry: WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
