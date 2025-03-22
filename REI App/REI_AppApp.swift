//
//  REI_AppApp.swift
//  REI App
//
//  Created by Durga Viswanadh on 22/03/25.
//

import SwiftUI

@main
struct REI_AppApp: App {
    @StateObject private var dataManager = DataManager()
    
    init() {
        // Request notification permissions
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
