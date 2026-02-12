//
//  WorkoutModels.swift
//  bedgemon
//

import Foundation

/// A single set: reps and weight.
struct WorkoutSet: Codable, Hashable {
    var reps: Int
    var weight: Double

    init(reps: Int = 0, weight: Double = 0) {
        self.reps = max(0, reps)
        self.weight = max(0, weight)
    }
}

/// One exercise within a workout day: name + sets.
struct ExerciseEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var sets: [WorkoutSet]

    var totalSets: Int { sets.count }

    init(id: UUID = UUID(), name: String, sets: [WorkoutSet] = []) {
        self.id = id
        self.name = name
        self.sets = sets
    }
}

/// A full workout day: date + list of exercises. Shared by both users; loggedBy records who added it.
struct WorkoutDay: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var exercises: [ExerciseEntry]
    /// Who logged this workout (Sarah or Dan). Used for attribution only; data is shared.
    var loggedBy: Profile?

    var exerciseCount: Int { exercises.count }
    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }

    init(id: UUID = UUID(), date: Date, exercises: [ExerciseEntry] = [], loggedBy: Profile? = nil) {
        self.id = id
        self.date = date
        self.exercises = exercises
        self.loggedBy = loggedBy
    }
}
