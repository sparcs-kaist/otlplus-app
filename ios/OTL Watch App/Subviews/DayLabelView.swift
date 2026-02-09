//
//  DayLabelView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/9/23.
//

import SwiftUI

enum DayType: String {
    case sun = "일"
    case mon = "월"
    case tue = "화"
    case wed = "수"
    case thu = "목"
    case fri = "금"
    case sat = "토"
}

@available(iOS 15.0, *)
struct DayLabelView: View {
    @Binding var day: DayType
    
    @State private var isHighlighted: Bool = false
    
    var body: some View {
        ZStack {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(.accent)
            }
            Text(day.rawValue)
                .fontWeight(.medium)
        }.frame(width: 22, height: 20)
        .onAppear {
            if getDayWithWeekDay(weekday: Calendar.current.component(.weekday, from: Date())) == convertDayType(toDays: self.day).rawValue {
                self.isHighlighted = true
            }
        }
    }
    
    func convertDayType(toDays: DayType) -> Days {
        switch toDays {
        case .mon:
            return .mon
        case .tue:
            return .tue
        case .wed:
            return .wed
        case .thu:
            return .thu
        case .fri:
            return .fri
        case .sat:
            return .sat
        case .sun:
            return .sun
        }
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
}

@available(iOS 17.0, *)
#Preview("DayLabelView", traits: .sizeThatFitsLayout) {
    VStack {
        DayLabelView(day: .constant(.mon))
        DayLabelView(day: .constant(.fri))
    }
}
