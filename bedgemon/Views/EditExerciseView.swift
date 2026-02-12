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
            .listSectionSpacing(16)
            .navigationTitle(exercise.name.isEmpty ? "New exercise" : "Edit exercise")
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
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { focusedField = nil }
                            .fontWeight(.medium)
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
            HStack(spacing: 12) {
                Image(systemName: "textformat")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .center)
                TextField("e.g. Bench Press, Squat", text: $name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color(.secondarySystemGroupedBackground))
        } header: {
            Text("Name")
        } footer: {
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Name this exercise so you can find it later.")
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
                    .font(.subheadline.weight(.semibold))
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        } header: {
            Text("Sets")
        } footer: {
            if sets.isEmpty {
                Text("Add sets with reps and weight for each.")
            } else {
                Text("Swipe left on a set to delete.")
            }
        }
    }

    private func setRow(index: Int) -> some View {
        HStack(spacing: 16) {
            Text("Set \(index + 1)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption)
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
                    .font(.caption)
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
        .padding(.vertical, 8)
        .listRowBackground(Color(.secondarySystemGroupedBackground))
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
