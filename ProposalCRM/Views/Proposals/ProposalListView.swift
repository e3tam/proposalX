// ProposalListView.swift
// Fixed to use shared NavigationState

import SwiftUI
import CoreData

struct ProposalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    @State private var searchText = ""
    @State private var showingCreateProposal = false
    @State private var selectedStatus: String? = nil
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    var body: some View {
        VStack {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: { selectedStatus = nil }) {
                        Text("All")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedStatus == nil ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedStatus == nil ? .white : .primary)
                            .cornerRadius(20)
                    }
                    
                    ForEach(statusOptions, id: \.self) { status in
                        Button(action: { selectedStatus = status }) {
                            Text(status)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedStatus == status ? statusColor(for: status) : Color.gray.opacity(0.2))
                                .foregroundColor(selectedStatus == status ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            if filteredProposals.isEmpty {
                VStack(spacing: 20) {
                    if proposals.isEmpty {
                        Text("No Proposals Yet")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Create your first proposal to get started")
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingCreateProposal = true }) {
                            Label("Create Proposal", systemImage: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Text("No matching proposals")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Try changing your search or filter")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                // Fixed navigation approach
                List {
                    ForEach(filteredProposals, id: \.self) { proposal in
                        Button(action: {
                            // Set the selected proposal and trigger navigation via the shared state
                            navigationState.selectedProposal = proposal
                            navigationState.isNavigatingToDetail = true
                            
                            // Hide the sidebar when navigating to details
                            navigationState.showSidebar = false
                        }) {
                            ProposalRowView(proposal: proposal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteProposals)
                }
                // Use background navigation link that's triggered programmatically
                .background(
                    Group {
                        if let proposal = navigationState.selectedProposal {
                            NavigationLink(
                                destination: ProposalDetailView(proposal: proposal)
                                    .environmentObject(navigationState),
                                isActive: $navigationState.isNavigatingToDetail
                            ) {
                                EmptyView()
                            }
                        } else {
                            EmptyView()
                        }
                    }
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search Proposals")
        .navigationTitle("Proposals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateProposal = true }) {
                    Label("Create", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateProposal) {
            CustomerSelectionForProposalView()
                .environmentObject(navigationState)
        }
    }
    
    private var filteredProposals: [Proposal] {
        // Filter the proposals based on search text and selected status
        let filtered = proposals.filter { proposal in
            // Apply status filter if selected
            if let status = selectedStatus, proposal.status != status {
                return false
            }
            
            // Apply search text filter if entered
            if !searchText.isEmpty {
                let matchesNumber = proposal.number?.localizedCaseInsensitiveContains(searchText) ?? false
                let matchesCustomer = proposal.customer?.name?.localizedCaseInsensitiveContains(searchText) ?? false
                
                if !matchesNumber && !matchesCustomer {
                    return false
                }
            }
            
            return true
        }
        
        // Return the filtered results as an array
        return Array(filtered)
    }
    
    private func deleteProposals(offsets: IndexSet) {
        withAnimation {
            // Convert IndexSet to indices in the filtered array
            offsets.map { filteredProposals[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting proposal: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft":
            return .gray
        case "Pending":
            return .orange
        case "Sent":
            return .blue
        case "Won":
            return .green
        case "Lost":
            return .red
        case "Expired":
            return .purple
        default:
            return .gray
        }
    }
    
    // Helper function to format a relative time string
    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate the difference components
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth, .month], from: date, to: now)
        
        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let week = components.weekOfMonth, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "just now"
        }
    }
}

// Renamed from ProposalRowContent to ProposalRowView to avoid conflicts
struct ProposalRowView: View {
    // Changed from @ObservedObject to regular property
    var proposal: Proposal
    
    var body: some View {
        HStack {
            // Left column - proposal info
            VStack(alignment: .leading, spacing: 6) {
                Text(proposal.number ?? "New Proposal")
                    .font(.headline)
                
                Text(proposal.customer?.name ?? "No Customer")
                    .font(.subheadline)
                
                DateView(date: proposal.creationDate)
            }
            
            Spacer()
            
            // Right column - status and amount
            VStack(alignment: .trailing, spacing: 6) {
                StatusView(status: proposal.status ?? "Draft")
                
                TaskCountView(proposal: proposal)
                
                Text("€" + String(format: "%.2f", proposal.totalAmount))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 4)
    }
}

// Helper views to break down the complex UI
struct DateView: View {
    let date: Date?
    
    var body: some View {
        HStack(spacing: 4) {
            // Date text
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Dot separator
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Update indicator
            Text("Updated")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Format the date outside the view builder
    private var formattedDate: String {
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        } else {
            return "Unknown Date"
        }
    }
}

struct StatusView: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
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

struct TaskCountView: View {
    let proposal: Proposal
    
    var body: some View {
        Group {
            let pendingTasks = proposal.tasksArray.filter { $0.status != "Completed" }
            if !pendingTasks.isEmpty {
                let hasOverdue = pendingTasks.contains { $0.isOverdue }
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(hasOverdue ? .red : .orange)
                    
                    Text("\(pendingTasks.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(hasOverdue ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                )
            } else {
                Text("No tasks")
                    .font(.caption)
                    .foregroundColor(.clear) // Invisible, just for spacing
            }
        }
    }
}
