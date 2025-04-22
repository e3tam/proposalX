//
//  ProposalCRMApp.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


import SwiftUI

@main
struct ProposalCRMApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}