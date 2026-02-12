//
//  InitialSplashView.swift
//  bedgemon
//
//  App's initial screen: picture, bedgemon, and Home button. Tapping Home goes to the home page with tiles.
//

import SwiftUI

struct InitialSplashView: View {
    var onHome: () -> Void = {}

    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("nailong")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 40)

                Text("bedgemon")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Button(action: onHome) {
                    Label("Home", systemImage: "house.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    InitialSplashView()
}
