//
//  HomeView.swift
//  bedgemon
//

import SwiftUI

struct HomeView: View {
    let profile: Profile

    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("nailong")
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal)

                Text("Hello, \(profile == .sarah ? "Sarah" : "Dan")!")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
        }
    }
}
