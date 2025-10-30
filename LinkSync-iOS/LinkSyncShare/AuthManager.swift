//  AuthManager.swift
//  LinkSyncShare
//
//  Created by Wayne on 10/22/25.
//
import Foundation
import Amplify
import AWSCognitoAuthPlugin

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private var hasConfiguredAmplify = false
    @Published var isAuthenticated: Bool = false
    
    private init() {
        Task {
            AmplifyConfiguration.configure()
            await checkAuthSession()
        }
    }

    // MARK: - Configure Amplify
    private func configureAmplifyIfNeeded() async {
        guard !hasConfiguredAmplify else { return }
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            hasConfiguredAmplify = true
            print("✅ Amplify configured in Share Extension")
        } catch let error as AmplifyError where error.errorDescription.contains("already configured") {
            print("ℹ️ Amplify already configured, skipping")
        } catch {
            print("❌ Failed to configure Amplify in Share Extension: \(error)")
        }
    }

    // MARK: - Check session validity
    func checkAuthSession() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            isAuthenticated = session.isSignedIn
            print("🔑 Share Extension Authenticated: \(isAuthenticated)")
        } catch {
            isAuthenticated = false
            print("❌ Failed to fetch auth session in Share Extension: \(error)")
        }
    }
    
    // MARK: - Get User ID
    func getCurrentUserId() async -> String? {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            print("✅ Retrieved user ID: \(user.userId)")
            return user.userId
        } catch {
            print("❌ Failed to get user ID: \(error)")
            return nil
        }
    }
}
