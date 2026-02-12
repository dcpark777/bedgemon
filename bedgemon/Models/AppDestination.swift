//
//  AppDestination.swift
//  bedgemon
//

import SwiftUI

/// Top-level destinations in the app sidebar menu.
enum AppDestination: String, CaseIterable, Hashable {
    case home
    case workoutTracker

    var title: String {
        switch self {
        case .home: return "Home"
        case .workoutTracker: return "Workout Tracker"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .workoutTracker: return "figure.strengthtraining.traditional"
        }
    }
}
