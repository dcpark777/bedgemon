//
//  CollectionStore.swift
//  bedgemon
//
//  Exercise collections (templates) synced via CloudKit. Shared by both users.
//

import CloudKit
import Foundation

private enum CollectionRecordKeys {
    static let type = "ExerciseCollection"
    static let id = "id"
    static let name = "name"
    /// We use the existing production field for both legacy [String] and new [TemplateExerciseItem] JSON to avoid schema changes.
    static let exerciseNamesData = "exerciseNamesData"
}

enum CollectionStore {
    private static let defaults = UserDefaults.standard
    private static let localKey = "exerciseCollections"
    private static let container = CKContainer.default()
    private static var publicDB: CKDatabase { container.publicCloudDatabase }

    static func load() async -> [ExerciseCollection] {
        do {
            let remote = try await fetchAllFromCloudKit()
            cacheLocally(remote)
            return remote.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            return loadFromLocalCache()
        }
    }

    static func add(_ collection: ExerciseCollection) async throws {
        try await saveRecord(collection)
        var cached = loadFromLocalCache()
        if !cached.contains(where: { $0.id == collection.id }) {
            cached.append(collection)
            cacheLocally(cached)
        }
    }

    static func delete(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await publicDB.deleteRecord(withID: recordID)
        var cached = loadFromLocalCache()
        cached.removeAll { $0.id == id }
        cacheLocally(cached)
    }

    private static func fetchAllFromCloudKit() async throws -> [ExerciseCollection] {
        let query = CKQuery(recordType: CollectionRecordKeys.type, predicate: NSPredicate(value: true))
        var all: [ExerciseCollection] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let (matchResults, nextCursor) = if let c = cursor {
                try await publicDB.records(continuingMatchFrom: c)
            } else {
                try await publicDB.records(matching: query)
            }
            cursor = nextCursor
            for (_, result) in matchResults {
                if case .success(let record) = result, let col = decode(record) {
                    all.append(col)
                }
            }
        } while cursor != nil
        return all
    }

    private static func saveRecord(_ collection: ExerciseCollection) async throws {
        let recordID = CKRecord.ID(recordName: collection.id.uuidString)
        let record = CKRecord(recordType: CollectionRecordKeys.type, recordID: recordID)
        record[CollectionRecordKeys.id] = collection.id.uuidString
        record[CollectionRecordKeys.name] = collection.name
        if let data = try? JSONEncoder().encode(collection.exercises) {
            record[CollectionRecordKeys.exerciseNamesData] = data
        }
        _ = try await publicDB.save(record)
    }

    private static func decode(_ record: CKRecord) -> ExerciseCollection? {
        guard let idStr = record[CollectionRecordKeys.id] as? String,
              let id = UUID(uuidString: idStr),
              let name = record[CollectionRecordKeys.name] as? String else { return nil }
        guard let data = record[CollectionRecordKeys.exerciseNamesData] as? Data else {
            return ExerciseCollection(id: id, name: name, exercises: [])
        }
        if let items = try? JSONDecoder().decode([TemplateExerciseItem].self, from: data) {
            return ExerciseCollection(id: id, name: name, exercises: items)
        }
        if let names = try? JSONDecoder().decode([String].self, from: data) {
            return ExerciseCollection(id: id, name: name, exerciseNames: names)
        }
        return ExerciseCollection(id: id, name: name, exercises: [])
    }

    private static func cacheLocally(_ collections: [ExerciseCollection]) {
        guard let data = try? JSONEncoder().encode(collections) else { return }
        defaults.set(data, forKey: localKey)
    }

    private static func loadFromLocalCache() -> [ExerciseCollection] {
        guard let data = defaults.data(forKey: localKey),
              let decoded = try? JSONDecoder().decode([ExerciseCollection].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
