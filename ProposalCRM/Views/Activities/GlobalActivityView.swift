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
            ActivityFilterBar(
                selectedType: $selectedActivityType,
                activityTypes: activityTypes,
                formatActivityType: formatActivityType
            )
            
            // Content based on filtered results
            if filteredActivities.isEmpty {
                EmptyActivityView(selectedActivityType: $selectedActivityType)
            } else {
                // Activity list
                ActivityListView(
                    activities: filteredActivities,
                    searchText: $searchText
                )
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
}

// MARK: - Helper Components

// Filter bar component
private struct ActivityFilterBar: View {
    @Binding var selectedType: String?
    let activityTypes: [String]
    let formatActivityType: (String) -> String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ActivityFilterButton(
                    title: "All",
                    isSelected: selectedType == nil,
                    action: { selectedType = nil }
                )
                
                Divider().frame(height: 24)
                
                ForEach(activityTypes.dropFirst(), id: \.self) { type in
                    ActivityFilterButton(
                        title: formatActivityType(type),
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

// Empty state view
private struct EmptyActivityView: View {
    @Binding var selectedActivityType: String?
    
    var body: some View {
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
    }
}

// Activity list view
private struct ActivityListView: View {
    let activities: [Activity]
    @Binding var searchText: String
    
    var body: some View {
        List {
            ForEach(activities, id: \.self) { activity in
                NavigationLink(destination: activityDestination(for: activity)) {
                    ActivityRowComponent(activity: activity)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search activities")
    }
    
    private func activityDestination(for activity: Activity) -> some View {
        Group {
            if let proposal = activity.proposal {
                ProposalDetailView(proposal: proposal)
            } else {
                Text("Activity details not available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Activity row component - made private to avoid name conflicts
private struct ActivityRowComponent: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: activity.typeIcon)
                    .foregroundColor(activity.typeColor)
                
                Text(activity.desc ?? "")
                    .font(.headline)
                
                Spacer()
                
                Text(activity.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let proposal = activity.proposal {
                Text("Proposal: \(proposal.number ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Filter button component - made private to avoid name conflicts
private struct ActivityFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}
