//
//  EditExerciseView.swift
//  bedgemon
//

import SwiftUI

struct EditExerciseView: View {
    let exercise: ExerciseEntry
    let onSave: (ExerciseEntry) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var name: String = ""
    @State private var sets: [WorkoutSet] = []

    private enum Field: Hashable {
        case name
        case reps(Int)
        case weight(Int)
    }

    var body: some View {
        NavigationStack {
            List {
                exerciseNameSection
                setsSection
            }
            .navigationTitle(exercise.name.isEmpty ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
            }
            .onAppear {
                name = exercise.name
                sets = exercise.sets.isEmpty ? [WorkoutSet(reps: 0, weight: 0)] : exercise.sets
            }
        }
    }

    private var exerciseNameSection: some View {
        Section {
            TextField("e.g. Bench Press, Squat", text: $name)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
        } header: {
            Text("Exercise name")
        } footer: {
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Give your exercise a name so you can find it later.")
            }
        }
    }

    private var setsSection: some View {
        Section {
            ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                setRow(index: index)
            }
            .onDelete(perform: deleteSets)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sets.append(WorkoutSet(reps: 0, weight: 0))
                }
            } label: {
                Label("Add set", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
            }
        } header: {
            Text("Sets")
        } footer: {
            if sets.isEmpty {
                Text("Tap \"Add set\" to log reps and weight for each set.")
            } else {
                Text("Swipe left on a set to remove it.")
            }
        }
    }

    private func setRow(index: Int) -> some View {
        HStack(spacing: 16) {
            Text("Set \(index + 1)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("0", value: Binding(
                    get: { sets[index].reps },
                    set: { sets[index] = WorkoutSet(reps: max(0, $0), weight: sets[index].weight) }
                ), format: .number)
                .focused($focusedField, equals: .reps(index))
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text("Weight (lb)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("0", value: Binding(
                    get: { sets[index].weight },
                    set: { sets[index] = WorkoutSet(reps: sets[index].reps, weight: max(0, $0)) }
                ), format: .number)
                .focused($focusedField, equals: .weight(index))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
    }

    private func deleteSets(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let entry = ExerciseEntry(
            id: exercise.id,
            name: trimmed.isEmpty ? "Exercise" : trimmed,
            sets: sets
        )
        onSave(entry)
        dismiss()
    }
}
