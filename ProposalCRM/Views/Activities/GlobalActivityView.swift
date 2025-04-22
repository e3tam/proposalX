//
//  GlobalActivityView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// Complete fixed version of the filteredActivities property in GlobalActivityView.swift

import SwiftUI

struct GlobalActivityView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.timestamp, ascending: false)],
        animation: .default)
    private var activities: FetchedResults<Activity>
    
    @State private var selectedActivityType: String? = nil
    @State private var searchText = ""
    
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
            .background(Color(UIColor.secondarySystemBackground))
            
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
                        NavigationLink(destination: activityDestination(for: activity)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: activity.typeIcon)
                                        .foregroundColor(activity.typeColor)
                                    
                                    Text(activity.description ?? "")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(activity.formattedTimestamp)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let proposal = activity.proposal {
                                    Text("Proposal: \(proposal.formattedNumber)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search activities")
            }
        }
        .navigationTitle("Activity History")
    }
    
    // FIXED: Properly handle filtering of FetchedResults
    private var filteredActivities: [Activity] {
        // Start by converting FetchedResults to an Array
        var result = Array(activities)
        
        // Apply type filter if selected
        if let type = selectedActivityType {
            result = result.filter { $0.type == type }
        }
        
        // Apply search filter if entered
        if !searchText.isEmpty {
            result = result.filter { activity in
                // Check description match (safely handle optionals)
                let descMatch = (activity.desc?.localizedCaseInsensitiveContains(searchText)) ?? false
                
                // Check type match
                let typeMatch = activity.type?.localizedCaseInsensitiveContains(searchText) ?? false
                
                // Check proposal match
                let proposalMatch = activity.proposal?.number?.localizedCaseInsensitiveContains(searchText) ?? false
                
                // Check details match
                let detailsMatch = activity.details?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return descMatch || typeMatch || proposalMatch || detailsMatch
            }
        }
        
        return result
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
    
    private func activityDestination(for activity: Activity) -> some View {
        if let proposal = activity.proposal {
            return AnyView(ProposalDetailView(proposal: proposal))
        } else {
            return AnyView(EmptyView())
        }
    }
}
