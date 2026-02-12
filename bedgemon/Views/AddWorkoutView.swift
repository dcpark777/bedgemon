//
//  AddWorkoutView.swift
//  bedgemon
//

import SwiftUI

struct AddWorkoutView: View {
    let profile: Profile
    let onSave: (WorkoutEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var name = ""
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Workout name", text: $name)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let entry = WorkoutEntry(date: date, name: trimmedName, notes: notes.isEmpty ? nil : notes)
        onSave(entry)
        dismiss()
    }
}
