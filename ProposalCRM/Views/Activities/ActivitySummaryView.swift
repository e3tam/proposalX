//
//  ActivitySummaryView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// ActivitySummaryView.swift
// Summary timeline view of recent activities
//

import SwiftUI

struct ActivitySummaryView: View {
    @ObservedObject var proposal: Proposal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: ActivityDetailView(proposal: proposal)) {
                    Label("View All", systemImage: "list.bullet")
                        .foregroundColor(.blue)
                }
            }
            
            if proposal.activitiesArray.isEmpty {
                Text("No activity recorded yet")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
            } else {
                ZStack {
                    // Solid background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Only show the 5 most recent activities
                        ForEach(proposal.activitiesArray.prefix(5), id: \.self) { activity in
                            HStack(spacing: 12) {
                                // Timeline dot and line
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(activity.typeColor)
                                        .frame(width: 10, height: 10)
                                    
                                    if activity != proposal.activitiesArray.prefix(5).last {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(width: 2)
                                    }
                                }
                                .frame(height: 50)
                                
                                // Activity summary
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(activity.description ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text(activity.formattedTimestamp)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        if proposal.activitiesArray.count > 5 {
                            NavigationLink(destination: ActivityDetailView(proposal: proposal)) {
                                Text("View All Activity")
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal)
    }
}