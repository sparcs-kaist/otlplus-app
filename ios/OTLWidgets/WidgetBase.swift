//
//  WidgetBase.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 12/05/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import Foundation
import SwiftUI

struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

func getColourForCourse(course: Int) -> Color {
    let colours = [
        [242.0, 206.0, 206.0],
        [244.0, 179.0, 174.0],
        [242.0, 188.0, 160.0],
        [240.0, 211.0, 171.0],
        [241.0, 225.0, 169.0],
        [244.0, 242.0, 179.0],
        [219.0, 244.0, 190.0],
        [190.0, 237.0, 215.0],
        [183.0, 226.0, 222.0],
        [201.0, 234.0, 244.0],
        [180.0, 211.0, 237.0],
        [185.0, 197.0, 237.0],
        [204.0, 198.0, 237.0],
        [216.0, 193.0, 240.0],
        [235.0, 202.0, 239.0],
        [244.0, 186.0, 219.0]
    ]
    
    return Color(red: Double(colours[course % 16][0]/255), green:Double(colours[course % 16][1]/255), blue:Double(colours[course % 16][2]/255))
}

func getDayWithWeekDay(weekday: Int) -> Int {
    switch weekday {
    case 1:
        return 6
    case 2:
        return 0
    case 3:
        return 1
    case 4:
        return 2
    case 5:
        return 3
    case 6:
        return 4
    case 7:
        return 5
    default:
        return 0
    }
}

func getDayInString(day: Int) -> String {
    switch day {
    case 0:
        return String(localized: "mon")
    case 1:
        return String(localized: "tue")
    case 2:
        return String(localized: "wed")
    case 3:
        return String(localized: "thu")
    case 4:
        return String(localized: "fri")
    case 5:
        return String(localized: "sat")
    case 6:
        return String(localized: "sun")
    default:
        return String(localized: "mon")
    }
}

func getLecturesForDay(timetable: Timetable?, day: Int) -> [(Int, Lecture)] {
    var tmp: [(Int, Lecture)] = [(Int, Lecture)]()
    if (timetable == nil) {
        return tmp
    }
    
    for l in timetable!.lectures {
        for i in 0..<l.classes.count {
            let c = l.classes[i]
            if c.day == day {
                tmp.append((i, l))
            }
        }
    }
    
    return tmp
}

extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}
