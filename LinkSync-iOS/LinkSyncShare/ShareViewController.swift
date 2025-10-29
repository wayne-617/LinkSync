//
//  ShareViewController.swift
//  LinkSyncShare
//
//  Corrected to handle Amplify configuration errors and improve error state UI.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin

class ShareViewController: UIViewController {
    
    private let apiService = APIService.shared
    private let userDefaults = UserDefaults(suiteName: Config.appGroupIdentifier)
    private let keychain = Keychain(service: "com.wayne617.linksync", accessGroup: Config.appGroupIdentifier)
    
    // UI Components
    private let containerView = UIView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let checkmarkLabel = UILabel()
    private let errorIconLabel = UILabel() // NEW: UI component for the 'X' icon
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task {
            await configureAmplify()
            await processSharedContent()
        }
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        // Container view with rounded corners
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Spinner
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .label
        statusLabel.text = "Initializing Share..."
        
        // Checkmark label (hidden initially)
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.font = UIFont.systemFont(ofSize: 48)
        checkmarkLabel.text = "✓"
        checkmarkLabel.textColor = .systemGreen
        checkmarkLabel.alpha = 0
        
        // Error icon label (NEW: hidden initially)
        errorIconLabel.translatesAutoresizingMaskIntoConstraints = false
        errorIconLabel.textAlignment = .center
        errorIconLabel.font = UIFont.systemFont(ofSize: 36) // EDITED: Reduced font size from 48 to 36
        errorIconLabel.text = "❌" // Using the X emoji for a clear failure signal
        errorIconLabel.textColor = .systemRed
        errorIconLabel.alpha = 0
        
        view.addSubview(containerView)
        containerView.addSubview(spinner)
        containerView.addSubview(statusLabel)
        containerView.addSubview(checkmarkLabel)
        containerView.addSubview(errorIconLabel) // Add the new error icon
        
        NSLayoutConstraint.activate([
            // Container centered
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 200),
            containerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Spinner position (same as the error icon position)
            spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            
            // Error icon position (aligned with the spinner)
            errorIconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            errorIconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            
            // Status label position below the icon/spinner area
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Checkmark centered
            checkmarkLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        spinner.startAnimating()
    }
    
    // MARK: - Amplify Configuration
    
    private func configureAmplify() async {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ Amplify configured in share extension")
        } catch {
            let errorDescription = error.localizedDescription.lowercased()
            
            // Safely ignore "already configured" errors
            if errorDescription.contains("already configured") || errorDescription.contains("cannot be added after") {	
                print("⚠️ Amplify was already configured in this process. Proceeding.")
            } else {
                print("❌ Failed to configure Amplify: \(error)")
                // If configuration fails for a real reason, show a fatal error
                await showError("Fatal configuration error.")
            }
        }
    }
    
    // MARK: - Process Shared Content
    
    private func processSharedContent() async {
        await MainActor.run {
            statusLabel.text = "Checking account status..."
        }
        
        // 1. Check for local user ID (App Group)
        guard let userId = userDefaults?.string(forKey: Config.userIdKey) else {
            await showError("Please sign in to the main app first")
            return
        }
        
        // 2. Validate session using Amplify
        await MainActor.run {
            statusLabel.text = "Validating session..."
        }
        
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            
            guard session.isSignedIn else {
                await showError("Session expired. Please sign in to the main app.")
                return
            }
            
            print("✅ User authenticated with valid session")
            
        } catch {
            print("❌ Auth session error: \(error)")
            await showError("Session check failed. Please sign in to the main app.")
            return
        }
        
        // 3. Extract content
        await MainActor.run {
            statusLabel.text = "Extracting content..."
        }
        
        guard let content = await extractSharedContent() else {
            await showError("No content to share")
            return
        }
        
        print("✅ Extracted content: \(content)")
        
        // 4. Upload content
        await MainActor.run {
            statusLabel.text = "Sending link..."
        }
        
        do {
            _ = try await apiService.uploadMessage(userId: userId, content: content)
            await showSuccess()
        } catch {
            print("❌ Upload error: \(error)")
            await showError("Upload failed. Try again later.")
        }
    }
    
    private func extractSharedContent() async -> String? {
        // ... (Extraction logic remains the same) ...
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return nil
        }
        
        for item in inputItems {
            if let attachments = item.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        do {
                            if let content = try await attachment.loadItem(forTypeIdentifier: "public.text") as? String {
                                return content
                            }
                        } catch {
                            print("❌ Failed to load text content: \(error)")
                        }
                    }
                    
                    if attachment.hasItemConformingToTypeIdentifier("public.url") {
                        do {
                            if let url = try await attachment.loadItem(forTypeIdentifier: "public.url") as? URL {
                                return url.absoluteString
                            }
                        } catch {
                            print("❌ Failed to load URL content: \(error)")
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - UI Feedback
    
    private func showSuccess() async {
        await MainActor.run {
            // Hide spinner and error icon
            spinner.stopAnimating()
            spinner.alpha = 0
            errorIconLabel.alpha = 0 // Ensure error icon is hidden
            statusLabel.alpha = 0
            
            // Show checkmark with animation
            UIView.animate(withDuration: 0.3) {
                self.checkmarkLabel.alpha = 1
                self.checkmarkLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.checkmarkLabel.transform = .identity
                }
            }
        }
        
        // Wait and dismiss
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func showError(_ message: String) async {
        await MainActor.run {
            // 1. Hide spinner and show error icon
            spinner.stopAnimating()
            spinner.alpha = 0
            checkmarkLabel.alpha = 0 // Ensure checkmark is hidden
            errorIconLabel.alpha = 1 // Show the 'X' icon
            
            // 2. Update status text
            statusLabel.text = message
            statusLabel.textColor = .systemRed
            statusLabel.alpha = 1
        }
        
        // Wait and dismiss
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
