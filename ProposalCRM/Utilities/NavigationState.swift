//
//  NavigationState.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// NavigationState.swift
// Shared navigation state manager for the app

import SwiftUI

class NavigationState: ObservableObject {
    // Singleton instance
    static let shared = NavigationState()
    
    // Private initializer for singleton pattern
    private init() {}
    
    // Navigation state properties
    @Published var showSidebar: Bool = true
    @Published var selectedProposal: Proposal? = nil
    @Published var isNavigatingToDetail: Bool = false
}