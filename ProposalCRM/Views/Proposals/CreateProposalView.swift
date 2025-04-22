//
//  CreateProposalView.swift
//  ProposalCRM
//
//  View for creating a new proposal for a customer
//

import SwiftUI
import CoreData

struct CreateProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    let customer: Customer
    
    // Proposal properties
    @State private var number = ""
    @State private var status = "Draft"
    @State private var creationDate = Date()
    @State private var notes = ""
    
    // Status options
    let statusOptions = ["Draft", "Pending", "Sent"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("PROPOSAL DETAILS")) {
                    // Customer information (non-editable)
                    HStack {
                        Text("Customer")
                            .fontWeight(.medium)
                        Spacer()
                        Text(customer.formattedName)
                            .foregroundColor(.secondary)
                    }
                    
                    // Proposal number - with auto-generation option
                    HStack {
                        TextField("Proposal Number", text: $number)
                        
                        Button(action: generateProposalNumber) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Status picker
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    // Creation date
                    DatePicker("Date", selection: $creationDate, displayedComponents: .date)
                }
                
                Section(header: Text("NOTES")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: createProposal) {
                        HStack {
                            Spacer()
                            Text("Create Proposal")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("New Proposal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if isFormValid {
                            createProposal()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                // Auto-generate proposal number when view appears
                if number.isEmpty {
                    generateProposalNumber()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !number.isEmpty
    }
    
    private func generateProposalNumber() {
        // Format: PROP-YYYYMMDD-XXX (XXX is sequential number)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        // Get count of proposals for this customer to generate sequential number
        let count = customer.proposalsArray.count + 1
        
        // Generate the proposal number
        number = "PROP-\(dateString)-\(String(format: "%03d", count))"
    }
    
    private func createProposal() {
        let proposal = Proposal(context: viewContext)
        proposal.id = UUID()
        proposal.number = number
        proposal.status = status
        proposal.creationDate = creationDate
        proposal.notes = notes.isEmpty ? nil : notes
        proposal.totalAmount = 0.0 // Initialize with zero
        proposal.customer = customer
        
        do {
            try viewContext.save()
            
            // Log activity
            ActivityLogger.logProposalCreated(
                proposal: proposal,
                context: viewContext
            )
            
            // Set default payment terms
            proposal.setDefaultPaymentTerms()
            try viewContext.save()
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error creating proposal: \(nsError), \(nsError.userInfo)")
            // Optionally show an error alert
        }
    }
}
