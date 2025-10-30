//
//  LinkSync_iOSApp.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//
import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

@main
struct LinkSync_iOSApp: App {
    @StateObject private var authManager = AuthManager.shared

    init() {
        AmplifyConfiguration.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
