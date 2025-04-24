// ProposalListView.swift
// Refactored to avoid type-checking issues with cleaner navigation

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
        ZStack {
            mainContent
            
            // Navigation destination as an overlay
            if navigationState.isNavigatingToDetail,
               let selectedProposal = navigationState.selectedProposal {
                NavigationLink(
                    destination: ProposalDetailView(proposal: selectedProposal)
                        .environmentObject(navigationState),
                    isActive: $navigationState.isNavigatingToDetail
                ) {
                    EmptyView()
                }
            }
        }
        .onAppear {
            // Clear navigation state when view appears
            navigationState.selectedProposal = nil
            navigationState.isNavigatingToDetail = false
        }
    }
    
    // Break down into smaller components
    private var mainContent: some View {
        VStack {
            statusFilterView
            
            if filteredProposals.isEmpty {
                emptyStateView
            } else {
                proposalListView
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
    
    private var statusFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterButton(
                    title: "All",
                    isSelected: selectedStatus == nil,
                    action: { selectedStatus = nil }
                )
                
                ForEach(statusOptions, id: \.self) { status in
                    FilterButton(
                        title: status,
                        isSelected: selectedStatus == status,
                        color: statusColor(for: status),
                        action: { selectedStatus = status }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var proposalListView: some View {
        List {
            ForEach(filteredProposals, id: \.self) { proposal in
                ProposalRowView(proposal: proposal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Simplified selection handling
                        selectProposal(proposal)
                    }
            }
            .onDelete(perform: deleteProposals)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func selectProposal(_ proposal: Proposal) {
        navigationState.selectedProposal = proposal
        navigationState.isNavigatingToDetail = true
    }
    
    private var filteredProposals: [Proposal] {
        proposals.filter { proposal in
            // Status filter
            if let status = selectedStatus, proposal.status != status {
                return false
            }
            
            // Search text filter
            if !searchText.isEmpty {
                let matchesNumber = proposal.number?.localizedCaseInsensitiveContains(searchText) ?? false
                let matchesCustomer = proposal.customer?.name?.localizedCaseInsensitiveContains(searchText) ?? false
                return matchesNumber || matchesCustomer
            }
            
            return true
        }
    }
    
    private func deleteProposals(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredProposals[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting proposal: \(error)")
            }
        }
    }
    
    private func statusColor(for status: String) -> Color {
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
    
    // MARK: - Empty State View
    
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
}

// MARK: - Supporting Views

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

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

struct DateView: View {
    let date: Date?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Updated")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
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
            if let tasks = proposal.tasks as? Set<Task>, !tasks.isEmpty {
                let pendingTasks = tasks.filter { $0.status != "Completed" }
                if !pendingTasks.isEmpty {
                    let hasOverdue = pendingTasks.contains {
                        if let dueDate = $0.dueDate {
                            return dueDate < Date() && $0.status != "Completed"
                        }
                        return false
                    }
                    
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
                }
            } else {
                Text("No tasks")
                    .font(.caption)
                    .foregroundColor(.clear) // Invisible, just for spacing
            }
        }
    }
}
