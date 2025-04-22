// EditProposalView.swift
// Form for editing an existing proposal with enhanced customer information

import SwiftUI

struct EditProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    @State private var proposalNumber: String
    @State private var status: String
    @State private var notes: String
    @State private var creationDate: Date
    @State private var showingCustomerSelection = false
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    init(proposal: Proposal) {
        self.proposal = proposal
        _proposalNumber = State(initialValue: proposal.number ?? "")
        _status = State(initialValue: proposal.status ?? "Draft")
        _notes = State(initialValue: proposal.notes ?? "")
        _creationDate = State(initialValue: proposal.creationDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Customer Information Section
                Section(header: Text("Customer")) {
                    CustomerInfoCard(customer: proposal.customer)
                    
                    Button(action: { showingCustomerSelection = true }) {
                        Label("Change Customer", systemImage: "person.crop.circle.fill")
                    }
                }
                
                // Proposal Information Section
                Section(header: Text("Proposal Details")) {
                    TextField("Proposal Number", text: $proposalNumber)
                    
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    
                    DatePicker("Date", selection: $creationDate, displayedComponents: .date)
                }
                
                // Notes Section
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // Financial Summary Section (read-only)
                Section(header: Text("Financial Summary")) {
                    HStack {
                        Text("Products Total")
                        Spacer()
                        Text(String(format: "%.2f", proposal.subtotalProducts))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Engineering Total")
                        Spacer()
                        Text(String(format: "%.2f", proposal.subtotalEngineering))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Expenses Total")
                        Spacer()
                        Text(String(format: "%.2f", proposal.subtotalExpenses))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Taxes Total")
                        Spacer()
                        Text(String(format: "%.2f", proposal.subtotalTaxes))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Amount")
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(format: "%.2f", proposal.totalAmount))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Edit Proposal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProposal()
                    }
                    .disabled(proposalNumber.isEmpty)
                }
            }
            .sheet(isPresented: $showingCustomerSelection) {
                CustomerSelectionView(selectedCustomer: Binding(
                    get: { proposal.customer },
                    set: { newCustomer in
                        if let customer = newCustomer {
                            proposal.customer = customer
                        }
                    }
                ))
            }
        }
    }
    
    private func saveProposal() {
        // Track if status changed
        let oldStatus = proposal.status ?? ""
        
        proposal.number = proposalNumber
        proposal.status = status
        proposal.creationDate = creationDate
        proposal.notes = notes
        
        do {
            try viewContext.save()
            
            // Log status change if applicable
            if oldStatus != status {
                ActivityLogger.logStatusChanged(
                    proposal: proposal,
                    context: viewContext,
                    oldStatus: oldStatus,
                    newStatus: status
                )
            } else {
                ActivityLogger.logProposalUpdated(
                    proposal: proposal,
                    context: viewContext,
                    fieldChanged: "proposal details"
                )
            }
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal: \(nsError), \(nsError.userInfo)")
        }
    }
}

// Customer Information Card Component
struct CustomerInfoCard: View {
    let customer: Customer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let customer = customer {
                // Company name
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text(customer.formattedName)
                        .font(.headline)
                }
                
                // Contact person
                if let contactName = customer.contactName, !contactName.isEmpty {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Text(contactName)
                            .font(.subheadline)
                    }
                }
                
                // Email
                if let email = customer.email, !email.isEmpty {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Phone
                if let phone = customer.phone, !phone.isEmpty {
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Text(phone)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Address
                if let address = customer.address, !address.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "location")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No customer selected")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// Customer Selection View for changing the customer
struct CustomerSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Customer>
    
    @Binding var selectedCustomer: Customer?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCustomers, id: \.self) { customer in
                    Button(action: {
                        selectedCustomer = customer
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(customer.formattedName)
                                    .font(.headline)
                                
                                if let contactName = customer.contactName, !contactName.isEmpty {
                                    Text(contactName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let email = customer.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedCustomer == customer {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Customers")
            .navigationTitle("Select Customer")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                customer.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                customer.contactName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                customer.email?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
}

// Preview
struct EditProposalView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let proposal = Proposal(context: context)
        proposal.number = "PROP-2023-001"
        proposal.status = "Draft"
        
        let customer = Customer(context: context)
        customer.name = "Acme Corporation"
        customer.contactName = "John Doe"
        customer.email = "john@acme.com"
        customer.phone = "(555) 123-4567"
        customer.address = "123 Main St, Anytown, USA"
        
        proposal.customer = customer
        
        return EditProposalView(proposal: proposal)
            .environment(\.managedObjectContext, context)
    }
}
