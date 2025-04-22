//
//  ActivityDetailView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// ActivityDetailView.swift
// Detailed activity list with filtering
//

import SwiftUI

struct ActivityDetailView: View {
    @ObservedObject var proposal: Proposal
    @State private var showingAddComment = false
    @State private var commentText = ""
    @State private var selectedActivityType: String? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    let activityTypes = ["All", "Created", "Updated", "StatusChanged", "TaskAdded", "TaskCompleted", "CommentAdded"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterButton(title: "All", 
                                isSelected: selectedActivityType == nil,
                                action: { selectedActivityType = nil })
                    
                    Divider()
                        .frame(height: 24)
                    
                    ForEach(activityTypes.dropFirst(), id: \.self) { type in
                        FilterButton(title: formatActivityType(type),
                                    isSelected: selectedActivityType == type,
                                    action: { selectedActivityType = type })
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.2))
            
            if filteredActivities.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No activities found")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    if selectedActivityType != nil {
                        Text("Try selecting a different filter")
                            .foregroundColor(.gray)
                        
                        Button("Clear Filter") {
                            selectedActivityType = nil
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Activity list
                List {
                    ForEach(filteredActivities, id: \.self) { activity in
                        ActivityRowView(activity: activity)
                            .listRowBackground(Color.black.opacity(0.2))
                    }
                }
            }
        }
        .navigationTitle("Activity History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddComment = true }) {
                    Label("Add Comment", systemImage: "text.bubble.fill")
                }
            }
        }
        .alert("Add Comment", isPresented: $showingAddComment) {
            TextField("Comment", text: $commentText)
            
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !commentText.isEmpty {
                    addComment()
                }
            }
        }
    }
    
    private var filteredActivities: [Activity] {
        if let type = selectedActivityType {
            return proposal.activitiesArray.filter { $0.type == type }
        } else {
            return proposal.activitiesArray
        }
    }
    
    private func formatActivityType(_ type: String) -> String {
        switch type {
        case "StatusChanged": return "Status"
        case "TaskAdded": return "New Task"
        case "TaskCompleted": return "Completed"
        case "CommentAdded": return "Comment"
        default:
            return type
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