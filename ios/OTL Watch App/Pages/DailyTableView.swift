//
//  DailyTableView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/9/23.
//

import SwiftUI

@available(iOS 17.0, *)
struct DailyTableView: View {
    @Binding var lectures: [LectureElement]
    @Binding var day: DayType
    
    private func calculateHeight(duration: Int) -> CGFloat {
        let blockHeight: CGFloat = 25 // Height for a 30-minute block
        let offset: CGFloat = 1 // Space between blocks

        // Calculate the number of full 30-minute blocks and the remaining time
        let fullBlocks = duration / 30
        let remainingMinutes = duration % 30

        // Height for the full blocks
        let fullBlocksHeight = CGFloat(fullBlocks) * blockHeight

        // Height for the remaining minutes, scaled proportionally
        let remainingHeight = (CGFloat(remainingMinutes) / 30) * blockHeight

        // Add offsets between blocks
        let totalOffset = CGFloat(max(fullBlocks - 1, 0)) * offset
        
        print("For Duration: \(duration)")
        print(fullBlocksHeight + remainingHeight + totalOffset + 2)
        return fullBlocksHeight + remainingHeight + totalOffset + 2
    }
    
    private func getElementAt(index: Int) -> LectureElement {
        if index < 0 || index >= lectures.count {
            return lectures.first!
        }
        
        let sortedLectures = lectures.sorted { $0.classtime.begin < $1.classtime.begin }
        return sortedLectures[index]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    VStack(alignment: .trailing) {
                        ForEach(3..<9) { number in
                            if number == 3 {
                                Spacer()
                                    .frame(height: 51)
                            }
                            Text("\(number * 3 > 12 ? number * 3 - 12 : number * 3)")
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .frame(height: 0)
                            if number != 8 {
                                Spacer()
                            }
                        }
                    }.frame(width: 18)
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            ForEach(0..<33) { number in
                                if number % 2 == 0 {
                                    HorizontalLine()
                                        .stroke(style: StrokeStyle(lineWidth: 1))
                                        .frame(height: 1)
                                        .foregroundStyle(Color.white.opacity(0.25))
                                } else {
                                    HorizontalLine()
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                                        .frame(height: 1)
                                        .foregroundStyle(Color.white.opacity(0.25))
                                }
                                if number != 32 {
                                    Spacer()
                                        .frame(height: 25)
                                }
                            }
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(0..<self.lectures.count) { i in
                                if i == 0 {
                                    Spacer()
                                        .frame(height: calculateHeight(duration: getElementAt(index: 0).classtime.begin - 480))
                                } else {
                                    Spacer()
                                        .frame(height: calculateHeight(duration: getElementAt(index: i).classtime.begin - getElementAt(index: i - 1).classtime.end))
                                }
                                DailyRow(lecture: getElementAt(index: i), day: self.$day)
                                    .padding(.vertical, 1)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(self.day.rawValue)요일")
        }.onAppear() {
            for lecture in lectures {
                print("Lectures for: \(lecture.title)")
                print(lecture.classtime)
            }
        }
    }
}

struct DailyRow: View {
    @State var lecture: LectureElement
    @Binding var day: DayType
    
    private func calculateHeight(duration: Int) -> CGFloat {
        let blockHeight: CGFloat = 22 // Height for a 30-minute block
        let offset: CGFloat = 4 // Space between blocks
        
        // Calculate the number of full 30-minute blocks and the remaining time
        let fullBlocks = duration / 30
        let remainingMinutes = duration % 30
        
        // Height for the full blocks
        let fullBlocksHeight = CGFloat(fullBlocks) * blockHeight
        
        // Height for the remaining minutes, scaled proportionally
        let remainingHeight = (CGFloat(remainingMinutes) / 30) * blockHeight
        
        // Add offsets between blocks
        let totalOffset = CGFloat(max(fullBlocks - 1, 0)) * offset
        
        return fullBlocksHeight + remainingHeight + totalOffset + 0.2
    }
    
    var body: some View {
        NavigationLink(destination: LectureDetailView(lecture: .constant(self.lecture), day: self.$day)) {
            DailyDayView(lecture: .constant(self.lecture))
        }
        .buttonStyle(.plain)
        .frame(height: calculateHeight(duration: self.lecture.classtime.end - self.lecture.classtime.begin))
    }
}

@available(iOS 17.0, *)
#Preview {
    DailyTableView(lectures: .constant([LectureElement]()), day: .constant(.mon))
}
