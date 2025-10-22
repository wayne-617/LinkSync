//
//  AuthManager.swift
//  LinkSyncShare
//
//  Created by Wayne on 10/22/25.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin
import Security

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults(suiteName: Config.appGroupIdentifier)
    private var isConfigured = false
    
    private init() {
        // Don't check auth status in init - wait for configureAmplify to be called
    }
    
    func configureAmplify() async {
        guard !isConfigured else { return }
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ Share Extension: Amplify configured successfully")
            isConfigured = true
            
            // Now that Amplify is configured, check auth status
            await checkAuthStatus()
        } catch {
            print("❌ Share Extension: Failed to configure Amplify: \(error)")
        }
    }
    
    private func checkAuthStatus() async {
        do {
            // First check if we have tokens in keychain
            let tokens = getTokensFromKeychain()
            if let accessToken = tokens.accessToken, let idToken = tokens.idToken {
                // We have tokens, try to restore the session
                await restoreSessionWithTokens(accessToken: accessToken, idToken: idToken)
            } else {
                // No tokens, check if there's an existing session
                let session = try await Amplify.Auth.fetchAuthSession()
                if session.isSignedIn {
                    await getCurrentUser()
                } else {
                    isAuthenticated = false
                }
            }
        } catch {
            print("❌ Share Extension: Auth session check failed: \(error)")
            isAuthenticated = false
        }
    }
    
    private func getCurrentUser() async {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            
            // Get the user ID directly from the user object
            let userId = user.userId
            userDefaults?.set(userId, forKey: Config.userIdKey)
            isAuthenticated = true
            print("✅ Share Extension: User authenticated: \(userId)")
        } catch {
            print("❌ Share Extension: Failed to get user info: \(error)")
            errorMessage = "Failed to get user info: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }
    
    func getCurrentUserId() -> String? {
        return userDefaults?.string(forKey: Config.userIdKey)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Keychain Methods
    
    private func getTokensFromKeychain() -> (accessToken: String?, idToken: String?) {
        let keychain = Keychain(service: "com.wayne617.linksync", accessGroup: Config.appGroupIdentifier)
        
        do {
            let accessToken = try keychain.get("access_token")
            let idToken = try keychain.get("id_token")
            return (accessToken, idToken)
        } catch {
            print("❌ Share Extension: Failed to get tokens from keychain: \(error)")
            return (nil, nil)
        }
    }
    
    private func restoreSessionWithTokens(accessToken: String, idToken: String) async {
        // For now, we'll just check if we can get the current user
        // In a real implementation, you might need to restore the session differently
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            let userId = user.userId
            userDefaults?.set(userId, forKey: Config.userIdKey)
            isAuthenticated = true
            print("✅ Share Extension: Session restored with tokens, user: \(userId)")
        } catch {
            print("❌ Share Extension: Failed to restore session with tokens: \(error)")
            isAuthenticated = false
        }
    }
}

// Simple Keychain wrapper for sharing tokens between app and extension
class Keychain {
    private let service: String
    private let accessGroup: String?
    
    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    func get(_ key: String) throws -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
}

enum KeychainError: Error {
    case loadFailed(OSStatus)
    case invalidData
}
