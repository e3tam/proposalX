// CustomerDetailView.swift
// Shows details for a specific customer and their proposals

import SwiftUI

struct CustomerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    @State private var isEditing = false
    @State private var showingNewProposal = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Customer Info Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(customer.formattedName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { isEditing = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    Divider()
                    
                    if let contactName = customer.contactName, !contactName.isEmpty {
                        HStack {
                            Label(contactName, systemImage: "person")
                                .font(.headline)
                        }
                    }
                    
                    HStack {
                        Label(customer.email ?? "No Email", systemImage: "envelope")
                    }
                    
                    HStack {
                        Label(customer.phone ?? "No Phone", systemImage: "phone")
                    }
                    
                    HStack {
                        Label(customer.address ?? "No Address", systemImage: "location")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Proposals Section
                VStack(alignment: .leading, spacing: 10)
                {
                    HStack {
                        Text("Proposals")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingNewProposal = true }) {
                            Label("New Proposal", systemImage: "plus")
                        }
                    }
                    
                    if customer.proposalsArray.isEmpty {
                        Text("No proposals yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(customer.proposalsArray, id: \.self) { proposal in
                            NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(proposal.formattedNumber)
                                            .font(.headline)
                                        Text(proposal.formattedDate)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(proposal.formattedTotal)
                                            .font(.headline)
                                        Text(proposal.formattedStatus)
                                            .font(.caption)
                                            .padding(4)
                                            .background(statusColor(for: proposal.formattedStatus))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Customer Details")
        .sheet(isPresented: $isEditing) {
            EditCustomerView(customer: customer)
        }
        .sheet(isPresented: $showingNewProposal) {
            CreateProposalView(customer: customer)
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
