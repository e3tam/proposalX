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
                VStack(alignment: .leading, spacing: 10) {
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
                    
                    // Display proposals or empty state
                    if customer.proposalsArray.isEmpty {
                        // Use your existing empty proposals component or just a placeholder
                        Text("No proposals yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Key part: List of proposals with proper navigation
                        ForEach(customer.proposalsArray, id: \.self) { proposal in
                            NavigationLink(
                                destination:
                                    ProposalDetailView(proposal: proposal)
                                        .environmentObject(navigationState)
                            ) {
                                // Use your existing proposal row component or create a simple one
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(proposal.formattedNumber)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text(proposal.formattedStatus)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(statusColor(for: proposal.formattedStatus))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    
                                    HStack {
                                        Text(proposal.formattedDate)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(proposal.formattedTotal)
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
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(customer.formattedName)
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
}
