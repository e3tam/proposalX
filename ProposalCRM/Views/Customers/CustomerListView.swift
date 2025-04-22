// CustomerListView.swift
// Enhanced to properly pass the NavigationState to detail views

import SwiftUI
import CoreData

struct CustomerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Customer>
    
    @State private var searchText = ""
    @State private var showingCreateCustomer = false
    
    var body: some View {
        VStack {
            if customers.isEmpty {
                EmptyCustomersView(onCreateCustomer: { showingCreateCustomer = true })
            } else {
                // Customer list with search
                List {
                    ForEach(filteredCustomers, id: \.self) { customer in
                        NavigationLink(
                            destination:
                                CustomerDetailView(customer: customer)
                                    .environmentObject(navigationState)
                        ) {
                            CustomerListItem(customer: customer)
                        }
                    }
                    .onDelete(perform: deleteCustomers)
                }
                .listStyle(PlainListStyle())
            }
        }
        .searchable(text: $searchText, prompt: "Search Customers")
        .navigationTitle("Customers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateCustomer = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateCustomer) {
            NavigationView {
                CreateCustomerView()
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
    
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredCustomers[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting customer: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// Empty customers view
struct EmptyCustomersView: View {
    let onCreateCustomer: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
                .padding()
            
            Text("No Customers Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add your first customer to get started with proposals")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onCreateCustomer) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Customer")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 16)
        }
        .padding()
    }
}

// Customer list item
struct CustomerListItem: View {
    @ObservedObject var customer: Customer
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(customer.initials)
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            // Customer info
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.formattedName)
                    .font(.headline)
                
                if let email = customer.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let phone = customer.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Proposal count badge
            if customer.proposalsArray.count > 0 {
                Text("\(customer.proposalsArray.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

// Extension to get customer initials
extension Customer {
    var initials: String {
        guard let name = self.name, !name.isEmpty else {
            return "?"
        }
        
        let components = name.components(separatedBy: " ")
        let firstLetter = String(components.first?.prefix(1) ?? "")
        
        if components.count > 1, let lastComponent = components.last {
            let lastLetter = String(lastComponent.prefix(1))
            return "\(firstLetter)\(lastLetter)"
        }
        
        return firstLetter
    }
}
