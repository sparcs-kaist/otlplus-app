//
//  HorizontalLine.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/9/23.
//

import SwiftUI

@available(iOS 13.0, *)
struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

@available(iOS 13.0, *)
#Preview {
    HorizontalLine()
}
