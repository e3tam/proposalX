// AddCustomerView.swift
// Form for adding a new customer

import SwiftUI

struct AddCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    
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
            .navigationTitle("New Customer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCustomer() {
        let newCustomer = Customer(context: viewContext)
        newCustomer.id = UUID()
        newCustomer.name = name
        newCustomer.contactName = contactName
        newCustomer.email = email
        newCustomer.phone = phone
        newCustomer.address = address
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving customer: \(nsError), \(nsError.userInfo)")
        }
    }
}
