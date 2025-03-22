//
//  REI_AppApp.swift
//  REI App
//
//  Created by Durga Viswanadh on 22/03/25.
//

import SwiftUI

@main
struct REI_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
