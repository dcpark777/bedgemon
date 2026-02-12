//
//  CurrentWorkoutStore.swift
//  bedgemon
//
//  Stores the in-progress workout draft per profile. Not synced to CloudKit
//  until the user taps "Finish workout" in the current workout editor.
//

import Foundation

enum CurrentWorkoutStore {
    private static let defaults = UserDefaults.standard

    private static func key(for profile: Profile) -> String {
        "bedgemon_currentWorkout_\(profile.rawValue)"
    }

    /// The current (in-progress) workout for the profile, if any.
    static func currentWorkout(for profile: Profile) -> WorkoutDay? {
        guard let data = defaults.data(forKey: key(for: profile)) else { return nil }
        return try? JSONDecoder().decode(WorkoutDay.self, from: data)
    }

    /// Set the current workout draft. Pass nil to clear (e.g. after finishing).
    static func setCurrentWorkout(_ day: WorkoutDay?, for profile: Profile) {
        if let day = day {
            let data = (try? JSONEncoder().encode(day)) ?? Data()
            defaults.set(data, forKey: key(for: profile))
        } else {
            defaults.removeObject(forKey: key(for: profile))
        }
    }
}
