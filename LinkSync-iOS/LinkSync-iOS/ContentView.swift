//
//  ContentView.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoading {
                // Loading Screen - shown during initial auth check
                ZStack {
                    // Subtle background gradient
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.05), Color.accentColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Logo and Branding
                        VStack(spacing: 12) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("linksync")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.bottom, 20)
                        
                        // Loading indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .scaleEffect(1.2)
                    }
                }
            } else if authManager.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
