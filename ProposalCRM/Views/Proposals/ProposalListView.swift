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
    @State private var isNavigating = false
    @State private var selectedProposal: Proposal?
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    var body: some View {
        VStack {
            statusFilterView
            
            if filteredProposals.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredProposals, id: \.self) { proposal in
                        // Use a Button instead of NavigationLink for more control
                        Button(action: {
                            selectProposal(proposal)
                        }) {
                            ProposalRowView(proposal: proposal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteProposals)
                }
                .listStyle(PlainListStyle())
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
        // Use background navigation link that's activated programmatically
        .background(
            NavigationLink(
                destination: Group {
                    if let proposal = selectedProposal {
                        ProposalDetailView(proposal: proposal)
                            .environmentObject(navigationState)
                    } else {
                        Text("Loading...")
                    }
                },
                isActive: $isNavigating
            ) {
                EmptyView()
            }
        )
        // Listen for "go back" signals from detail view
        .onChange(of: navigationState.shouldGoBack) { goBack in
            if goBack {
                isNavigating = false
                navigationState.shouldGoBack = false
            }
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
    
    // Safe proposal selection with delay to prevent UI hang
    private func selectProposal(_ proposal: Proposal) {
        // Store only the proposal ID or objectID
        selectedProposal = proposal
        
        // Add a slight delay to allow UI to complete any pending updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNavigating = true
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

// The supporting structs remain the same as before
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

// Keep other supporting views unchanged
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
