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
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .center)
                    Text(Self.dateFormatter.string(from: currentDay.date))
                        .font(.title3.weight(.semibold))
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            } header: {
                Text("Date")
            }

            Section {
                if currentDay.exercises.isEmpty {
                    ContentUnavailableView {
                        Label("No exercises", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Tap Edit to add exercises and sets.")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(currentDay.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(exercise.name)
                                    .font(.headline)
                            }
                            ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .leading)
                                    Text("\(set.reps) reps")
                                        .font(.subheadline)
                                    Text("\(formatWeight(set.weight)) lb")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                }
            } header: {
                Text("Exercises")
            }
        }
        .listSectionSpacing(20)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onEditSave != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEdit = true }
                        .fontWeight(.semibold)
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
