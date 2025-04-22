// CreateProposalView.swift
// Create a new proposal for a selected customer

import SwiftUI

struct CreateProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var customer: Customer?
    
    @State private var proposalNumber = ""
    @State private var status = "Draft"
    @State private var notes = ""
    @State private var creationDate = Date()
    
    @State private var showingItemSelection = false
    @State private var showingEngineeringForm = false
    @State private var showingExpensesForm = false
    @State private var showingCustomTaxForm = false
    
    @State private var proposal: Proposal?
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    var body: some View {
        Form {
            Section(header: Text("Proposal Information")) {
                TextField("Proposal Number", text: $proposalNumber)
                
                Picker("Status", selection: $status) {
                    ForEach(statusOptions, id: \.self) { status in
                        Text(status).tag(status)
                    }
                }
                
                DatePicker("Date", selection: $creationDate, displayedComponents: .date)
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .onAppear {
            // Generate a proposal number if empty
            if proposalNumber.isEmpty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let dateString = dateFormatter.string(from: Date())
                proposalNumber = "PROP-\(dateString)-001"
            }
            
            // Create the proposal object
            createProposal()
        }
        .navigationTitle("Create Proposal")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProposal()
                }
                .disabled(proposalNumber.isEmpty)
            }
        }
    }
    
    private func createProposal() {
        let newProposal = Proposal(context: viewContext)
        newProposal.id = UUID()
        newProposal.number = proposalNumber
        newProposal.creationDate = creationDate
        newProposal.status = status
        newProposal.customer = customer
        newProposal.totalAmount = 0
        newProposal.notes = notes
        
        do {
            try viewContext.save()
            proposal = newProposal
            
            // Log proposal creation
            ActivityLogger.logProposalCreated(
                proposal: newProposal,
                context: viewContext
            )
        } catch {
            let nsError = error as NSError
            print("Error creating proposal: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func saveProposal() {
        if let createdProposal = proposal {
            createdProposal.number = proposalNumber
            createdProposal.creationDate = creationDate
            createdProposal.status = status
            createdProposal.notes = notes
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving proposal: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
