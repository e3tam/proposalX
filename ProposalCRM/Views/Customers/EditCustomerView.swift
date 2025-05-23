//
//  EditCustomerView.swift
//  ProposalCRM
//
//  View for editing an existing customer
//

import SwiftUI
import CoreData

struct EditCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var customer: Customer
    
    // Customer properties
    @State private var name: String
    @State private var contactName: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    
    // Validation state
    @State private var showingValidationAlert = false
    
    // Initialize with customer data
    init(customer: Customer) {
        self.customer = customer
        
        // Initialize state properties with customer values
        _name = State(initialValue: customer.name ?? "")
        _contactName = State(initialValue: customer.contactName ?? "")
        _email = State(initialValue: customer.email ?? "")
        _phone = State(initialValue: customer.phone ?? "")
        _address = State(initialValue: customer.address ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("CUSTOMER INFORMATION")) {
                TextField("Company Name", text: $name)
                    .disableAutocorrection(true)
                
                TextField("Contact Person", text: $contactName)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("CONTACT DETAILS")) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                
                TextField("Address", text: $address)
                    .disableAutocorrection(true)
            }
            
            // Customer statistics
            if !customer.proposalsArray.isEmpty {
                Section(header: Text("STATISTICS")) {
                    HStack {
                        Text("Total Proposals")
                        Spacer()
                        Text("\(customer.proposalsArray.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    let activeProposals = customer.proposalsArray.filter {
                        $0.status == "Draft" || $0.status == "Pending" || $0.status == "Sent"
                    }
                    HStack {
                        Text("Active Proposals")
                        Spacer()
                        Text("\(activeProposals.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    let wonProposals = customer.proposalsArray.filter { $0.status == "Won" }
                    HStack {
                        Text("Won Proposals")
                        Spacer()
                        Text("\(wonProposals.count)")
                            .foregroundColor(.green)
                    }
                    
                    // Total value of proposals
                    let totalValue = customer.proposalsArray.reduce(0.0) { $0 + $1.totalAmount }
                    HStack {
                        Text("Total Value")
                        Spacer()
                        Text(Formatters.formatEuro(totalValue))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Customer")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if isFormValid {
                        saveChanges()
                    } else {
                        showingValidationAlert = true
                    }
                }
            }
        }
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Missing Information"),
                message: Text("Please enter at least the customer name."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty
    }
    
    private func saveChanges() {
        customer.name = name
        customer.contactName = contactName.isEmpty ? nil : contactName
        customer.email = email.isEmpty ? nil : email
        customer.phone = phone.isEmpty ? nil : phone
        customer.address = address.isEmpty ? nil : address
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating customer: \(nsError), \(nsError.userInfo)")
            // Optionally show an error alert
        }
    }
}
