// PaymentTermsSection.swift
// Component for displaying and managing payment terms in proposals

import SwiftUI
import CoreData

struct PaymentTermsSection: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditSheet = false
    
    // State for editing a specific term
    @State private var showingAddEditTermSheet = false
    @State private var editingTermID: UUID? = nil
    
    // Colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.1) : Color(UIColor.tertiarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    // Get payment terms as an array
    private var paymentTermsArray: [PaymentTerm] {
        let set = proposal.paymentTerms as? Set<PaymentTerm> ?? []
        return set.sorted {
            // Sort by percentage (higher first)
            $0.percentage > $1.percentage
        }
    }
    
    // Get payment methods from the serialized data
    private var paymentMethods: [String] {
        guard let data = proposal.paymentMethodsData,
              let methods = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return methods
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with Edit button
            HStack {
                Text("Payment Terms")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingEditSheet = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            // Payment terms content view
            paymentTermsContent
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                PaymentTermsEditView(proposal: proposal)
                    .navigationTitle("Edit Payment Terms")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingEditSheet = false
                        },
                        trailing: Button("Save") {
                            // Save changes
                            do {
                                try viewContext.save()
                            } catch {
                                print("Error saving payment terms: \(error)")
                            }
                            showingEditSheet = false
                        }
                    )
            }
        }
        .sheet(isPresented: $showingAddEditTermSheet) {
            NavigationView {
                PaymentTermEditView(
                    proposal: proposal,
                    termID: editingTermID
                )
                .navigationTitle(editingTermID == nil ? "Add Payment Term" : "Edit Payment Term")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddEditTermSheet = false
                    },
                    trailing: Button("Save") {
                        // Save changes
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error saving payment term: \(error)")
                        }
                        showingAddEditTermSheet = false
                    }
                )
            }
        }
    }
    
    // Payment terms content view
    private var paymentTermsContent: some View {
        VStack(spacing: 0) {
            // Terms table header
            HStack {
                Text("Terms")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Due Date")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 120, alignment: .trailing)
                
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 120, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color(UIColor.secondarySystemBackground))
            
            if paymentTermsArray.isEmpty {
                Text("No payment terms defined")
                    .foregroundColor(secondaryTextColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
            } else {
                // Payment terms rows
                ForEach(paymentTermsArray, id: \.id) { term in
                    PaymentTermRow(term: term)
                        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.systemBackground))
                    
                    Divider()
                        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                }
            }
            
            // Payment methods section
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment Methods:")
                    .font(.headline)
                    .padding(.top, 16)
                
                // Display available payment methods
                ForEach(paymentMethods, id: \.self) { method in
                    HStack(spacing: 10) {
                        Image(systemName: paymentMethodIcon(method))
                            .foregroundColor(.blue)
                        
                        Text(method)
                            .foregroundColor(primaryTextColor)
                    }
                    .padding(.vertical, 4)
                }
                
                // Show a placeholder if no payment methods are defined
                if paymentMethods.isEmpty {
                    Text("No payment methods specified")
                        .foregroundColor(secondaryTextColor)
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Helper function to get icon for payment method
    private func paymentMethodIcon(_ method: String) -> String {
        switch method.lowercased() {
        case "bank transfer", "wire transfer", "bank":
            return "building.columns.fill"
        case "credit card", "card":
            return "creditcard.fill"
        case "cash":
            return "banknote.fill"
        case "paypal":
            return "p.circle.fill"
        case "check", "cheque":
            return "doc.text.fill"
        default:
            return "euro.circle.fill" // Default financial icon
        }
    }
}

// Row component for a payment term
struct PaymentTermRow: View {
    let term: PaymentTerm
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(term.name ?? "Payment Term")
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                
                Text("\(Int(term.percentage))% of total")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(formattedDueDate)
                .font(.system(size: 14))
                .frame(width: 120, alignment: .trailing)
            
            Text(Formatters.formatEuro(term.amount))
                .font(.system(size: 16))
                .fontWeight(.medium)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
    
    // Formatted due date based on term type
    private var formattedDueDate: String {
        if let dueDate = term.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: dueDate)
        } else if term.dueDays > 0 {  // Changed from if let to direct comparison
            return "Net \(Int(term.dueDays)) days"
        } else if let dueCondition = term.dueCondition {
            return dueCondition
        } else {
            return "Not specified"
        }
    }
} // Add this closing brace here to complete the PaymentTermRow struct


