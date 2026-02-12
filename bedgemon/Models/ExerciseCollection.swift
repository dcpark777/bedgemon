//
//  ExerciseCollection.swift
//  bedgemon
//

import Foundation

/// One exercise in a template: name plus optional default sets/reps/weight.
struct TemplateExerciseItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    /// Optional: number of sets to pre-fill.
    var setsCount: Int?
    /// Optional: reps per set (used for each pre-filled set).
    var repsPerSet: Int?
    /// Optional: weight per set in lb (used for each pre-filled set).
    var weight: Double?

    init(id: UUID = UUID(), name: String, setsCount: Int? = nil, repsPerSet: Int? = nil, weight: Double? = nil) {
        self.id = id
        self.name = name
        self.setsCount = setsCount
        self.repsPerSet = repsPerSet
        self.weight = weight
    }
}

/// Template for a workout: named collection of exercises with optional set/reps/weight. Used to pre-fill a new workout (e.g. "Leg day").
struct ExerciseCollection: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var exercises: [TemplateExerciseItem]

    init(id: UUID = UUID(), name: String, exercises: [TemplateExerciseItem] = []) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }

    /// Legacy: template created with just exercise names (no set/reps/weight).
    init(id: UUID = UUID(), name: String, exerciseNames: [String]) {
        self.id = id
        self.name = name
        self.exercises = exerciseNames.map { TemplateExerciseItem(name: $0) }
    }

    /// Converts this template into exercise entries for a new workout. Uses optional sets/reps/weight when provided.
    func toExerciseEntries() -> [ExerciseEntry] {
        exercises.map { item in
            let sets: [WorkoutSet]
            if let count = item.setsCount, count > 0 {
                let reps = max(0, item.repsPerSet ?? 0)
                let w = max(0, item.weight ?? 0)
                sets = (0..<count).map { _ in WorkoutSet(reps: reps, weight: w) }
            } else {
                sets = []
            }
            return ExerciseEntry(name: item.name, sets: sets)
        }
    }
}
