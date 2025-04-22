//
//  ProposalStatusChart.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// ProposalStatusChart.swift
// Chart component for visualizing proposal statuses
//

import SwiftUI
import Charts

struct ProposalStatusChart: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.status, ascending: true)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    var body: some View {
        Group {
            if proposals.isEmpty {
                Text("No proposals available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(proposalStatusCounts.keys.sorted(), id: \.self) { status in
                        BarMark(
                            x: .value("Status", status),
                            y: .value("Count", proposalStatusCounts[status] ?? 0)
                        )
                        .cornerRadius(8)
                        .foregroundStyle(by: .value("Status", status))
                    }
                }
                .chartForegroundStyleScale([
                    "Draft": Color.gray,
                    "Pending": Color.orange,
                    "Sent": Color.blue,
                    "Won": Color.green,
                    "Lost": Color.red,
                    "Expired": Color.purple
                ])
            }
        }
    }
    
    private var proposalStatusCounts: [String: Int] {
        var counts: [String: Int] = [
            "Draft": 0,
            "Pending": 0,
            "Sent": 0,
            "Won": 0,
            "Lost": 0,
            "Expired": 0
        ]
        
        proposals.forEach { proposal in
            if let status = proposal.status {
                counts[status, default: 0] += 1
            }
        }
        
        return counts
    }
}