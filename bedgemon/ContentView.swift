//
//  ContentView.swift
//  bedgemon
//
//  Created by Daniel Park on 2/11/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var auth: AuthManager

    var body: some View {
        Group {
            if let profile = auth.profile {
                HomeView(profile: profile)
            } else if auth.pendingAppleUserID != nil {
                ChooseProfileView(auth: auth)
            } else {
                SignInView(auth: auth)
            }
        }
    }
}

#Preview {
    ContentView(auth: AuthManager())
}
