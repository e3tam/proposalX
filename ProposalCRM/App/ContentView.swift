//
//  ContentView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = "Dashboard"
    
    var body: some View {
        ZStack {
            // Custom segmented control for tab selection
            VStack(spacing: 0) {
                // Tab bar at top
                HStack(spacing: 0) {
                    TabButton(title: "Customers", icon: "person.3", selected: $selectedTab)
                    TabButton(title: "Products", icon: "cube.box", selected: $selectedTab)
                    TabButton(title: "Proposals", icon: "doc.text", selected: $selectedTab)
                    TabButton(title: "Tasks", icon: "checklist", selected: $selectedTab)
                    TabButton(title: "Dashboard", icon: "chart.bar", selected: $selectedTab)
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray6))
                
                // Content view based on selected tab
                if selectedTab == "Dashboard" {
                    // Show dashboard with no navigation view or sidebars
                    EnhancedDashboardView()
                        .transition(.opacity)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    // Use navigation view for other tabs
                    ZStack {
                        if selectedTab == "Customers" {
                            NavigationView { CustomerListView() }
                                .transition(.opacity)
                        } else if selectedTab == "Products" {
                            NavigationView { CustomProductListView() }
                                .transition(.opacity)
                        } else if selectedTab == "Proposals" {
                            NavigationView { ProposalListView() }
                                .transition(.opacity)
                        } else if selectedTab == "Tasks" {
                            NavigationView { TaskListView() }
                                .transition(.opacity)
                        }
                    }
                    .navigationViewStyle(DoubleColumnNavigationViewStyle())
                }
            }
        }
    }
}


// Enhanced ProposalListView to display task indicators
struct ProposalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
                List {
                    ForEach(filteredProposals, id: \.self) { proposal in
                        NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(proposal.formattedNumber)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Task indicator badge
                                    TaskIndicatorBadge(proposal: proposal)
                                    
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
                    }
                    .onDelete(perform: deleteProposals)
                }
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

// Tab Button Component
struct TabButton: View {
    let title: String
    let icon: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: {
            withAnimation {
                selected = title
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selected == title ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selected == title ?
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .padding(.horizontal, 8) :
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .padding(.horizontal, 8)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
