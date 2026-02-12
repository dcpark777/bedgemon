//
//  AppContentView.swift
//  bedgemon
//
//  First screen after sign-in. User goes here before Home (tiles).
//

import SwiftUI

struct AppContentView: View {
    let profile: Profile

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Bedgemon")
                        .font(.title.weight(.semibold))

                    NavigationLink {
                        HomeView(profile: profile)
                    } label: {
                        Label("Home", systemImage: "house.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Content")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AppContentView(profile: .sarah)
}
