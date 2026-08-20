//
//  ContentView.swift
//  otl Watch App
//
//  Created by Soongyu Kwon on 06/11/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = WatchViewModel.shared

    @State private var loginState: Bool = WatchTokenVault.hasTokenPair

    var body: some View {
        Group {
            if loginState {
                WeeklyTableView(loginState: $loginState)
            } else {
                LoginView()
            }
        }
        .onChange(of: viewModel.tokenPair) { tokenPair in
            loginState = tokenPair != nil
        }
    }
}

#Preview {
    ContentView()
}
