//
//  WorkoutStore.swift
//  bedgemon
//
//  Workout days are stored per profile (Sarah vs Dan). Synced via iCloud CloudKit.
//  Either user can create/edit workouts for both; the selected profile determines whose list is shown/edited.
//

import CloudKit
import Foundation

private enum RecordKeys {
    static let type = "WorkoutDay"
    static let id = "id"
    static let date = "date"
    static let exercisesData = "exercisesData"
    static let loggedBy = "loggedBy"
}

/// Per-profile workout log; syncs via CloudKit. Use load(profile:) to get one person's list.
enum WorkoutStore {
    private static let defaults = UserDefaults.standard
    private static let container = CKContainer.default()
    private static var publicDB: CKDatabase { container.publicCloudDatabase }

    private static func localKey(for profile: Profile) -> String {
        "workoutDays_\(profile.rawValue)"
    }

    // MARK: - Public API (async)

    /// Load workout days for the given profile. Fetches from CloudKit when possible and updates local cache.
    static func load(profile: Profile) async -> [WorkoutDay] {
        do {
            let remote = try await fetchFromCloudKit(profile: profile)
            let sorted = sortByDate(remote)
            cacheLocally(profile: profile, days: sorted)
            return sorted
        } catch {
            return loadFromLocalCache(profile: profile)
        }
    }

    /// Add one workout day (day.loggedBy must be set to the profile this belongs to).
    static func addDay(_ day: WorkoutDay) async throws {
        guard let profile = day.loggedBy else { return }
        try await saveRecord(day)
        var cached = loadFromLocalCache(profile: profile)
        if !cached.contains(where: { $0.id == day.id }) {
            cached.insert(day, at: 0)
            cacheLocally(profile: profile, days: sortByDate(cached))
        }
    }

    /// Delete one workout day from the given profile's list (CloudKit + local cache).
    static func deleteDay(id: UUID, profile: Profile) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await publicDB.deleteRecord(withID: recordID)
        var cached = loadFromLocalCache(profile: profile)
        cached.removeAll { $0.id == id }
        cacheLocally(profile: profile, days: cached)
    }

    // MARK: - CloudKit

    private static func fetchFromCloudKit(profile: Profile) async throws -> [WorkoutDay] {
        let predicate = NSPredicate(format: "loggedBy == %@", profile.rawValue)
        let query = CKQuery(recordType: RecordKeys.type, predicate: predicate)
        var all: [WorkoutDay] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let (matchResults, nextCursor) = if let c = cursor {
                try await publicDB.records(continuingMatchFrom: c)
            } else {
                try await publicDB.records(matching: query)
            }
            cursor = nextCursor
            for (_, result) in matchResults {
                if case .success(let record) = result, let day = decode(record) {
                    all.append(day)
                }
            }
        } while cursor != nil
        return all
    }

    private static func saveRecord(_ day: WorkoutDay) async throws {
        let recordID = CKRecord.ID(recordName: day.id.uuidString)
        let record = CKRecord(recordType: RecordKeys.type, recordID: recordID)
        record[RecordKeys.id] = day.id.uuidString
        record[RecordKeys.date] = day.date
        record[RecordKeys.loggedBy] = day.loggedBy?.rawValue
        if let data = try? JSONEncoder().encode(day.exercises) {
            record[RecordKeys.exercisesData] = data
        }
        _ = try await publicDB.save(record)
    }

    private static func decode(_ record: CKRecord) -> WorkoutDay? {
        guard let idStr = record[RecordKeys.id] as? String,
              let id = UUID(uuidString: idStr),
              let date = record[RecordKeys.date] as? Date else { return nil }
        let exercises: [ExerciseEntry] = (record[RecordKeys.exercisesData] as? Data).flatMap {
            try? JSONDecoder().decode([ExerciseEntry].self, from: $0)
        } ?? []
        let loggedBy: Profile? = (record[RecordKeys.loggedBy] as? String).flatMap(Profile.init(rawValue:))
        return WorkoutDay(id: id, date: date, exercises: exercises, loggedBy: loggedBy)
    }

    // MARK: - Local cache

    private static func sortByDate(_ days: [WorkoutDay]) -> [WorkoutDay] {
        let cal = Calendar.current
        return days.sorted { cal.startOfDay(for: $0.date) > cal.startOfDay(for: $1.date) }
    }

    private static func cacheLocally(profile: Profile, days: [WorkoutDay]) {
        guard let data = try? JSONEncoder().encode(days) else { return }
        defaults.set(data, forKey: localKey(for: profile))
    }

    private static func loadFromLocalCache(profile: Profile) -> [WorkoutDay] {
        let key = localKey(for: profile)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WorkoutDay].self, from: data) else {
            return []
        }
        return sortByDate(decoded)
    }
}
