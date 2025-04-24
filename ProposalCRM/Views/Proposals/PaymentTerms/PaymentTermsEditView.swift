import SwiftUI
import CoreData

struct PaymentTermsEditView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    // State for sheet presentation
    @State private var showingAddTerm = false
    @State private var showingTemplates = false
    @State private var editingTermID: UUID? = nil
    
    // Payment methods state
    @State private var paymentMethods: [String] = []
    @State private var selectedPaymentMethods: Set<String> = []
    
    // UI refresh trigger
    @State private var refreshTrigger = UUID()
    
    // Helper function to get month order from a term name
    private func getMonthOrder(_ term: PaymentTerm) -> Int {
        guard let name = term.name?.lowercased() else { return Int.max }
        
        if name.contains("first") {
            return 1
        } else if name.contains("second") {
            return 2
        } else if name.contains("third") {
            return 3
        } else if name.contains("fourth") || name.contains("final") {
            return 4
        }
        
        return Int.max // Unknown month order
    }
    
    // Get payment terms as an array - with improved sorting for monthly installments
    private var paymentTermsArray: [PaymentTerm] {
        if let terms = proposal.paymentTerms as? Set<PaymentTerm> {
            return terms.sorted { term1, term2 in
                // Special handling for monthly installments
                let month1 = getMonthOrder(term1)
                let month2 = getMonthOrder(term2)
                
                // If both terms have month ordering, use that
                if month1 != Int.max && month2 != Int.max {
                    return month1 < month2
                }
                
                // Otherwise sort by due days
                if term1.dueDays != term2.dueDays {
                    return term1.dueDays < term2.dueDays
                }
                
                // Last resort: sort by percentage (higher first)
                return term1.percentage > term2.percentage
            }
        }
        
        // Fallback to a direct fetch if relationship is inaccessible
        let fetchRequest: NSFetchRequest<PaymentTerm> = PaymentTerm.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "proposal == %@", proposal)
        
        do {
            let terms = try viewContext.fetch(fetchRequest)
            // Apply the same sorting logic
            return terms.sorted { term1, term2 in
                let month1 = getMonthOrder(term1)
                let month2 = getMonthOrder(term2)
                
                if month1 != Int.max && month2 != Int.max {
                    return month1 < month2
                }
                
                if term1.dueDays != term2.dueDays {
                    return term1.dueDays < term2.dueDays
                }
                
                return term1.percentage > term2.percentage
            }
        } catch {
            print("Error fetching payment terms: \(error)")
            return []
        }
    }
    
    // Helper function to get a formatted description for a term
    private func getFormattedDescription(_ term: PaymentTerm) -> String {
        if let description = term.descriptionText, !description.isEmpty {
            return description
        }
        
        let percentage = Int(term.percentage)
        
        if let name = term.name?.lowercased() {
            if name.contains("first") {
                return "\(percentage)% first installment"
            } else if name.contains("second") {
                return "\(percentage)% second installment"
            } else if name.contains("third") {
                return "\(percentage)% third installment"
            } else if name.contains("initial") || name.contains("advance") || name.contains("deposit") {
                return "\(percentage)% pre-payment"
            } else if name.contains("delivery") || name.contains("progress") {
                return "\(percentage)% after delivery"
            } else if name.contains("final") || name.contains("complete") {
                return "\(percentage)% upon completion"
            }
        }
        
        return "\(percentage)% payment"
    }
    
    // Helper function to format the due date
    private func getFormattedDueDate(_ term: PaymentTerm) -> String {
        if let dueDate = term.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: dueDate)
        } else if term.dueDays > 0 {
            return "Net \(Int(term.dueDays)) days"
        } else if let condition = term.dueCondition, !condition.isEmpty {
            return condition
        }
        return "Due date not specified"
    }
    
    // Get total percentage for validation
    private var totalPercentage: Double {
        return paymentTermsArray.reduce(0.0) { $0 + $1.percentage }
    }
    
    var body: some View {
        Form {
            // Payment Schedule Summary Section
            if !paymentTermsArray.isEmpty {
                Section(header: Text("PAYMENT SCHEDULE SUMMARY")) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(paymentTermsArray, id: \.id) { term in
                            HStack {
                                Text("\(Int(term.percentage))%")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(width: 50, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(term.name ?? "Payment Term")
                                        .fontWeight(.medium)
                                    
                                    Text(getFormattedDescription(term))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(formatCurrency(term.amount))
                                        .fontWeight(.medium)
                                    
                                    Text(getFormattedDueDate(term))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            if term != paymentTermsArray.last {
                                Divider()
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Total row
                    HStack {
                        Text("Total")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(totalPercentage))%")
                            .foregroundColor(totalPercentage == 100 ? .primary : .orange)
                            .fontWeight(.bold)
                        
                        Text(formatCurrency(proposal.totalAmount))
                            .fontWeight(.bold)
                    }
                    .padding(.top, 8)
                }
            }
            
            // Payment Terms Section
            Section(header: Text("PAYMENT TERMS")) {
                if paymentTermsArray.isEmpty {
                    Text("No payment terms defined yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(paymentTermsArray, id: \.id) { term in
                        Button(action: {
                            editingTermID = term.id
                            showingAddTerm = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(term.name ?? "Payment Term")
                                        .foregroundColor(.primary)
                                    
                                    Text("\(Int(term.percentage))% - \(formatCurrency(term.amount))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deletePaymentTerm)
                    
                    // Percentage validation warning
                    if totalPercentage != 100 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Total: \(Int(totalPercentage))% (should be 100%)")
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Button(action: {
                    editingTermID = nil
                    showingAddTerm = true
                }) {
                    Label("Add Payment Term", systemImage: "plus")
                }
                
                Button(action: {
                    showingTemplates = true
                }) {
                    Label("Apply Template", systemImage: "doc.on.doc")
                }
            }
            
            // Payment Methods Section
            Section(header: Text("PAYMENT METHODS")) {
                ForEach(paymentMethods, id: \.self) { method in
                    HStack {
                        Button(action: {
                            togglePaymentMethod(method)
                        }) {
                            HStack {
                                Image(systemName: selectedPaymentMethods.contains(method) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedPaymentMethods.contains(method) ? .blue : .gray)
                                
                                Text(method)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            
            // Notes Section
            Section(header: Text("PAYMENT NOTES")) {
                TextEditor(text: Binding(
                    get: { proposal.paymentNotes ?? "" },
                    set: { proposal.paymentNotes = $0 }
                ))
                .frame(minHeight: 100)
            }
        }
        .id(refreshTrigger) // Force refresh when needed
        .onAppear(perform: loadData)
        .navigationTitle("Payment Terms")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showingAddTerm) {
            NavigationView {
                PaymentTermFormView(
                    proposal: proposal,
                    termID: editingTermID,
                    onDismiss: {
                        refreshTerms()
                    }
                )
            }
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationView {
                PaymentTemplatesView(
                    proposal: proposal,
                    onApply: {
                        refreshTerms()
                    }
                )
                .navigationTitle("Payment Templates")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingTemplates = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadData() {
        // Initialize payment methods
        paymentMethods = ["Bank Transfer", "Credit Card", "PayPal", "Check", "Cash", "Mobile Payment"]
        
        // Load selected payment methods
        if let data = proposal.paymentMethodsData,
           let methods = try? JSONDecoder().decode([String].self, from: data) {
            selectedPaymentMethods = Set(methods)
        }
        
        // Trigger UI refresh
        refreshTrigger = UUID()
    }
    
    private func togglePaymentMethod(_ method: String) {
        if selectedPaymentMethods.contains(method) {
            selectedPaymentMethods.remove(method)
        } else {
            selectedPaymentMethods.insert(method)
        }
    }
    
    private func deletePaymentTerm(at offsets: IndexSet) {
        // Get terms to delete
        let termsToDelete = offsets.map { paymentTermsArray[$0] }
        
        // Delete terms
        for term in termsToDelete {
            viewContext.delete(term)
        }
        
        // Save changes
        do {
            try viewContext.save()
            refreshTerms()
        } catch {
            print("Error deleting payment terms: \(error)")
        }
    }
    
    private func saveChanges() {
        // Save payment methods
        let methodsArray = Array(selectedPaymentMethods)
        if let encoded = try? JSONEncoder().encode(methodsArray) {
            proposal.paymentMethodsData = encoded
        }
        
        // Save context
        do {
            try viewContext.save()
            
            // Log activity
            ActivityLogger.logProposalUpdated(
                proposal: proposal,
                context: viewContext,
                fieldChanged: "Payment Terms"
            )
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving payment terms: \(error)")
        }
    }
    
    private func refreshTerms() {
        // Force the view context to refresh all objects
        viewContext.refreshAllObjects()
        
        // Force refresh the view
        refreshTrigger = UUID()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}
