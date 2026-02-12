//
//  EditExerciseCollectionView.swift
//  bedgemon
//
//  Create or edit an exercise collection (template): name + list of exercises with optional sets, reps, weight.
//

import SwiftUI

struct EditExerciseCollectionView: View {
    /// nil = create new; non-nil = edit existing.
    let collection: ExerciseCollection?
    let onSave: (ExerciseCollection) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var exercises: [TemplateExerciseItem] = []

    private var canSave: Bool {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        let valid = exercises.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        return !valid.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Template name") {
                    TextField("e.g. Leg day, Upper body", text: $name)
                }

                Section {
                    ForEach(exercises) { item in
                        templateExerciseRow(item)
                    }
                    .onDelete(perform: deleteExercises)
                    Button {
                        exercises.append(TemplateExerciseItem(name: ""))
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    Text("Name is required. Sets, reps per set, and weight are optional and will pre-fill the workout when you use this template.")
                }
            }
            .navigationTitle(collection == nil ? "New template" : "Edit template")
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
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let c = collection {
                    name = c.name
                    exercises = c.exercises.isEmpty ? [TemplateExerciseItem(name: "")] : c.exercises
                } else {
                    exercises = [TemplateExerciseItem(name: "")]
                }
            }
        }
    }

    private func templateExerciseRow(_ item: TemplateExerciseItem) -> some View {
        let idx = exercises.firstIndex(where: { $0.id == item.id }) ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            TextField("Exercise name", text: Binding(
                get: { exercises[idx].name },
                set: { newVal in
                    var u = exercises[idx]
                    u.name = newVal
                    exercises[idx] = u
                }
            ))

            HStack(spacing: 16) {
                optionalIntField(
                    label: "Sets",
                    value: Binding(
                        get: { exercises[idx].setsCount },
                        set: { newVal in
                            var u = exercises[idx]
                            u.setsCount = newVal
                            exercises[idx] = u
                        }
                    ),
                    placeholder: "—"
                )
                optionalIntField(
                    label: "Reps/set",
                    value: Binding(
                        get: { exercises[idx].repsPerSet },
                        set: { newVal in
                            var u = exercises[idx]
                            u.repsPerSet = newVal
                            exercises[idx] = u
                        }
                    ),
                    placeholder: "—"
                )
                optionalWeightField(
                    label: "Weight (lb)",
                    value: Binding(
                        get: { exercises[idx].weight },
                        set: { newVal in
                            var u = exercises[idx]
                            u.weight = newVal
                            exercises[idx] = u
                        }
                    ),
                    placeholder: "—"
                )
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func optionalIntField(label: String, value: Binding<Int?>, placeholder: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: Binding(
                get: { value.wrappedValue.map { String($0) } ?? "" },
                set: { value.wrappedValue = Int($0).flatMap { $0 >= 0 ? $0 : nil } }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 44)
        }
    }

    private func optionalWeightField(label: String, value: Binding<Double?>, placeholder: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: Binding(
                get: {
                    guard let v = value.wrappedValue else { return "" }
                    return v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
                },
                set: {
                    let trimmed = $0.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        value.wrappedValue = nil
                    } else if let v = Double(trimmed), v >= 0 {
                        value.wrappedValue = v
                    }
                }
            ))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 50)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let valid = exercises
            .map { item in
                var copy = item
                copy.name = item.name.trimmingCharacters(in: .whitespaces)
                return copy
            }
            .filter { !$0.name.isEmpty }
        guard !valid.isEmpty else { return }
        let saved = ExerciseCollection(
            id: collection?.id ?? UUID(),
            name: trimmedName,
            exercises: valid
        )
        onSave(saved)
        dismiss()
    }
}
