// ActivitySummarySection.swift
// Component for displaying recent activities in proposal detail view

import SwiftUI

struct ActivitySummarySection: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var proposal: Proposal
    @State private var showingAddComment = false
    @State private var commentText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: { showingAddComment = true }) {
                        Label("Add Comment", systemImage: "text.bubble")
                            .foregroundColor(.blue)
                    }
                    
                    NavigationLink(destination: ActivityDetailView(proposal: proposal)) {
                        Label("View All", systemImage: "list.bullet")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Activity log
            RecentActivityLogView(proposal: proposal)
        }
        .padding(.horizontal)
        .alert("Add Comment", isPresented: $showingAddComment) {
            TextField("Comment", text: $commentText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !commentText.isEmpty {
                    addComment()
                }
            }
        } message: {
            Text("Enter a comment for this proposal")
        }
    }
    
    private func addComment() {
        ActivityLogger.logCommentAdded(
            proposal: proposal,
            context: viewContext,
            comment: commentText
        )
        
        commentText = ""
    }
}

// Renamed from ActivityLogView to RecentActivityLogView
struct RecentActivityLogView: View {
    @ObservedObject var proposal: Proposal
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
            
            if proposal.activitiesArray.isEmpty {
                VStack {
                    Text("No activity yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(proposal.activitiesArray.prefix(3), id: \.self) { activity in
                        RecentActivityRow(activity: activity)
                        
                        if activity != proposal.activitiesArray.prefix(3).last {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                    
                    if proposal.activitiesArray.count > 3 {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        NavigationLink(destination: ActivityDetailView(proposal: proposal)) {
                            HStack {
                                Text("View all activity")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Renamed from ActivityRow to RecentActivityRow
struct RecentActivityRow: View {
    @ObservedObject var activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Activity icon
            Image(systemName: activity.typeIcon)
                .foregroundColor(activity.typeColor)
                .font(.system(size: 18))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.desc ?? "Unknown activity")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(activity.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let details = activity.details, !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