// Edit view for payment terms
struct PaymentTermsEditView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.managedObjectContext) private var viewContext
    @State private var paymentMethods: [String] = ["Bank Transfer", "Credit Card", "Cash", "PayPal", "Check"]
    @State private var showingAddTermSheet = false
    @State private var editingTermID: UUID? = nil
    
    // Get payment terms as an array
    private var paymentTermsArray: [PaymentTerm] {
        let set = proposal.paymentTerms as? Set<PaymentTerm> ?? []
        return set.sorted {
            // Sort by percentage (higher first)
            $0.percentage > $1.percentage
        }
    }
    
    // Get current payment methods from the proposal
    private var currentMethods: [String] {
        guard let data = proposal.paymentMethodsData,
              let methods = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return methods
    }
    
    var body: some View {
        Form {
            Section(header: Text("PAYMENT TERMS")) {
                if paymentTermsArray.isEmpty {
                    Text("No payment terms defined yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(paymentTermsArray, id: \.id) { term in
                        Button(action: {
                            editingTermID = term.id
                            showingAddTermSheet = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(term.name ?? "Payment Term")
                                        .foregroundColor(.primary)
                                    
                                    Text("\(Int(term.percentage))% of total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(Formatters.formatEuro(term.amount))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .onDelete(perform: deletePaymentTerm)
                }
                
                Button(action: {
                    editingTermID = nil
                    showingAddTermSheet = true
                }) {
                    Label("Add Payment Term", systemImage: "plus")
                }
            }
            
            Section(header: Text("PAYMENT METHODS")) {
                ForEach(paymentMethods.indices, id: \.self) { index in
                    HStack {
                        Button(action: {
                            // Toggle payment method selection
                            var methods = currentMethods
                            if methods.contains(paymentMethods[index]) {
                                methods.removeAll { $0 == paymentMethods[index] }
                            } else {
                                methods.append(paymentMethods[index])
                            }
                            updatePaymentMethods(methods)
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .opacity(currentMethods.contains(paymentMethods[index]) ? 1.0 : 0.0)
                                
                                Text(paymentMethods[index])
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("TEMPLATES")) {
                Button(action: {
                    applyTemplate_5050Split()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("50/50 Split")
                                .foregroundColor(.primary)
                            
                            Text("Upfront 50%, Final 50%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: {
                    applyTemplate_Progressive()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progressive")
                                .foregroundColor(.primary)
                            
                            Text("20% / 30% / 50% split")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTermSheet) {
            NavigationView {
                PaymentTermEditView(
                    proposal: proposal,
                    termID: editingTermID
                )
                .navigationTitle(editingTermID == nil ? "Add Payment Term" : "Edit Payment Term")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddTermSheet = false
                    },
                    trailing: Button("Save") {
                        // Save changes to context
                        do {
                            try viewContext.save()
                            showingAddTermSheet = false
                        } catch {
                            print("Error saving payment term: \(error)")
                        }
                    }
                )
            }
        }
    }
    
    // Helper method to update payment methods
    private func updatePaymentMethods(_ methods: [String]) {
        if let data = try? JSONEncoder().encode(methods) {
            proposal.paymentMethodsData = data
            try? viewContext.save()
        }
    }
    
    private func deletePaymentTerm(at offsets: IndexSet) {
        // Convert IndexSet to actual PaymentTerm objects
        let termsToDelete = offsets.map { paymentTermsArray[$0] }
        
        // Delete each term
        for term in termsToDelete {
            viewContext.delete(term)
        }
        
        // Save changes
        do {
            try viewContext.save()
        } catch {
            print("Error deleting payment term: \(error)")
        }
    }
    
    // Template: 50/50 Split
    private func applyTemplate_5050Split() {
        // First delete existing terms
        for term in paymentTermsArray {
            viewContext.delete(term)
        }
        
        // Create first term - 50% advance
        let term1 = PaymentTerm(context: viewContext)
        term1.id = UUID()
        term1.name = "Advance Payment"
        term1.percentage = 50
        term1.amount = proposal.totalAmount * 0.5
        term1.dueCondition = "Upon signing"
        term1.proposal = proposal
        
        // Create second term - 50% final
        let term2 = PaymentTerm(context: viewContext)
        term2.id = UUID()
        term2.name = "Final Payment"
        term2.percentage = 50
        term2.amount = proposal.totalAmount * 0.5
        term2.dueDays = 30
        term2.proposal = proposal
        
        // Save changes
        do {
            try viewContext.save()
        } catch {
            print("Error creating payment terms: \(error)")
        }
    }
    
    // Template: Progressive
    private func applyTemplate_Progressive() {
        // First delete existing terms
        for term in paymentTermsArray {
            viewContext.delete(term)
        }
        
        // Create first term - 20% deposit
        let term1 = PaymentTerm(context: viewContext)
        term1.id = UUID()
        term1.name = "Deposit"
        term1.percentage = 20
        term1.amount = proposal.totalAmount * 0.2
        term1.dueCondition = "Upon signing"
        term1.proposal = proposal
        
        // Create second term - 30% progress
        let term2 = PaymentTerm(context: viewContext)
        term2.id = UUID()
        term2.name = "Progress Payment"
        term2.percentage = 30
        term2.amount = proposal.totalAmount * 0.3
        term2.dueCondition = "Upon delivery"
        term2.proposal = proposal
        
        // Create third term - 50% final
        let term3 = PaymentTerm(context: viewContext)
        term3.id = UUID()
        term3.name = "Final Payment"
        term3.percentage = 50
        term3.amount = proposal.totalAmount * 0.5
        term3.dueDays = 30
        term3.proposal = proposal
        
        // Save changes
        do {
            try viewContext.save()
        } catch {
            print("Error creating payment terms: \(error)")
        }
    }
}

// Individual payment term edit view
struct PaymentTermEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var proposal: Proposal
    
    // State properties for editing
    @State private var name: String = ""
    @State private var percentage: String = ""
    @State private var dueCondition: String = ""
    @State private var dueDays: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedDueType: DueType = .condition
    
    // UUID of the term to edit (nil if creating a new term)
    let termID: UUID?
    
    // The term being edited, if any
    private var term: PaymentTerm? {
        guard let termID = termID else { return nil }
        
        // Find the term with the given ID
        let set = proposal.paymentTerms as? Set<PaymentTerm> ?? []
        return set.first { $0.id == termID }
    }
    
    enum DueType: String, CaseIterable, Identifiable {
        case condition = "Condition"
        case days = "Days"
        case date = "Specific Date"
        
        var id: String { self.rawValue }
    }
    
    init(proposal: Proposal, termID: UUID?) {
        self.proposal = proposal
        self.termID = termID
        
        // Find the term if editing an existing one
        let existingTerm: PaymentTerm?
        if let termID = termID {
            let set = proposal.paymentTerms as? Set<PaymentTerm> ?? []
            existingTerm = set.first { $0.id == termID }
        } else {
            existingTerm = nil
        }
        
        // Initialize state from existing term or defaults
        _name = State(initialValue: existingTerm?.name ?? "")
        
        if let percentage = existingTerm?.percentage {
            _percentage = State(initialValue: "\(Int(percentage))")
        } else {
            _percentage = State(initialValue: "")
        }
        
        _dueCondition = State(initialValue: existingTerm?.dueCondition ?? "")
        
        if let dueDays = existingTerm?.dueDays {
            _dueDays = State(initialValue: "\(Int(dueDays))")
        } else {
            _dueDays = State(initialValue: "")
        }
        
        if let dueDate = existingTerm?.dueDate {
            _dueDate = State(initialValue: dueDate)
        } else {
            _dueDate = State(initialValue: Date())
        }
        
        // Determine due type
        if existingTerm?.dueDate != nil {
            _selectedDueType = State(initialValue: .date)
        } else if existingTerm?.dueDays != nil {
            _selectedDueType = State(initialValue: .days)
        } else {
            _selectedDueType = State(initialValue: .condition)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("TERM DETAILS")) {
                TextField("Name (e.g., Deposit, Final Payment)", text: $name)
                
                TextField("Percentage of Total", text: $percentage)
                    .keyboardType(.decimalPad)
                
                // Calculate amount preview
                if let percentValue = Double(percentage), percentValue > 0 {
                    let amount = proposal.totalAmount * (percentValue / 100)
                    Text("Amount: \(Formatters.formatEuro(amount))")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("DUE DATE")) {
                Picker("Due Date Type", selection: $selectedDueType) {
                    ForEach(DueType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Show different input based on selected due type
                switch selectedDueType {
                case .condition:
                    TextField("Due Condition (e.g., Upon signing)", text: $dueCondition)
                    
                case .days:
                    TextField("Days after invoice", text: $dueDays)
                        .keyboardType(.numberPad)
                    
                case .date:
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                }
            }
            
            Section(header: Text("PREVIEW")) {
                if !name.isEmpty && !percentage.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(name)
                            .font(.headline)
                        
                        HStack {
                            Text("\(percentage)% of total")
                            
                            Spacer()
                            
                            // Due date display based on type
                            Text(getDueDateText())
                                .foregroundColor(.secondary)
                        }
                        
                        if let previewPercentValue = Double(percentage), previewPercentValue > 0 {
                            let amount = proposal.totalAmount * (previewPercentValue / 100)
                            Text(Formatters.formatEuro(amount))
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                } else {
                    Text("Enter term details for preview")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Button(action: {
                saveChanges()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save Payment Term")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
            }
            .padding(.vertical)
            .disabled(!isFormValid)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !percentage.isEmpty &&
        (selectedDueType != .condition || !dueCondition.isEmpty) &&
        (selectedDueType != .days || !dueDays.isEmpty)
    }
    
    private func getDueDateText() -> String {
        switch selectedDueType {
        case .condition:
            return dueCondition.isEmpty ? "Upon agreement" : dueCondition
        case .days:
            if let days = Int(dueDays) {
                return "Net \(days) days"
            } else {
                return "Net 30 days"
            }
        case .date:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: dueDate)
        }
    }
    
    private func saveChanges() {
        guard !name.isEmpty && !percentage.isEmpty else { return }
        
        // Get percentage value
        guard let percentValue = Double(percentage) else { return }
        
        // Get existing term or create new one
        let paymentTerm: PaymentTerm
        
        if let existingTerm = term {
            paymentTerm = existingTerm
        } else {
            // Create new term
            paymentTerm = PaymentTerm(context: viewContext)
            paymentTerm.id = UUID()
            paymentTerm.proposal = proposal
        }
        
        // Set properties
        paymentTerm.name = name
        paymentTerm.percentage = percentValue
        paymentTerm.amount = proposal.totalAmount * (percentValue / 100)
        
        // Rather than setting to nil which can cause issues if the property isn't optional,
        // we'll just skip setting these properties unless they have a value
        switch selectedDueType {
        case .condition:
            paymentTerm.dueCondition = dueCondition
            // Remove other due date info if they exist
            paymentTerm.dueDays = 0
            paymentTerm.dueDate = nil
        case .days:
            if let days = Double(dueDays) {
                paymentTerm.dueDays = days
                // Remove other due date info if they exist
                paymentTerm.dueCondition = nil
                paymentTerm.dueDate = nil
            }
        case .date:
            paymentTerm.dueDate = dueDate
            // Remove other due date info if they exist
            paymentTerm.dueCondition = nil
            paymentTerm.dueDays = 0
        }
        
        // Save changes
        do {
            try viewContext.save()
        } catch {
            print("Error saving payment term: \(error)")
        }
    }
}
