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
    // Use regular property instead of @ObservedObject
    var proposal: Proposal
    @EnvironmentObject private var navigationState: NavigationState
    
    var body: some View {
        NavigationLink(
            destination: ProposalDetailView(proposal: proposal)
                    .environmentObject(navigationState)
        ) {
            proposalRowContent
        }
    }
    
    // Extract the row content to a computed property
    private var proposalRowContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row with number and status
            HStack {
                Text(proposal.number ?? "New Proposal")
                    .font(.headline)
                
                Spacer()
                
                // Task indicator - simplified
                taskIndicator
                
                // Status pill
                statusPill
            }
            
            // Customer name
            Text(proposal.customer?.name ?? "No Customer")
                .font(.subheadline)
            
            // Bottom row with date, update info, and amount
            HStack {
                // Date - using a simple Text view with the formatted date string
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Static spacers and dots for update info
                Spacer()
                    .frame(width: 4)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Spacer()
                    .frame(width: 4)
                
                Text("Updated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Amount
                amountLabel
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper property to format the date outside the view builder
    private var formattedDate: String {
        if let date = proposal.creationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        } else {
            return "Unknown Date"
        }
    }
    
    // Extract task indicator to a separate view
    private var taskIndicator: some View {
        let pendingTasks = proposal.tasksArray.filter { $0.status != "Completed" }
        let hasOverdue = pendingTasks.contains { $0.isOverdue }
        
        return Group {
            if !pendingTasks.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(hasOverdue ? .red : .orange)
                    
                    Text("\(pendingTasks.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(hasOverdue ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                )
                .padding(.trailing, 4)
            } else {
                EmptyView()
            }
        }
    }
    
    // Extract status pill to a separate view
    private var statusPill: some View {
        Text(proposal.status ?? "Draft")
            .font(.caption)
            .padding(4)
            .background(statusColor(for: proposal.status ?? "Draft"))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    // Extract amount label to a separate view
    private var amountLabel: some View {
        Text("€" + String(format: "%.2f", proposal.totalAmount))
            .font(.title3)
            .fontWeight(.bold)
    }
    
    // Status color helper function
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
