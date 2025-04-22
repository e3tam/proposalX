//
//  CustomerSelectionForProposalView.swift
//  ProposalCRM
//
//  View for selecting a customer when creating a new proposal
//

import SwiftUI
import CoreData

struct CustomerSelectionForProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Customer>
    
    @State private var searchText = ""
    @State private var selectedCustomer: Customer?
    @State private var showingCreateCustomer = false
    @State private var showingCreateProposal = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    
                    TextField("Search customers", text: $searchText)
                        .padding(8)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Customer list
                if filteredCustomers.isEmpty {
                    VStack(spacing: 20) {
                        if customers.isEmpty {
                            Text("No Customers Yet")
                                .font(.title)
                                .foregroundColor(.secondary)
                            
                            Text("Create your first customer to get started")
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingCreateCustomer = true }) {
                                Label("Create Customer", systemImage: "plus")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        } else {
                            Text("No matching customers")
                                .font(.title)
                                .foregroundColor(.secondary)
                            
                            Text("Try changing your search criteria")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else {
                    List(filteredCustomers, id: \.self) { customer in
                        Button(action: {
                            selectedCustomer = customer
                            // Only show the create proposal sheet when a customer is selected
                            showingCreateProposal = true
                        }) {
                            CustomerSelectionRow(customer: customer, isSelected: selectedCustomer == customer)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Create new customer button
                if !customers.isEmpty {
                    Button(action: { showingCreateCustomer = true }) {
                        Label("Create New Customer", systemImage: "plus")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            // FIX: Sheet creation uses optional binding to safely unwrap the selectedCustomer
            .sheet(isPresented: $showingCreateProposal) {
                if let customer = selectedCustomer {
                    CreateProposalView(customer: customer)
                } else {
                    // Fallback view in case no customer is selected - unlikely to happen
                    // since we only set showingCreateProposal when a customer is selected
                    VStack {
                        Text("No customer selected")
                            .font(.headline)
                        
                        Button("Close") {
                            showingCreateProposal = false
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingCreateCustomer) {
                NavigationView {
                    CreateCustomerView()
                }
            }
        }
    }
    
    private var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                let name = customer.name ?? ""
                let email = customer.email ?? ""
                let phone = customer.phone ?? ""
                
                return name.localizedCaseInsensitiveContains(searchText) ||
                       email.localizedCaseInsensitiveContains(searchText) ||
                       phone.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// Customer selection row component
struct CustomerSelectionRow: View {
    let customer: Customer
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.formattedName)
                    .font(.headline)
                
                if let email = customer.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let phone = customer.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
}
