//
//  PastWorkoutsView.swift
//  bedgemon
//
//  View and manage past workout days for a chosen profile. Separate flow from starting a new workout.
//

import SwiftUI

struct PastWorkoutsView: View {
    let profile: Profile
    @State private var selectedProfile: Profile
    @State private var days: [WorkoutDay] = []
    @State private var isLoading = false
    @State private var syncErrorMessage: String?

    init(profile: Profile) {
        self.profile = profile
        _selectedProfile = State(initialValue: profile)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        List {
            Section {
                Picker("View", selection: $selectedProfile) {
                    Text("Sarah").tag(Profile.sarah)
                    Text("Dan").tag(Profile.dan)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProfile) { _, _ in
                    Task { await reload() }
                }
            } header: {
                Text("Whose workouts")
            }

            if let msg = syncErrorMessage {
                Section {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                ForEach(days) { day in
                    NavigationLink(value: day) {
                        dayRow(day)
                    }
                }
                .onDelete(perform: deleteDays)
            } header: {
                Text("Workouts")
            } footer: {
                if days.isEmpty {
                    Text("No workouts yet for \(selectedProfile == .sarah ? "Sarah" : "Dan").")
                }
            }
        }
        .navigationTitle("Past workouts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: WorkoutDay.self) { day in
            WorkoutDayDetailView(
                day: day,
                profile: selectedProfile,
                onUpdate: { Task { await reload() } },
                onEditSave: { updated in
                    Task {
                        try? await WorkoutStore.addDay(updated)
                        await reload()
                    }
                }
            )
        }
        .refreshable { await reload() }
        .task { await reload() }
        .overlay {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    private func dayRow(_ day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.dateFormatter.string(from: day.date))
                .font(.headline)
            if !day.exercises.isEmpty {
                Text(day.exercises.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func reload() async {
        isLoading = true
        syncErrorMessage = nil
        defer { isLoading = false }
        days = await WorkoutStore.load(profile: selectedProfile)
    }

    private func deleteDays(at offsets: IndexSet) {
        let toDelete = offsets.map { days[$0] }
        Task {
            isLoading = true
            syncErrorMessage = nil
            defer { isLoading = false }
            for day in toDelete {
                do {
                    try await WorkoutStore.deleteDay(id: day.id, profile: selectedProfile)
                } catch {
                    syncErrorMessage = "Couldn’t remove from cloud: \(error.localizedDescription)"
                }
            }
            days = await WorkoutStore.load(profile: selectedProfile)
        }
    }
}
