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

struct WeekClassesWidgetData: Identifiable {
    let id = UUID()
    let title: String
    let height: Double
    let y: Double
    let colour: Color
}

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
    
    @State var background: Bool = false
    var entry: Provider.Entry
    
    var widgetBackground: some View {
        colorScheme == .dark ? Color(red: 51.0/255, green: 51.0/255, blue: 51.0/255) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if background {
                widgetBackground
            }
            GeometryReader { proxy in
                Group {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 17)
                        Color.clear
                            .overlay(
                                HStack(spacing: 2) {
                                    TimeLabelView()
                                    ForEach(0..<5) { number in
                                        ZStack(alignment: .topLeading) {
                                            TableLineView()
                                            if let data = entry.timetableData, !data.isEmpty {
                                                ForEach(getLecturesData(data: getLecturesForDay(timetable: data[0], day: number))) { lectureData in
                                                    WeekClassesLectureView(lectureName: lectureData.title, colour: lectureData.colour)
                                                        .frame(height: lectureData.height)
                                                        .offset(y: lectureData.y)
                                                }
                                            }
                                        }
                                    }
                                }
                                , alignment: .top
                            )
                            .offset(y: getOffsetByDate(timetable: (entry.timetableData != nil && !entry.timetableData!.isEmpty) ? entry.timetableData![0] : nil, date: entry.date))
                    }
                }.padding(16)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: 45)
                                .offset(y: 33)
                            Rectangle()
                                .offset(y: 37)
                        }
                    )
            }
            GeometryReader { proxy in
                ZStack {
                    HStack {
                        Spacer()
                            .frame(width: 18)
                        ForEach([String(localized: "mon"), String(localized: "tue"), String(localized: "wed"), String(localized: "thu"), String(localized: "fri")], id: \.self) { text in
                            Text(text)
                                .offset(y: -2)
                                .frame(width: 50)
                        }
                    }.font(.custom("NotoSansKR-Regular", size: 12))
                        .offset(y: 10)
                }.padding(.horizontal, 16)
            }
            if (entry.timetableData == nil) {
                ZStack {
                    Color.clear
                        .background(.ultraThinMaterial)
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
    }
    
    func getOffsetByDate(timetable: Timetable?, date: Date) -> CGFloat {
        if (timetable == nil || timetable?.lectures.count == 0) {
            return 0
        }
        
        var tmp = 0
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date) >= 2 ? calendar.component(.hour, from: date)-2 : calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date) + calendar.component(.hour, from: date) * 60
        
        if hour > 9 {
            tmp = hour >= 18 ? -387 : -43*(hour-9)
        }
        
        var end = 0
        for lecture in timetable!.lectures {
            for classtime in lecture.classes {
                end = (classtime.end > end) ? classtime.end : end
            }
        }
        
        return (end >= minutes) ? CGFloat(tmp) : 0
    }
    
    func getLecturesData(data: [(Int, Lecture)]) -> [WeekClassesWidgetData] {
        var tmp = [WeekClassesWidgetData]()
        
        for (i, l) in data {
            let c = l.classes[i]
            
            let title = l.name
            let minute = c.end - c.begin
            var height = 0.6833 * Double(minute)
            if minute/30 != 0 {
                height = height + Double(minute/30 - 1)
            }
            let y = 0.7166 * Double(c.begin - 540) + 5
            let colour = getColourForCourse(course: l.courseId)
            
            tmp.append(WeekClassesWidgetData(title: title, height: height, y: y, colour: colour))
        }
        
        return tmp
    }
}

struct TimeLabelView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(9..<25) { number in
                HStack(spacing: 2) {
                    Text("\(number%12 == 0 ? 12 : number%12)")
                        .frame(width: 14, height: 18, alignment: .trailing)
                        .font(.custom("NotoSansKR-Regular", size: 12))
                    HorizontalLine()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .frame(width: 0, height: 1)
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25))
                }
                if number != 24 {
                    HStack(spacing: 2) {
                        HorizontalLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                            .frame(width: 0, height: 1)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25))
                    }
                }
            }
        }.offset(y: -4)
    }
}

struct TableLineView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(9..<25) { number in
                HStack(spacing: 0) {
                    Text("\(number%12 == 0 ? 12 : number%12)")
                        .frame(width: 0, height: 18, alignment: .trailing)
                        .font(.custom("NotoSansKR-Regular", size: 12))
                    HorizontalLine()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .frame(height: 1)
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25))
                }
                if number != 24 {
                    HStack(spacing: 0) {
                        HorizontalLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                            .frame(height: 1)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25))
                    }
                }
            }
        }.offset(y: -4)
    }
}


struct WeekClassesLectureView: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    
    let lectureName: String
    let colour: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(colour)
                .padding(.vertical, 2)
                .widgetAccentable()
                .opacity(renderingMode == .accented ? 0.2 : 1)
            Text(lectureName)
                .font(.custom("NotoSansKR-Regular", size: 10))
                .foregroundColor(.black)
                .padding([.leading, .top, .trailing], 4)
        }
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
