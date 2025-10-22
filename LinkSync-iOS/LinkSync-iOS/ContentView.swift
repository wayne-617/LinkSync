//
//  ContentView.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isConfigured = false
    
    var body: some View {
        Group {
            if isConfigured {
                if authManager.isAuthenticated {
                    MainView() // no need to pass authManager
                } else {
                    LoginView() // no need to pass authManager
                }
            } else {
                // Show loading while configuring Amplify
                VStack {
                    ProgressView()
                    Text("Initializing...")
                        .padding(.top)
                }
            }
        }
        .environmentObject(authManager) // inject singleton into the environment
        .task {
            await authManager.configureAmplify()
            isConfigured = true
            print("ContentView: isConfigured = \(isConfigured), isAuthenticated = \(authManager.isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
}
