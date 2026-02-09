//
//  LectureDetailView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/21/23.
//

import SwiftUI


extension UIColor {

    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}

@available(iOS 15.0, *)
extension Color {
    func adjust(hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, opacity: CGFloat = 1) -> Color {
        let color = UIColor(self)
        var currentHue: CGFloat = 0
        var currentSaturation: CGFloat = 0
        var currentBrigthness: CGFloat = 0
        var currentOpacity: CGFloat = 0

        if color.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentOpacity) {
            return Color(hue: currentHue + hue, saturation: currentSaturation + saturation, brightness: currentBrigthness + brightness, opacity: currentOpacity + opacity)
        }
        return self
    }
    
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        let color = UIColor(self)
        
        return Color(uiColor: color.lighter(by: percentage)!)
    }
    
    func darker(by percentage: CGFloat = 30.0) -> Color {
        let color = UIColor(self)
        
        return Color(uiColor: color.darker(by: percentage)!)
    }
}

@available(iOS 16.0, *)
struct LectureDetailView: View {
    @Binding var lecture: LectureElement
    @Binding var day: DayType
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .ignoresSafeArea()
                    .foregroundStyle(LinearGradient(colors: [getColourForCourse(course: lecture.course).darker(by: 40), getColourForCourse(course: lecture.course).adjust(brightness: -0.8)], startPoint: .top, endPoint: .bottom))
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(String(format: "%@요일 %02d:%02d-%02d:%02d", self.day.rawValue, lecture.classtime.begin/60, lecture.classtime.begin%60, lecture.classtime.end/60, lecture.classtime.end%60))
                            .font(.system(size: 15))
                            .foregroundStyle(getColourForCourse(course: lecture.course).adjust(brightness: 0.5))
                        HStack(alignment: .top) {
                            Circle()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(getColourForCourse(course: lecture.course))
                                .offset(y: 7)
                            Text(lecture.title)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text(lecture.classtime.classroom)
                            .font(.system(size: 13))
                        Text("\(lecture.professors[0].name) 교수님")
                            .font(.system(size: 13))
                    }
                    .offset(y: 15)
                }.padding()
            }
        }
    }
}
