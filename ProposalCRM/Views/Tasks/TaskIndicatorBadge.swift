//
//  TaskIndicatorBadge.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// TaskIndicatorBadge.swift
// Task indicator badge for ProposalListView
// TaskIndicatorBadge.swift
// Task indicator badge for ProposalListView

import SwiftUI

struct TaskIndicatorBadge: View {
    @ObservedObject var proposal: Proposal
    
    var body: some View {
        HStack(spacing: 4) {
            if proposal.pendingTasksCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "checklist")
                        .font(.caption)
                    
                    Text("\(proposal.pendingTasksCount)")
                        .font(.caption)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(proposal.hasOverdueTasks ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
            
            if let lastActivity = proposal.lastActivity,
                Date().timeIntervalSince(lastActivity.timestamp ?? Date()) < 86400 { // Last 24 hours
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}
