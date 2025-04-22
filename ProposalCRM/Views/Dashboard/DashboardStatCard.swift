//
//  DashboardStatCard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// DashboardStatCard.swift
// Reusable card component for dashboard statistics
//

import SwiftUI

struct DashboardStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon at the top
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            // Main value
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Subtitle
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}