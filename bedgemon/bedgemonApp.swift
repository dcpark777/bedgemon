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

    var body: some Scene {
        WindowGroup {
            ContentView(auth: auth)
                .onAppear {
                    Task { await auth.checkRestoreSession() }
                }
        }
    }
}
