//
//  LinkSync_iOSApp.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//

import SwiftUI

@main
struct LinkSync_iOSApp: App {
    @StateObject private var authManager = AuthManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
