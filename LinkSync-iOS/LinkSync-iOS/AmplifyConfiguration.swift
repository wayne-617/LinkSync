//
//  AmplifyConfiguration.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/29/25.
//
import Amplify
import AWSCognitoAuthPlugin
import Foundation

enum AmplifyConfiguration {
    private static var isConfigured = false
    private static let lock = NSLock()
    
    static func configure() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isConfigured else {
            print("ℹ️ Amplify already configured")
            return
        }
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ Amplify configured successfully")
            isConfigured = true
        } catch {
            print("❌ Failed to configure Amplify: \(error)")
        }
    }
}
