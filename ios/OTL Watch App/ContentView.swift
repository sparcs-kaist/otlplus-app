//
//  ContentView.swift
//  otl Watch App
//
//  Created by Soongyu Kwon on 06/11/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = WatchViewModel()
    
    @State private var loginState: Bool = true
    
    var body: some View {
        if loginState {
            WeeklyTableView(loginState: $loginState)
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
