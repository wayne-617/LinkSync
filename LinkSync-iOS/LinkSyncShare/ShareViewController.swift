//
//  ShareViewController.swift
//  LinkSyncShare
//
//  Created by Wayne on 10/22/25.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin

class ShareViewController: UIViewController {
    
    private let apiService = APIService.shared
    private let authManager = AuthManager.shared
    
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Configure Amplify and then process shared content
        Task {
            await authManager.configureAmplify()
            await processSharedContent()
        }
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        view.addSubview(spinner)
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Process Shared Content
    
    private func processSharedContent() async {
        // Show spinner
        await MainActor.run {
            spinner.startAnimating()
            statusLabel.text = "Checking authentication..."
        }
        
        // Wait for authentication check to complete
        while authManager.isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        // Check if user is authenticated
        guard authManager.isAuthenticated else {
            await MainActor.run { showErrorAndDismiss("User not authenticated. Please sign in to the main app first.") }
            return
        }
        
        // Extract shared content
        guard let content = await extractSharedContent() else {
            await MainActor.run { showErrorAndDismiss("No content to share") }
            return
        }
        
        // Get current user ID
        guard let userId = authManager.getCurrentUserId() else {
            await MainActor.run { showErrorAndDismiss("User not authenticated") }
            return
        }
        
        // Update status and call API
        await MainActor.run {
            statusLabel.text = "Sending..."
        }
        
        do {
            _ = try await apiService.uploadMessage(userId: userId, content: content)
            await MainActor.run { showSuccessAndDismiss() }
        } catch {
            await MainActor.run { showErrorAndDismiss("Failed to send: \(error.localizedDescription)") }
        }
    }
    
    private func extractSharedContent() async -> String? {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return nil
        }
        
        for item in inputItems {
            if let attachments = item.attachments {
                for attachment in attachments {
                    // 1️⃣ Try text first
                    if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        do {
                            if let content = try await attachment.loadItem(forTypeIdentifier: "public.text") as? String {
                                return content
                            }
                        } catch {
                            print("❌ Failed to load text content: \(error)")
                        }
                    }
                    
                    // 2️⃣ Try URL next
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
    
    private func showSuccessAndDismiss() {
        spinner.stopAnimating()
        statusLabel.text = "Sent to computer ✅"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func showErrorAndDismiss(_ message: String) {
        spinner.stopAnimating()
        statusLabel.text = "❌ \(message)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}