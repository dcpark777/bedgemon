//
//  WorkoutTrackerView.swift
//  bedgemon
//
//  Hub: current workout (in progress), start new, past workouts, templates.
//

import SwiftUI

struct WorkoutTrackerView: View {
    let profile: Profile
    @State private var selectedProfile: Profile
    @State private var currentWorkout: WorkoutDay?
    @State private var showingStartWorkout = false
    /// Draft being edited in the current-workout sheet (keeps sheet content stable when we clear currentWorkout).
    @State private var editingCurrentDraft: WorkoutDay?

    init(profile: Profile) {
        self.profile = profile
        _selectedProfile = State(initialValue: profile)
    }

    var body: some View {
        List {
            Section {
                Picker("For", selection: $selectedProfile) {
                    Text("Sarah").tag(Profile.sarah)
                    Text("Dan").tag(Profile.dan)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Workouts for")
            } footer: {
                Text("Choose who the workout is for. You can start workouts and view history for either.")
            }

            if let current = currentWorkout {
                Section {
                    Button {
                        editingCurrentDraft = current
                    } label: {
                        HStack {
                            Label("Current workout", systemImage: "figure.run")
                                .font(.headline)
                            Spacer()
                            Text(shortDate(current.date))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Current workout")
                } footer: {
                    Text("Tap to add or edit exercises. Finish the workout to save it to past workouts.")
                }
            }

            Section {
                Button {
                    showingStartWorkout = true
                } label: {
                    Label("Start new workout", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            } header: {
                Text(currentWorkout == nil ? "Start a workout" : "Or start another later")
            } footer: {
                if currentWorkout == nil {
                    Text("Creates a current workout you can open to log exercises, then finish to save to past workouts.")
                }
            }

            Section {
                NavigationLink {
                    PastWorkoutsView(profile: selectedProfile)
                } label: {
                    Label("Past workouts", systemImage: "calendar")
                }
                NavigationLink {
                    ExerciseCollectionsView()
                } label: {
                    Label("Templates", systemImage: "list.bullet.rectangle")
                }
            } header: {
                Text("Past workouts")
            }
        }
        .navigationTitle("Workout Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshCurrentWorkout() }
        .onChange(of: selectedProfile) { _, _ in refreshCurrentWorkout() }
        .sheet(isPresented: $showingStartWorkout) {
            StartWorkoutView(profile: selectedProfile, onStartWorkout: { draft in
                CurrentWorkoutStore.setCurrentWorkout(draft, for: selectedProfile)
                currentWorkout = draft
                showingStartWorkout = false
            })
        }
        .sheet(item: $editingCurrentDraft) { draft in
            AddWorkoutDayView(
                profile: selectedProfile,
                existingDay: draft,
                isOngoingWorkout: true,
                onSave: { day in
                    Task {
                        await addDay(day)
                        CurrentWorkoutStore.setCurrentWorkout(nil, for: selectedProfile)
                        currentWorkout = nil
                        editingCurrentDraft = nil
                    }
                }
            )
        }
    }

    private func refreshCurrentWorkout() {
        currentWorkout = CurrentWorkoutStore.currentWorkout(for: selectedProfile)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func addDay(_ day: WorkoutDay) async {
        do {
            try await WorkoutStore.addDay(day)
        } catch {
            // Sync error; data is cached locally. Sheet will still dismiss.
        }
    }
}
