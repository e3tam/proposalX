// EditCustomerView.swift
// Form for editing an existing customer

import SwiftUI

struct EditCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var customer: Customer
    
    @State private var name: String
    @State private var contactName: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    
    init(customer: Customer) {
        self.customer = customer
        _name = State(initialValue: customer.name ?? "")
        _contactName = State(initialValue: customer.contactName ?? "")
        _email = State(initialValue: customer.email ?? "")
        _phone = State(initialValue: customer.phone ?? "")
        _address = State(initialValue: customer.address ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customer Information")) {
                    TextField("Company Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Contact Person", text: $contactName)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Address", text: $address)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("Edit Customer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateCustomer()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func updateCustomer() {
        customer.name = name
        customer.contactName = contactName
        customer.email = email
        customer.phone = phone
        customer.address = address
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating customer: \(nsError), \(nsError.userInfo)")
        }
    }
}
