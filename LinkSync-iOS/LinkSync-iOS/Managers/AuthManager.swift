//
//  AuthManager.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Security

// Simple Keychain wrapper for sharing tokens between app and extension
class Keychain {
    private let service: String
    private let accessGroup: String?
    
    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    func set(_ value: String, key: String) throws {
        let data = value.data(using: .utf8)!
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
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
    
    func remove(_ key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
}

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults(suiteName: Config.appGroupIdentifier)
    private var isConfigured = false
    
    init() {
        // Don't check auth status in init - wait for configureAmplify to be called
    }
    
    func configureAmplify() async {
        guard !isConfigured else { return }
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Amplify configured successfully")
            isConfigured = true
            
            // Now that Amplify is configured, check auth status
            await checkAuthStatus()
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
    
    func signIn(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First check if there's already a signed-in user
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                // Sign out the existing user first
                print("User already signed in, signing out first...")
                _ = try await Amplify.Auth.signOut()
            }
            
            let result = try await Amplify.Auth.signIn(username: username, password: password)
            
            if result.isSignedIn {
                await getCurrentUser()
            } else {
                errorMessage = "Login failed. Please check your credentials."
            }
        } catch {
            print("Sign in error: \(error)")
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            _ = try await Amplify.Auth.signOut()
            isAuthenticated = false
            userDefaults?.removeObject(forKey: Config.userIdKey)
            clearTokensFromKeychain()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func getCurrentUser() async {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            let session = try await Amplify.Auth.fetchAuthSession()
            
            // Get the user ID directly from the user object
            let userId = user.userId
            userDefaults?.set(userId, forKey: Config.userIdKey)
            
            // Save tokens to keychain for extension access
            if let cognitoSession = session as? AWSAuthCognitoSession {
                let tokensResult = await cognitoSession.getCognitoTokens()
                switch tokensResult {
                case .success(let tokens):
                    // Save tokens to keychain for share extension access
                    saveTokensToKeychain(accessToken: tokens.accessToken, idToken: tokens.idToken)
                    print("✅ Tokens saved to keychain for share extension")
                case .failure(let error):
                    print("❌ Failed to get tokens: \(error)")
                }
            }
            
            isAuthenticated = true
            print("User authenticated: \(userId)")
        } catch {
            print("Failed to get user info: \(error)")
            errorMessage = "Failed to get user info: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }
    
    private func checkAuthStatus() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                await getCurrentUser()
            } else {
                isAuthenticated = false
            }
        } catch {
            // User is not authenticated
            print("Auth session check failed: \(error)")
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
    
    private func saveTokensToKeychain(accessToken: String, idToken: String) {
        let keychain = Keychain(service: "com.wayne617.linksync", accessGroup: Config.appGroupIdentifier)
        
        do {
            try keychain.set(accessToken, key: "access_token")
            try keychain.set(idToken, key: "id_token")
            print("✅ Tokens saved to keychain")
        } catch {
            print("❌ Failed to save tokens to keychain: \(error)")
        }
    }
    
    private func getTokensFromKeychain() -> (accessToken: String?, idToken: String?) {
        let keychain = Keychain(service: "com.wayne617.linksync", accessGroup: Config.appGroupIdentifier)
        
        do {
            let accessToken = try keychain.get("access_token")
            let idToken = try keychain.get("id_token")
            return (accessToken, idToken)
        } catch {
            print("❌ Failed to get tokens from keychain: \(error)")
            return (nil, nil)
        }
    }
    
    private func clearTokensFromKeychain() {
        let keychain = Keychain(service: "com.wayne617.linksync", accessGroup: Config.appGroupIdentifier)
        
        do {
            try keychain.remove("access_token")
            try keychain.remove("id_token")
            print("✅ Tokens cleared from keychain")
        } catch {
            print("❌ Failed to clear tokens from keychain: \(error)")
        }
    }
}
