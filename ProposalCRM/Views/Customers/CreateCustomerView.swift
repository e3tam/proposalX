//
//  CreateCustomerView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


//
//  CreateCustomerView.swift
//  ProposalCRM
//
//  View for creating a new customer
//

import SwiftUI
import CoreData

struct CreateCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // Customer properties
    @State private var name = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    
    // Validation state
    @State private var showingValidationAlert = false
    
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
            
            Section {
                Button(action: saveCustomer) {
                    HStack {
                        Spacer()
                        Text("Create Customer")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isFormValid)
            }
        }
        .navigationTitle("New Customer")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if isFormValid {
                        saveCustomer()
                    } else {
                        showingValidationAlert = true
                    }
                }
            }
        }
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Missing Information"),
                message: Text("Please enter at least the customer name to create a customer."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty
    }
    
    private func saveCustomer() {
        let customer = Customer(context: viewContext)
        customer.id = UUID()
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
            print("Error creating customer: \(nsError), \(nsError.userInfo)")
            // Optionally show an error alert
        }
    }
}

struct CreateCustomerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateCustomerView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}