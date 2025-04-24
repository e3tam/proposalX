import SwiftUI
import CoreData

struct PaymentTermFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // The proposal to which this payment term belongs
    @ObservedObject var proposal: Proposal
    
    // Optional payment term to edit (nil if creating a new one)
    var termID: UUID?
    
    // Closure to call when dismissing the view
    var onDismiss: (() -> Void)?
    
    // Form state
    @State private var name = ""
    @State private var percentage = ""
    @State private var dueType = DueType.condition
    @State private var dueCondition = ""
    @State private var dueDays = ""
    @State private var dueDate = Date()
    
    // Validation state
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // Types of due date options
    enum DueType: String, CaseIterable, Identifiable {
        case condition = "Condition"
        case days = "Days"
        case date = "Date"
        
        var id: String { self.rawValue }
    }
    
    // Computed property to get the term being edited
    private var termToEdit: PaymentTerm? {
        guard let termID = termID else { return nil }
        
        let request: NSFetchRequest<PaymentTerm> = PaymentTerm.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", termID as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching term: \(error)")
            return nil
        }
    }
    
    var body: some View {
        Form {
            // Basic information section
            Section(header: Text("PAYMENT TERM DETAILS")) {
                TextField("Name (e.g., Initial Payment)", text: $name)
                
                HStack {
                    Text("Percentage")
                    Spacer()
                    TextField("", text: $percentage)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("%")
                }
                
                // Amount preview
                if let percentValue = Double(percentage), percentValue > 0 {
                    let amount = proposal.totalAmount * (percentValue / 100)
                    Text("Amount: \(formatCurrency(amount))")
                        .foregroundColor(.secondary)
                }
            }
            
            // Due date information section
            Section(header: Text("DUE DATE")) {
                Picker("Type", selection: $dueType) {
                    ForEach(DueType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Show different input based on due type
                switch dueType {
                case .condition:
                    TextField("Due condition (e.g., Upon signing)", text: $dueCondition)
                    
                case .days:
                    HStack {
                        Text("Days after invoice")
                        Spacer()
                        TextField("", text: $dueDays)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                case .date:
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                }
            }
            
            // Preview section
            Section(header: Text("PREVIEW")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(name.isEmpty ? "Payment Term" : name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(percentage.isEmpty ? "0" : percentage)% of total")
                        
                        Spacer()
                        
                        // Display due date based on type
                        Text(getFormattedDueDate())
                            .foregroundColor(.secondary)
                    }
                    
                    if let percentValue = Double(percentage), percentValue > 0 {
                        let amount = proposal.totalAmount * (percentValue / 100)
                        Text(formatCurrency(amount))
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Save button
            Section {
                Button(action: saveTerm) {
                    Text("Save Payment Term")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
            }
        }
        .navigationTitle(termID == nil ? "Add Payment Term" : "Edit Payment Term")
        .onAppear(perform: loadTermData)
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Validation Error"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadTermData() {
        // If editing an existing term, load its data
        if let term = termToEdit {
            name = term.name ?? ""
            percentage = String(format: "%.0f", term.percentage)
            
            if let dueDate = term.dueDate {
                self.dueType = .date
                self.dueDate = dueDate
            } else if term.dueDays > 0 {
                self.dueType = .days
                self.dueDays = "\(Int(term.dueDays))"
            } else if let condition = term.dueCondition, !condition.isEmpty {
                self.dueType = .condition
                self.dueCondition = condition
            }
        }
    }
    
    private var isFormValid: Bool {
        // Name must not be empty
        guard !name.isEmpty else { return false }
        
        // Percentage must be a valid number between 1 and 100
        guard let percentValue = Double(percentage),
              percentValue > 0, percentValue <= 100 else {
            return false
        }
        
        // Based on due type, validate the corresponding field
        switch dueType {
        case .condition:
            return !dueCondition.isEmpty
        case .days:
            return !dueDays.isEmpty && Int(dueDays) != nil
        case .date:
            return true // Date picker always has a valid date
        }
    }
    
    private func getFormattedDueDate() -> String {
        switch dueType {
        case .condition:
            return dueCondition.isEmpty ? "Upon agreement" : dueCondition
        case .days:
            if let days = Int(dueDays) {
                return "Net \(days) days"
            } else {
                return "Specify days"
            }
        case .date:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: dueDate)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func saveTerm() {
        // Validate the form
        guard isFormValid else {
            validationMessage = "Please complete all required fields"
            showingValidationAlert = true
            return
        }
        
        // Parse percentage
        guard let percentageValue = Double(percentage) else {
            validationMessage = "Invalid percentage value"
            showingValidationAlert = true
            return
        }
        
        // Get or create the payment term
        let term: PaymentTerm
        if let existingTerm = termToEdit {
            term = existingTerm
        } else {
            term = PaymentTerm(context: viewContext)
            term.id = UUID()
            term.proposal = proposal
        }
        
        // Set common properties
        term.name = name
        term.percentage = percentageValue
        term.amount = proposal.totalAmount * (percentageValue / 100)
        
        // Set due date properties based on type
        switch dueType {
        case .condition:
            term.dueCondition = dueCondition
            term.dueDays = 0
            term.dueDate = nil
        case .days:
            if let days = Double(dueDays) {
                term.dueDays = days
                term.dueCondition = nil
                term.dueDate = nil
            }
        case .date:
            term.dueDate = dueDate
            term.dueCondition = nil
            term.dueDays = 0
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
            
            // Log activity
            ActivityLogger.logProposalUpdated(
                proposal: proposal,
                context: viewContext,
                fieldChanged: "Payment Terms"
            )
            
            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
            onDismiss?()
        } catch {
            validationMessage = "Error saving payment term: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }
}
