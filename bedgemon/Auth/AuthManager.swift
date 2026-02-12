//
//  AuthManager.swift
//  bedgemon
//

import AuthenticationServices
import Foundation
import SwiftUI
import Combine
import UIKit

private enum UserDefaultsKeys {
    static let appleUserIDToProfile = "appleUserIDToProfile"
    static let lastSignedInAppleUserID = "lastSignedInAppleUserID"
}

@MainActor
final class AuthManager: NSObject, ObservableObject {
    
    @Published var profile: Profile?
    @Published var pendingAppleUserID: String?

    private let defaults = UserDefaults.standard
    private var mapping: [String: Profile] {
        get {
            guard let data = defaults.data(forKey: UserDefaultsKeys.appleUserIDToProfile),
                  let decoded = try? JSONDecoder().decode([String: Profile].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: UserDefaultsKeys.appleUserIDToProfile)
        }
    }

    private var lastSignedInAppleUserID: String? {
        get { defaults.string(forKey: UserDefaultsKeys.lastSignedInAppleUserID) }
        set { defaults.set(newValue, forKey: UserDefaultsKeys.lastSignedInAppleUserID) }
    }

    private var authController: ASAuthorizationController?

    override init() {
        super.init()
    }

    /// Call on app launch to restore profile if the user was previously signed in.
    func checkRestoreSession() async {
        guard let lastID = lastSignedInAppleUserID else {
            profile = nil
            pendingAppleUserID = nil
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        // credentialState(forUserID:) is async/throws on modern SDKs
        let state: ASAuthorizationAppleIDProvider.CredentialState
        do {
            state = try await provider.credentialState(forUserID: lastID)
        } catch {
            // Treat errors like not found/revoked
            lastSignedInAppleUserID = nil
            profile = nil
            pendingAppleUserID = nil
            return
        }
        switch state {
        case .authorized:
            if let p = mapping[lastID] {
                profile = p
                pendingAppleUserID = nil
            } else {
                lastSignedInAppleUserID = nil
                profile = nil
                pendingAppleUserID = nil
            }
        case .revoked, .notFound, .transferred:
            lastSignedInAppleUserID = nil
            profile = nil
            pendingAppleUserID = nil
        @unknown default:
            lastSignedInAppleUserID = nil
            profile = nil
            pendingAppleUserID = nil
        }
    }

    /// Apple ID email that is treated as Dan. All others (or no email) map to Sarah.
    private static let danAppleIDEmail = "dan.park.primary@gmail.com"

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email]  // needed to get email for profile auto-assignment

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authController = controller
        controller.performRequests()
    }

    func bindUnknownUserToProfile(_ profile: Profile) {
        guard let id = pendingAppleUserID else { return }
        var m = mapping
        m[id] = profile
        mapping = m
        lastSignedInAppleUserID = id
        self.profile = profile
        pendingAppleUserID = nil
    }

    /// Call this when using SwiftUI SignInWithAppleButton's onCompletion(.success(authorization)).
    func handleAuthorization(_ authorization: ASAuthorization) {
        applyAuthorization(authorization)
    }

    /// Resolves profile from credential: dan.park.primary@gmail.com → Dan, otherwise → Sarah. Saves mapping so future sign-ins use the same profile.
    private func applyAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let appleUserID = credential.user
        if let p = mapping[appleUserID] {
            profile = p
            lastSignedInAppleUserID = appleUserID
            pendingAppleUserID = nil
        } else {
            let resolvedProfile: Profile
            if let email = credential.email, email == Self.danAppleIDEmail {
                resolvedProfile = .dan
            } else {
                resolvedProfile = .sarah
            }
            var m = mapping
            m[appleUserID] = resolvedProfile
            mapping = m
            lastSignedInAppleUserID = appleUserID
            profile = resolvedProfile
            pendingAppleUserID = nil
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        applyAuthorization(authorization)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // User cancelled or error; leave state unchanged.
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Prefer the foreground-active scene
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first

        // Return an existing key window if available
        if let window = activeScene?.keyWindow { return window }
        if let window = activeScene?.windows.first(where: { $0.isKeyWindow }) { return window }
        if let window = activeScene?.windows.first { return window }

        // As a last resort, create a temporary window bound to a scene to satisfy API requirements
        if let scene = activeScene {
            return UIWindow(windowScene: scene)
        }

        // If no scenes are available, fall back to any key window across scenes
        if let anyKey = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) { return anyKey }

        // Final fallback: Avoid deprecated UIWindow() initializer.
        // If we still haven't found a window, try to create one only if we have a scene.
        if let scene = activeScene {
            return UIWindow(windowScene: scene)
        }

        // If no scenes are available, this API shouldn't be called. In debug, surface a warning.
        assertionFailure("ASAuthorizationController requires a window scene to present. No active scenes available.")

        // Try to bind a new window to any available scene (avoids deprecated UIWindow()).
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            return UIWindow(windowScene: scene)
        }

        // No scene available; presenting Sign in with Apple is impossible. Crash in debug rather than use deprecated init.
        fatalError("No window scene available for Sign in with Apple presentation.")
    }
}
