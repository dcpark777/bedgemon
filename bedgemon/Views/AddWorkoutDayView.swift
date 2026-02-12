//
//  AddWorkoutDayView.swift
//  bedgemon
//

import SwiftUI

struct AddWorkoutDayView: View {
    let profile: Profile
    /// Pre-filled date when starting from Start Workout flow.
    var initialDate: Date?
    /// Pre-filled exercises (e.g. from a template) when starting from Start Workout flow.
    var initialExercises: [ExerciseEntry]?
    /// When set, we're editing an existing workout (preserve id and allow adding exercises over time).
    var existingDay: WorkoutDay?
    /// When true, this is the "current workout": title "Current workout", button "Finish". Saving adds to past workouts.
    var isOngoingWorkout: Bool = false
    let onSave: (WorkoutDay) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var exercises: [ExerciseEntry] = []
    @State private var editingExercise: ExerciseEntry?

    init(profile: Profile, initialDate: Date? = nil, initialExercises: [ExerciseEntry]? = nil, existingDay: WorkoutDay? = nil, isOngoingWorkout: Bool = false, onSave: @escaping (WorkoutDay) -> Void) {
        self.profile = profile
        self.initialDate = initialDate
        self.initialExercises = initialExercises
        self.existingDay = existingDay
        self.isOngoingWorkout = isOngoingWorkout
        self.onSave = onSave
        let startDate: Date
        if let existing = existingDay {
            startDate = existing.date
        } else {
            startDate = initialDate.map { Calendar.current.startOfDay(for: $0) } ?? Calendar.current.startOfDay(for: Date())
        }
        _date = State(initialValue: startDate)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .center)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                } header: {
                    Text("Date")
                }

                Section {
                    if exercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("No exercises yet")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text("Tap below to add your first exercise.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(exercises) { exercise in
                            Button {
                                editingExercise = exercise
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, alignment: .center)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exerciseDisplayName(exercise))
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        if !exercise.sets.isEmpty {
                                            Text(exerciseSetSummary(exercise))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text("\(exercise.totalSets) set\(exercise.totalSets == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color(.secondarySystemGroupedBackground))
                        }
                        .onDelete(perform: deleteExercises)
                    }

                    Button {
                        let newEx = ExerciseEntry(name: "")
                        editingExercise = newEx
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("Exercises")
                } footer: {
                    if isOngoingWorkout {
                        Text("When you're done, tap Finish to save this workout to history.")
                    } else {
                        Text("Save to keep your changes.")
                    }
                }
            }
            .listSectionSpacing(20)
            .navigationTitle(
                isOngoingWorkout ? "Current workout" : (existingDay == nil ? "New workout" : "Edit workout")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isOngoingWorkout ? "Finish" : "Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $editingExercise) { exercise in
                EditExerciseView(
                    exercise: exercise,
                    onSave: { updated in
                        if let idx = exercises.firstIndex(where: { $0.id == updated.id }) {
                            exercises[idx] = updated
                        } else {
                            exercises.append(updated)
                        }
                        editingExercise = nil
                    },
                    onCancel: { editingExercise = nil }
                )
            }
            .onAppear {
                if let existing = existingDay {
                    exercises = existing.exercises
                } else if let initial = initialExercises, exercises.isEmpty, !initial.isEmpty {
                    exercises = initial
                }
            }
        }
    }

    private func exerciseDisplayName(_ exercise: ExerciseEntry) -> String {
        let t = exercise.name.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "New exercise" : t
    }

    private func exerciseSetSummary(_ exercise: ExerciseEntry) -> String {
        exercise.sets.prefix(4).map { "\($0.reps)×\(formatWeight($0.weight))" }.joined(separator: ", ")
    }

    private func formatWeight(_ w: Double) -> String {
        if w == 0 { return "0" }
        if w.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }

    private func deleteExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func save() {
        let valid = exercises.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let day = WorkoutDay(
            id: existingDay?.id ?? UUID(),
            date: date,
            exercises: valid,
            loggedBy: existingDay?.loggedBy ?? profile
        )
        onSave(day)
        dismiss()
    }
}
