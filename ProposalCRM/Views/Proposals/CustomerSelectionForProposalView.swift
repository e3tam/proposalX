// CustomerSelectionForProposalView.swift
// Select a customer for a new proposal

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
    @State private var showingAddCustomer = false
    @State private var selectedCustomer: Customer?
    @State private var navigateToProposalForm = false
    
    var body: some View {
        NavigationView {
            VStack {
                if customers.isEmpty {
                    VStack(spacing: 20) {
                        Text("No Customers Available")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Add a customer first to create a proposal")
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingAddCustomer = true }) {
                            Label("Add Customer", systemImage: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredCustomers, id: \.self) { customer in
                            Button(action: {
                                selectedCustomer = customer
                                navigateToProposalForm = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(customer.formattedName)
                                            .font(.headline)
                                        Text(customer.email ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search Customers")
                }
            }
            .navigationTitle("Select Customer")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView()
            }
            .background(
                NavigationLink(
                    destination: CreateProposalView(customer: selectedCustomer),
                    isActive: $navigateToProposalForm,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    private var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                customer.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                customer.email?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
}
