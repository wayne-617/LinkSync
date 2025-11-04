import Foundation
import Amplify
import AWSCognitoAuthPlugin
import Combine
import os.log

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let logger = Logger(subsystem: "com.yourapp.linksync", category: "Auth")

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private init() {
        AmplifyConfiguration.configure()
        Task {
            //AmplifyConfiguration.configure()
            await checkAuthSession()
        }
    }
    
    func initializeAuth() async {
        // 1. Ensure Amplify is configured FIRST
        //AmplifyConfiguration.configure()
        
        // 2. Then, check the session.
        await checkAuthSession()
        
        // 3. Set up listeners or refresh logic here if needed.
    }

    // MARK: - Sign In
    func signIn(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            //try await Amplify.Auth.signIn(username: username, password: password)
            // Use global sign out to invalidate tokens on the server
            
            
            let result = try await Amplify.Auth.signIn(username: username, password: password)
            
            if result.isSignedIn {
                logger.info("✅ Sign-in successful")
                print("✅ Sign-in successful")
                isAuthenticated = true
                
                SharedAuthState.setAuthenticated(true)
                SharedAuthState.setAuthTimestamp(Date().timeIntervalSince1970)
                
                // Verify we can get the user
                if let userId = await getUserId() {
                    SharedAuthState.setUserId(userId)
                } else {
                    logger.warning("⚠️ Could not get userId immediately after sign in")
                    print("⚠️ Could not get userId immediately after sign in")
                }
                
                
                // Verify session
                let session = try await Amplify.Auth.fetchAuthSession()
            } else {
                logger.warning("⚠️ Sign-in not complete (MFA or confirmation required)")
                print("⚠️ Sign-in not complete (MFA or confirmation required)")
                isAuthenticated = false
            }
        } catch {
            logger.error("❌ Sign-in error: \(error.localizedDescription)")
            print("❌ Sign-in error: \(error)")
            errorMessage = "Failed to sign in. Please check your credentials."
            isAuthenticated = false
        }
        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        // Use global sign out to invalidate tokens on the server
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        let result = await Amplify.Auth.signOut(options: options)
        
        SharedAuthState.setAuthenticated(false)
        
        // Always set to not authenticated after sign out
        isAuthenticated = false
        isLoading = false
    }

    // MARK: - Check Current Session
    func checkAuthSession() async {
        isLoading = true
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            logger.info("🔍 Auth session check - isSignedIn: \(session.isSignedIn)")
            print("🔍 Auth session check - isSignedIn: \(session.isSignedIn)")
            if session.isSignedIn {
                isAuthenticated = true
                
                // Also verify we can get user
                if let userId = await getUserId() {
                    logger.info("✅ Verified userId: \(userId)")
                    print("✅ Verified userId: \(userId)")
                }
            } else {
                logger.info("🔒 No valid session")
                print("🔒 No valid session")
                isAuthenticated = false
            }
        } catch {
            logger.error("❌ Failed to fetch auth session: \(error.localizedDescription)")
            print("❌ Failed to fetch auth session: \(error)")
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // MARK: - Get User ID
    func getUserId() async -> String? {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            //logger.info("✅ Retrieved user ID: \(user.userId)")
            //print("✅ Retrieved user ID: \(user.userId)")
            return user.userId
        } catch {
            //logger.error("❌ Failed to get user ID: \(error.localizedDescription)")
            //print("❌ Failed to get user ID: \(error)")
            return nil
        }
    }
}
