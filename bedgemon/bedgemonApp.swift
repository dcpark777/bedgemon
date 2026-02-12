//
//  bedgemonApp.swift
//  bedgemon
//
//  Created by Daniel Park on 2/11/26.
//

import SwiftUI

@main
struct bedgemonApp: App {
    @StateObject private var auth = AuthManager()
    @State private var showContentView = false

    var body: some Scene {
        WindowGroup {
            if showContentView {
                ContentView(auth: auth)
            } else {
                InitialSplashView(onHome: {
                    showContentView = true
                })
                .onAppear {
                    Task { await auth.checkRestoreSession() }
                }
            }
        }
    }
}
