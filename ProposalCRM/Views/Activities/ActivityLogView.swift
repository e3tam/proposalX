//
//  ActivityLogView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// ActivityLogView.swift
// Display activity history for a proposal
//

import SwiftUI
import CoreData
struct ActivityLogView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            if proposal.activitiesArray.isEmpty {
                EmptyActivityView()
            } else {
                ForEach(proposal.activitiesArray.prefix(5), id: \.self) { activity in
                    ActivityRow(activity: activity)
                    
                    if activity != proposal.activitiesArray.prefix(5).last {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .padding(.vertical, 5)
    }
}

// Supporting view for when there are no activities
private struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No activity yet")
                .foregroundColor(.gray)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// View for a single activity row
struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Activity icon
            Image(systemName: activity.typeIcon)
                .font(.system(size: 18))
                .foregroundColor(activity.typeColor)
                .frame(width: 25, height: 25)
                .background(activity.typeColor.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 5) {
                // Activity description
                Text(activity.desc ?? "Unknown activity")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                // Activity details if available
                if let details = activity.details, !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                }
                
                // Timestamp
                Text(activity.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
    }
}
