// ProposalCRMApp.swift
// Updated to use NavigationState singleton

import SwiftUI

@main
struct ProposalCRMApp: App {
    let persistenceController = PersistenceController.shared
    
    // Use the shared singleton instance instead of creating a new one
    let navigationState = NavigationState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(navigationState) // Provide NavigationState to the view hierarchy
        }
    }
}
