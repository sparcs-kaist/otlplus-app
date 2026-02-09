//
//  WeeklyDayView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/16/23.
//

import SwiftUI

@available(iOS 15.0, *)
struct WeeklyDayView: View {
    @Binding var lectures: [LectureElement]
    
    @State private var showsDailyTableView = false
    
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color(red: 51/256, green: 51/256, blue: 51/256))
            ForEach(self.lectures) { lecture in
                RoundedRectangle(cornerRadius: 2)
                    .foregroundStyle(getColourForCourse(course: lecture.course))
                    .frame(height: Double(lecture.classtime.end - lecture.classtime.begin)/60*14-1)
                    .offset(y: CGFloat(Double(lecture.classtime.begin - 540)/60*14))
            }
        }
    }
}
