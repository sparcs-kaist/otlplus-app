//
//  LoginView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 12/18/23.
//

import SwiftUI

@available(iOS 16.0, *)
struct LoginView: View {
    var body: some View {
        NavigationStack {
            Text("iPhone에서 OTL앱을 열어 로그인한 후 이용하실 수 있습니다.")
                .multilineTextAlignment(.center)
                .navigationTitle("OTL")
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    LoginView()
}
