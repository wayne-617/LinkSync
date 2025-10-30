//
//  AmplifyConfig.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/29/25.
//
import Amplify
import AWSCognitoAuthPlugin

enum AmplifyConfig {
    private static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ Amplify configured successfully")
            isConfigured = true
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("already configured") || message.contains("cannot be added after") {
                print("⚠️ Amplify was already configured in this process")
                isConfigured = true
            } else {
                print("❌ Amplify configuration error: \(error)")
            }
        }
    }
}
