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

struct TodayClassesWidgetData: Identifiable {
    let id = UUID()
    let title: String
    let place: String
    let width: Double
    let x: Double
    let colour: Color
}



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
    @State var background: Bool = false
    
    var entry: Provider.Entry
    
    var widgetBackground: some View {
        colorScheme == .dark ? Color(red: 51.0/255, green: 51.0/255, blue: 51.0/255) : Color(red: 249.0/255, green: 240.0/255, blue: 240.0/255)
    }
    
    var body: some View {
        ZStack {
            if background {
                widgetBackground
            }
            Color.clear
                .overlay(
                    Group {
                        ZStack(alignment: .leading) {
                            HStack {
                                ForEach(9..<25) { number in
                                    VStack {
                                        Text("\(number%12 == 0 ? 12 : number%12)")
                                            .frame(width: 40)
                                            .multilineTextAlignment(.center)
                                            .font(.system(size: 12, weight: number%6==0 ? .bold : .regular))
                                        VerticalLine()
                                            .stroke(style: StrokeStyle(lineWidth: 1))
                                            .frame(width: 1)
                                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25))
                                    }
                                    if number != 24 {
                                        Spacer()
                                        VStack {
                                            Spacer()
                                                .frame(height: 24)
                                            VerticalLine()
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                                                .frame(width: 1)
                                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25))
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            if (entry.timetableData != nil && !entry.timetableData!.isEmpty) {
                                ForEach(getLecturesData(data: getLecturesForDay(timetable: entry.timetableData?[0], day: getDayWithWeekDay(weekday: Calendar.current.component(.weekday, from: entry.date))))) { data in
                                    VStack {
                                        Spacer().frame(height: 24)
                                        TodayClassesLectureView(lectureName: data.title, lecturePlace: data.place, colour: data.colour)
                                            .frame(width: data.width)
                                            .offset(x: data.x)
                                        Spacer().frame(height: 2)
                                    }
                                }
                            }
                            ExactTimeLine()
                                .offset(x: getXByDate(date: entry.date))
                        }
                    }.padding(.vertical, 16)
                        .offset(x: getOffsetByDate(date: entry.date))
                    , alignment: .leading
                )
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
    
    func getOffsetByDate(date: Date) -> CGFloat {
        var tmp = 0
        let hour = Calendar.current.component(.hour, from: date) >= 2 ? Calendar.current.component(.hour, from: date)-2 : Calendar.current.component(.hour, from: date)
        
        if hour > 9 {
            tmp = hour >= 19 ? -570 : -57*(hour-9)
        }
        
        
        return CGFloat(tmp)
    }
    
    func getXByDate(date: Date) -> CGFloat {
        var tmp = 0.0
        let hour = Calendar.current.component(.hour, from: date)
        let minutes = Calendar.current.component(.minute, from: date) + hour * 60
        
        if minutes <= 540 {
            return -100
        }
        
        tmp = 13.5 + 0.95 * Double(minutes - 540)
        
        return tmp
    }
    
    func getLecturesData(data: [(Int, Lecture)]) -> [TodayClassesWidgetData] {
        var tmp = [TodayClassesWidgetData]()
        
        for (i, l) in data {
            let c = l.classes[i]
            
            let title = l.name + l.subtitle
            let place = "(" + c.buildingCode + ") " + c.roomName
            let width = (0.9388*Double(c.end-c.begin)*10).rounded()/10
            let x = 20 + (Double(c.begin-540)*0.95*10).rounded()/10
            let colour = getColourForCourse(course: l.courseId)
            
            tmp.append(TodayClassesWidgetData(title: title, place: place, width: width, x: x, colour: colour))
        }
        
        return tmp
    }
}

struct TodayClassesLectureView: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    
    let lectureName: String
    let lecturePlace: String
    let colour: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(colour)
                .widgetAccentable()
                .opacity(renderingMode == .accented ? 0.2 : 1.0)
            HStack {
                VStack(alignment: .leading) {
                    Text(lectureName)
                        .font(.custom("NotoSansKR-Regular", size: 12))
                        .foregroundColor(.black)
                    Text(lecturePlace)
                        .font(.custom("NotoSansKR-Regular", size: 12))
                        .foregroundColor(Color(red: 102.0/255, green: 102.0/255, blue: 102.0/255))
                        .widgetAccentable()
                    Spacer()
                }.padding(.vertical, 8)
                Spacer()
            }.padding(.horizontal, 8)
        }
        .padding(.horizontal, 2)
    }
}

struct ExactTimeLine: View {
    var body: some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(Color(red: 229.0/255, green: 76.0/255, blue: 99.0/255))
                .frame(width: 12, height: 12)
            Rectangle()
                .fill(Color(red: 229.0/255, green: 76.0/255, blue: 99.0/255))
                .frame(width: 2)
        }.widgetAccentable()
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
