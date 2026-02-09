//
//  DailyDayView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/17/23.
//

import SwiftUI

@available(iOS 15.0, *)
struct DailyDayView: View {
    @Binding var lecture: LectureElement
    
    @State private var showsDetailView = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .foregroundStyle(getColourForCourse(course: lecture.course))
            Text(lecture.title)
                .foregroundStyle(.black)
                .padding()
        }
    }
}
