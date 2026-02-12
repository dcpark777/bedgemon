//
//  WorkoutDayDetailView.swift
//  bedgemon
//

import SwiftUI

struct WorkoutDayDetailView: View {
    let day: WorkoutDay
    /// Profile this workout belongs to (for editing). Use day.loggedBy when available.
    let profile: Profile
    let onUpdate: () -> Void
    /// Called when user saves from the edit sheet (same day, possibly more exercises).
    let onEditSave: ((WorkoutDay) -> Void)?

    @State private var currentDay: WorkoutDay
    @State private var showingEdit = false
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    init(day: WorkoutDay, profile: Profile, onUpdate: @escaping () -> Void, onEditSave: ((WorkoutDay) -> Void)? = nil) {
        self.day = day
        self.profile = profile
        self.onUpdate = onUpdate
        self.onEditSave = onEditSave
        _currentDay = State(initialValue: day)
    }

    var body: some View {
        List {
            Section("Date") {
                Text(Self.dateFormatter.string(from: currentDay.date))
            }
            Section("Exercises") {
                if currentDay.exercises.isEmpty {
                    Text("No exercises yet. Tap Edit to add some.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(currentDay.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.headline)
                            ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(set.reps) reps")
                                    Text("\(formatWeight(set.weight)) lb")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Workout Day")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onEditSave != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEdit = true }
                }
            }
        }
        .onAppear { currentDay = day }
        .sheet(isPresented: $showingEdit) {
            AddWorkoutDayView(
                profile: profile,
                existingDay: currentDay,
                onSave: { updated in
                    onEditSave?(updated)
                    currentDay = updated
                    showingEdit = false
                }
            )
        }
    }

    private func formatWeight(_ w: Double) -> String {
        if w == 0 { return "0" }
        if w.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }
}
