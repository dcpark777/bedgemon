//
//  HomeView.swift
//  bedgemon
//

import SwiftUI

struct HomeView: View {
    let profile: Profile

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        tileGrid
                    }
                    .padding()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .workoutTracker:
                    WorkoutTrackerView(profile: profile)
                }
            }
        }
    }

    private var tileGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ], spacing: 16) {
            ForEach(HomeTile.allTiles) { tile in
                NavigationLink(value: tile.id) {
                    HomeTileCard(tile: tile)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct HomeTileCard: View {
    let tile: HomeTile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: tile.systemImageName)
                .font(.system(size: 32))
                .foregroundStyle(.tint)
            Text(tile.title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView(profile: .sarah)
}
