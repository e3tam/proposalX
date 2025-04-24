// Simplified CustomerDetailView.swift
// Focuses only on proposal navigation, without redefining components

import SwiftUI
import CoreData

struct CustomerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    @EnvironmentObject private var navigationState: NavigationState
    
    @State private var showingEditCustomer = false
    @State private var showingCreateProposal = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Use your existing CustomerInfoCard component here
                // CustomerInfoCard(customer: customer)
                
                // Proposals section
                proposalsSection
            }
            .padding(.vertical)
        }
        .navigationTitle(customer.name ?? "Customer")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditCustomer = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditCustomer) {
            NavigationView {
                EditCustomerView(customer: customer)
            }
        }
        .sheet(isPresented: $showingCreateProposal) {
            CreateProposalView(customer: customer)
        }
    }
    
    // MARK: - Section Components
    
    private var proposalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            proposalsSectionHeader
            
            if customer.proposalsArray.isEmpty {
                emptyProposalsView
            } else {
                proposalsList
            }
        }
    }
    
    private var proposalsSectionHeader: some View {
        HStack {
            Text("Proposals")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                showingCreateProposal = true
            }) {
                Label("Add Proposal", systemImage: "plus")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyProposalsView: some View {
        Text("No proposals yet")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    private var proposalsList: some View {
        ForEach(customer.proposalsArray, id: \.self) { proposal in
            proposalNavigationLink(for: proposal)
        }
    }
    
    // MARK: - Helper Components
    
    private func proposalNavigationLink(for proposal: Proposal) -> some View {
        NavigationLink(
            destination:
                ProposalDetailView(proposal: proposal)
                    .environmentObject(navigationState)
        ) {
            // Simple inline proposal row - replace with your existing component if needed
            proposalRowContent(for: proposal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func proposalRowContent(for proposal: Proposal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(proposal.number ?? "New Proposal")
                    .font(.headline)
                
                Spacer()
                
                Text(proposal.status ?? "Draft")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: proposal.status ?? "Draft"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                if let date = proposal.creationDate {
                    Text(dateFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(currencyFormatter.string(from: NSNumber(value: proposal.totalAmount)) ?? "€0.00")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // Helper function for status colors
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
    
    // Formatters
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        return formatter
    }
}

// MARK: - Preview Provider
struct CustomerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let customer = Customer(context: context)
        customer.name = "Preview Customer"
        customer.email = "customer@example.com"
        customer.phone = "123-456-7890"
        
        return NavigationView {
            CustomerDetailView(customer: customer)
                .environmentObject(NavigationState.shared)
                .environment(\.managedObjectContext, context)
        }
    }
}
