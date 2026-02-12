//
//  AppShellView.swift
//  bedgemon
//
//  Main content (home tiles or workout tracker) with a hamburger that opens the menu in a sheet.
//  Tapping Home on the splash lands here on the home tile screen; menu does not replace it.
//

import SwiftUI

struct AppShellView: View {
    let profile: Profile
    @State private var selectedDestination: AppDestination = .home
    @State private var showingMenu = false

    private var profileDisplayName: String {
        profile == .sarah ? "Sarah" : "Dan"
    }

    var body: some View {
        Group {
            switch selectedDestination {
            case .home:
                HomeView(profile: profile)
            case .workoutTracker:
                WorkoutTrackerView(profile: profile)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
        .sheet(isPresented: $showingMenu) {
            menuSheet
        }
    }

    private var menuSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profileDisplayName)
                                .font(.headline)
                            Text("Profile")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                }

                Section("Navigate") {
                    ForEach(AppDestination.allCases, id: \.self) { dest in
                        Button {
                            selectedDestination = dest
                            showingMenu = false
                        } label: {
                            HStack {
                                Label(dest.title, systemImage: dest.systemImage)
                                Spacer()
                                if selectedDestination == dest {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingMenu = false
                    }
                }
            }
        }
    }
}

#Preview {
    AppShellView(profile: .sarah)
}
