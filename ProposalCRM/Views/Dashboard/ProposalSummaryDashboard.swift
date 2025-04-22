//
//  ProposalSummaryDashboard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// ProposalSummaryDashboard.swift
// Condensed proposal summary for dashboard widgets
//

import SwiftUI

struct ProposalSummaryDashboard: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Proposal Overview")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: ProposalListView()) {
                    Text("View All")
                }
            }
            
            // Financial summary
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "$%.2f", activeProposalsValue))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", successRate))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(successRate >= 50 ? .green : .orange)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
            
            // Status breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Status Breakdown")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    StatusTag(status: "Draft", count: draftCount)
                    StatusTag(status: "Sent", count: sentCount)
                    StatusTag(status: "Won", count: wonCount)
                    StatusTag(status: "Lost", count: lostCount)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Computed properties
    private var activeProposalsValue: Double {
        return proposals
            .filter { $0.status != "Won" && $0.status != "Lost" }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    private var successRate: Double {
        let closedProposals = proposals.filter { 
            $0.status == "Won" || $0.status == "Lost" 
        }
        
        guard closedProposals.count > 0 else { return 0 }
        
        let wonCount = closedProposals.filter { $0.status == "Won" }.count
        return Double(wonCount) / Double(closedProposals.count) * 100
    }
    
    private var draftCount: Int {
        return proposals.filter { $0.status == "Draft" }.count
    }
    
    private var sentCount: Int {
        return proposals.filter { $0.status == "Sent" }.count
    }
    
    private var wonCount: Int {
        return proposals.filter { $0.status == "Won" }.count
    }
    
    private var lostCount: Int {
        return proposals.filter { $0.status == "Lost" }.count
    }
}

struct StatusTag: View {
    let status: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text("\(status): \(count)")
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    var statusColor: Color {
        switch status {
        case "Draft": return .gray
        case "Pending": return .orange
        case "Sent": return .blue
        case "Won": return .green
        case "Lost": return .red
        case "Expired": return .purple
        default: return .gray
        }
    }
}
