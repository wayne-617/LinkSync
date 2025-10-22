# LinkSync iOS App

A SwiftUI app that allows users to authenticate with AWS Cognito and upload text or URLs to their connected computer through an AWS API Gateway endpoint. The app includes a share extension for sharing content from other iOS applications.

## Features

- **Authentication**: Login using AWS Cognito via AWS Amplify
- **Text/URL Upload**: Upload text or URLs to connected computer via API Gateway
- **Share Extension**: Share text and URLs directly from other iOS apps
- **Auto-logout**: Automatic logout when refresh tokens expire
- **App Group**: Shared data between main app and share extension

## Setup Instructions

### 1. Xcode Project Configuration

1. Open `LinkSync-iOS.xcodeproj` in Xcode
2. Add AWS Amplify dependencies:
   - Go to File → Add Package Dependencies
   - Add: `https://github.com/aws-amplify/amplify-swift`
   - Select "Amplify" and "AWSCognitoAuthPlugin" products

### 2. App Group Configuration

1. In Xcode, select the main app target
2. Go to Signing & Capabilities
3. Add "App Groups" capability
4. Add group: `group.com.wayne617.linksyncios`

5. Select the LinkSyncShare extension target
6. Repeat steps 2-4 to add the same app group

### 3. AWS Configuration

The app is already configured with the provided AWS Cognito User Pool:
- Pool ID: `us-east-1_aFaTx8fmX`
- App Client ID: `5r588udrvmq6lvlse8jgahs0tq`
- Region: `us-east-1`

### 4. Configuration Setup

1. **Copy Config Files:**
   ```bash
   cp LinkSync-iOS/Config.example.swift LinkSync-iOS/Config.swift
   cp LinkSyncShare/Config.example.swift LinkSyncShare/Config.swift
   ```

2. **Update Config.swift files** with your actual values:
   - API Gateway URL
   - App Group Identifier
   - Any other environment-specific settings

3. **API Configuration:**
   - Base URL: `https://9xjsa6aiql.execute-api.us-east-1.amazonaws.com/DEV`
   - Endpoint: `POST /messages`

## Project Structure

```
LinkSync-iOS/
├── LinkSync-iOS/                 # Main app
│   ├── ContentView.swift         # Root view with auth state
│   ├── Views/
│   │   ├── LoginView.swift       # Login screen with registration modal
│   │   └── MainView.swift        # Main screen with text input and upload
│   ├── Managers/
│   │   └── AuthManager.swift     # AWS Cognito authentication
│   ├── Services/
│   │   └── APIService.swift      # API Gateway communication
│   ├── Config.swift              # Configuration constants
│   └── amplifyconfiguration.json # AWS Amplify configuration
├── LinkSyncShare/                # Share extension
│   ├── ShareViewController.swift # Share extension controller
│   └── APIService.swift          # API service for extension
└── Package.swift                 # Swift Package Manager dependencies
```

## Usage

### Main App
1. Launch the app
2. Enter username and password
3. Tap "Login" to authenticate
4. Enter text or URL in the text area
5. Tap "Upload to Computer" to send to connected device
6. Use the profile icon to sign out

### Share Extension
1. In any app, tap the share button
2. Select "LinkSync" from the share sheet
3. The content will be automatically uploaded to your connected computer

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+

## Dependencies

- AWS Amplify Swift SDK
- AWS Cognito Auth Plugin
