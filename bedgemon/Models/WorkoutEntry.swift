//
//  WorkoutEntry.swift
//  bedgemon
//

import Foundation

/// Simple workout log entry (v1); persisted per profile.
struct WorkoutEntry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var name: String
    var notes: String?

    init(id: UUID = UUID(), date: Date = Date(), name: String, notes: String? = nil) {
        self.id = id
        self.date = date
        self.name = name
        self.notes = notes
    }
}
