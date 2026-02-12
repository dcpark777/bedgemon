//
//  StartWorkoutView.swift
//  bedgemon
//
//  Pick date and optional template, then create a current workout draft.
//  User taps the new "Current workout" on the hub to add/edit exercises and finish.
//

import SwiftUI

struct StartWorkoutView: View {
    let profile: Profile
    /// Called with the new draft; parent stores it as current workout and dismisses.
    let onStartWorkout: (WorkoutDay) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var date = Calendar.current.startOfDay(for: Date())
    @State private var collections: [ExerciseCollection] = []
    @State private var selectedTemplate: ExerciseCollection?
    @State private var isLoadingCollections = false

    private var initialExercises: [ExerciseEntry] {
        selectedTemplate?.toExerciseEntries() ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                    Section("Date") {
                        DatePicker("Workout date", selection: $date, displayedComponents: .date)
                    }

                    Section {
                        if isLoadingCollections {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            Button {
                                selectedTemplate = nil
                            } label: {
                                HStack {
                                    Text("Start from scratch")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedTemplate == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            ForEach(collections) { collection in
                                Button {
                                    selectedTemplate = collection
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(collection.name)
                                                .foregroundStyle(.primary)
                                            if !collection.exercises.isEmpty {
                                                Text("\(collection.exercises.count) exercises")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if selectedTemplate?.id == collection.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Template")
                    } footer: {
                        Text("Optional. A template pre-fills the exercise list when you open the current workout.")
                    }

                    Section {
                        Button {
                            let draft = WorkoutDay(
                                date: date,
                                exercises: initialExercises,
                                loggedBy: profile
                            )
                            onStartWorkout(draft)
                            dismiss()
                        } label: {
                            Label("Start workout", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                    } footer: {
                        Text("A \"Current workout\" will appear on the tracker. Tap it to add or edit exercises, then finish to save to past workouts.")
                    }
                }
                .navigationTitle("New workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .task {
                    isLoadingCollections = true
                    defer { isLoadingCollections = false }
                    collections = await CollectionStore.load()
                }
            }
        }
    }
