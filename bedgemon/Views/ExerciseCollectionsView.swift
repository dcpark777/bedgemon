//
//  ExerciseCollectionsView.swift
//  bedgemon
//
//  List and manage exercise collections (templates) used when starting a workout.
//

import SwiftUI

struct ExerciseCollectionsView: View {
    @State private var collections: [ExerciseCollection] = []
    @State private var editingCollection: ExerciseCollection?
    @State private var showingAddCollection = false
    @State private var isLoading = false

    var body: some View {
        List {
            if let msg = syncErrorMessage {
                Section {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            ForEach(collections) { collection in
                Button {
                    editingCollection = collection
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(collection.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            if !collection.exercises.isEmpty {
                                Text(collection.exercises.map(\.name).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteCollections)

            Section {
                Button {
                    showingAddCollection = true
                } label: {
                    Label("New template", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
        .overlay {
            if isLoading {
                ProgressView("Syncing…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showingAddCollection) {
            EditExerciseCollectionView(collection: nil, onSave: { new in
                Task { await addCollection(new) }
                showingAddCollection = false
            }, onCancel: { showingAddCollection = false })
        }
        .sheet(item: $editingCollection) { collection in
            EditExerciseCollectionView(collection: collection, onSave: { updated in
                Task { await updateCollection(updated) }
                editingCollection = nil
            }, onCancel: { editingCollection = nil })
        }
    }

    @State private var syncErrorMessage: String?

    private func reload() async {
        isLoading = true
        syncErrorMessage = nil
        defer { isLoading = false }
        collections = await CollectionStore.load()
    }

    private func addCollection(_ collection: ExerciseCollection) async {
        isLoading = true
        syncErrorMessage = nil
        defer { isLoading = false }
        do {
            try await CollectionStore.add(collection)
            collections = await CollectionStore.load()
        } catch {
            syncErrorMessage = "Couldn’t sync template: \(error.localizedDescription)"
            collections = await CollectionStore.load()
        }
    }

    private func updateCollection(_ collection: ExerciseCollection) async {
        isLoading = true
        syncErrorMessage = nil
        defer { isLoading = false }
        do {
            try await CollectionStore.add(collection)  // same record ID overwrites in CloudKit
            collections = await CollectionStore.load()
        } catch {
            syncErrorMessage = "Couldn’t save: \(error.localizedDescription)"
            collections = await CollectionStore.load()
        }
    }

    private func deleteCollections(at offsets: IndexSet) {
        let toDelete = offsets.map { collections[$0] }
        Task {
            isLoading = true
            syncErrorMessage = nil
            defer { isLoading = false }
            for collection in toDelete {
                try? await CollectionStore.delete(id: collection.id)
            }
            collections = await CollectionStore.load()
        }
    }
}
