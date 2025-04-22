//
//  RecentActivityDashboard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// RecentActivityDashboard.swift
// Condensed activity feed for dashboard widgets
//

import SwiftUI

struct RecentActivityDashboard: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.timestamp, ascending: false)],
        animation: .default)
    private var recentActivities: FetchedResults<Activity>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: GlobalActivityView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if recentActivities.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
            } else {
                // Timeline visualization
                VStack(spacing: 0) {
                    ForEach(Array(recentActivities.prefix(4)), id: \.self) { activity in
                        HStack(spacing: 15) {
                            // Timeline dot and line
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: activity.typeIcon)
                                        .foregroundColor(activity.typeColor)
                                        .font(.system(size: 14))
                                }
                                
                                if activity != recentActivities.prefix(4).last {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 2, height: 30)
                                }
                            }
                            
                            // Activity details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.description ?? "")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                HStack {
                                    if let proposal = activity.proposal {
                                        Text(proposal.formattedNumber)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(activity.formattedTimestamp)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}