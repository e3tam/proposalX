//
//  ProposalListItem.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// ProposalListItem.swift
// Component for displaying proposal items in lists with proper navigation

import SwiftUI

struct ProposalListItem: View {
    @ObservedObject var proposal: Proposal
    @EnvironmentObject private var navigationState: NavigationState
    
    var body: some View {
        NavigationLink(
            destination: 
                ProposalDetailView(proposal: proposal)
                    .environmentObject(navigationState)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(proposal.formattedNumber)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Task indicator badge
                    if proposal.pendingTasksCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(proposal.hasOverdueTasks ? .red : .orange)
                            
                            Text("\(proposal.pendingTasksCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(proposal.hasOverdueTasks ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                        .padding(.trailing, 4)
                    }
                    
                    Text(proposal.formattedStatus)
                        .font(.caption)
                        .padding(4)
                        .background(statusColor(for: proposal.formattedStatus))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text(proposal.customerName)
                    .font(.subheadline)
                
                HStack {
                    Text(proposal.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Last activity timestamp
                    if let lastActivity = proposal.lastActivity {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Updated \(lastActivity.timestamp ?? Date(), style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(proposal.formattedTotal)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft":
            return .gray
        case "Pending":
            return .orange
        case "Sent":
            return .blue
        case "Won":
            return .green
        case "Lost":
            return .red
        case "Expired":
            return .purple
        default:
            return .gray
        }
    }
}