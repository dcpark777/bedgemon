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
                Picker("Profile", selection: $selectedProfile) {
                    Text("Sarah").tag(Profile.sarah)
                    Text("Dan").tag(Profile.dan)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Workouts for")
            }

            if let current = currentWorkout {
                Section {
                    Button {
                        editingCurrentDraft = current
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.run")
                                .font(.title2)
                                .foregroundStyle(.tint)
                                .frame(width: 32, alignment: .center)
                            Text(shortDate(current.date))
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.accentColor.opacity(0.08))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Current workout")
                } footer: {
                    Text("Tap to open. Tap Finish to save.")
                }
            }

            Section {
                Button {
                    showingStartWorkout = true
                } label: {
                    Label("Start workout", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: {
                Text("New workout")
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
                    Label("Templates", systemImage: "square.stack.3d.up")
                }
            } header: {
                Text("History")
            }
        }
        .listSectionSpacing(24)
        .navigationTitle("Workouts")
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
