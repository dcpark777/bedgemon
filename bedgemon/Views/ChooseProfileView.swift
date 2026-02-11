//
//  ChooseProfileView.swift
//  bedgemon
//

import SwiftUI

struct ChooseProfileView: View {
    @ObservedObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Who's using the app?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Button("Sarah") {
                    auth.bindUnknownUserToProfile(.sarah)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)

                Button("Dan") {
                    auth.bindUnknownUserToProfile(.dan)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }
}
