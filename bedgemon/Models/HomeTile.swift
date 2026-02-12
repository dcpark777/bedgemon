//
//  HomeTile.swift
//  bedgemon
//

import SwiftUI

/// Navigable destinations from the Home screen.
enum AppRoute: Hashable {
    case workoutTracker
}

/// Definition for a single tile on the Home screen.
struct HomeTile: Identifiable {
    let id: AppRoute
    let title: String
    let systemImageName: String

    static let allTiles: [HomeTile] = [
        HomeTile(id: .workoutTracker, title: "Workout Tracker", systemImageName: "figure.strengthtraining.traditional")
    ]
}
