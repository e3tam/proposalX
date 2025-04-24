// ProposalListView.swift
// Simplified with direct NavigationLinks for better sidebar selection

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
                emptyStateView
            } else {
                // DIRECT NAVIGATION LINKS - Each row is a NavigationLink
                List {
                    ForEach(filteredProposals, id: \.self) { proposal in
                        NavigationLink(
                            destination: ProposalDetailView(proposal: proposal)
                                .environmentObject(navigationState)
                        ) {
                            ProposalRowView(proposal: proposal)
                        }
                    }
                    .onDelete(perform: deleteProposals)
                }
                .listStyle(PlainListStyle())
                .id(UUID()) // Force refresh list when view appears
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
    
    // Empty state view for when there are no proposals
    private var emptyStateView: some View {
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
}

// MARK: - Helper Views

// ProposalRowView component
struct ProposalRowView: View {
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

// Date view helper
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

// Status view helper
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

// Task count view helper
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
