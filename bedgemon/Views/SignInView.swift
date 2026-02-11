//
//  SignInView.swift
//  bedgemon
//

import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @ObservedObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("nailong")
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal)

                Text("bedgemon")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                SignInWithAppleButton(.continue, onRequest: { request in
                    request.requestedScopes = []
                }, onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        auth.handleAuthorization(authorization)
                    case .failure:
                        break
                    }
                })
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 40)
            }
        }
    }
}
