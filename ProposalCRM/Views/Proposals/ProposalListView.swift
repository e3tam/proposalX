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
                            ProposalRowContent(proposal: proposal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteProposals)
                }
                // Use background navigation link that's triggered programmatically
                .background(
                    NavigationLink(
                        destination: Group {
                            if let proposal = navigationState.selectedProposal {
                                ProposalDetailView(proposal: proposal)
                                    .environmentObject(navigationState)
                            } else {
                                EmptyView()
                            }
                        },
                        isActive: $navigationState.isNavigatingToDetail
                    ) {
                        EmptyView()
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
}

// Proposal row content component for consistent display
struct ProposalRowContent: View {
    @ObservedObject var proposal: Proposal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(proposal.formattedNumber)
                    .font(.headline)
                
                Spacer()
                
                // Task indicator badge
                if proposal.pendingTasksCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(proposal.hasOverdueTasks ? .red : .orange)
                        
                        Text("\(proposal.pendingTasksCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(proposal.hasOverdueTasks ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                    )
                    .padding(.trailing, 4)
                }
                
                Text(proposal.formattedStatus)
                    .font(.caption)
                    .padding(4)
                    .background(statusColor(for: proposal.formattedStatus))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text(proposal.customerName)
                .font(.subheadline)
            
            HStack {
                Text(proposal.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Last activity timestamp
                if let lastActivity = proposal.lastActivity {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Updated \(lastActivity.timestamp ?? Date(), style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(proposal.formattedTotal)
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 4)
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
