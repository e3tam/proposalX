import SwiftUI
import CoreData

struct ExpensesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    @State private var description = ""
    @State private var amount = ""
    @State private var selectedCategory = "Other"
    @State private var isRecurring = false
    @State private var showingCustomAmountAlert = false
    @State private var customAmountText = ""
    
    let categories = ["Travel", "Materials", "Services", "Equipment", "Shipping", "Other"]
    
    // Common expense templates with predefined values
    let quickAddOptions: [(name: String, description: String, amount: Double, category: String)] = [
        ("Flight Tickets", "Round-trip flight tickets", 500.00, "Travel"),
        ("Hotel Accommodation", "Hotel stay for 3 nights", 450.00, "Travel"),
        ("Shipping Standard", "Standard shipping service", 75.00, "Shipping"),
        ("Shipping Express", "Express shipping service", 150.00, "Shipping"),
        ("Installation Basic", "Basic installation service", 250.00, "Services"),
        ("Installation Premium", "Premium installation service", 500.00, "Services"),
        ("Materials Bundle", "Standard materials package", 200.00, "Materials"),
        ("Equipment Rental", "Equipment rental for 1 week", 350.00, "Equipment")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Main expense details section
                Section(header: Text("EXPENSE DETAILS")) {
                    TextField("Description", text: $description)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    HStack {
                        Text("Amount (€)")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    Toggle("Recurring Expense", isOn: $isRecurring)
                }
                
                // Quick add templates with predefined values
                Section(header: Text("QUICK ADD OPTIONS")) {
                    ForEach(quickAddOptions.filter { $0.category == selectedCategory }, id: \.name) { option in
                        Button(action: {
                            description = option.description
                            amount = String(format: "%.2f", option.amount)
                        }) {
                            HStack {
                                Text(option.name)
                                Spacer()
                                Text(Formatters.formatEuro(option.amount))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if quickAddOptions.filter({ $0.category == selectedCategory }).isEmpty {
                        Text("No quick options for this category")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Common expense amounts section
                Section(header: Text("COMMON AMOUNTS")) {
                    HStack(spacing: 12) {
                        ForEach([50.0, 100.0, 200.0, 500.0], id: \.self) { value in
                            Button(action: {
                                amount = String(format: "%.2f", value)
                            }) {
                                Text(Formatters.formatEuro(value))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: {
                            showingCustomAmountAlert = true
                        }) {
                            Text("Custom")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                // Preview section
                if !description.isEmpty || !amount.isEmpty {
                    Section(header: Text("PREVIEW")) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(description.isEmpty ? "No description" : description)
                                    .font(.headline)
                                
                                Text(selectedCategory)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if isRecurring {
                                    Text("Recurring expense")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            Text(amount.isEmpty ? "€0.00" : Formatters.formatEuro(Double(amount) ?? 0))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Enter Custom Amount", isPresented: $showingCustomAmountAlert) {
                TextField("Amount", text: $customAmountText)
                    .keyboardType(.decimalPad)
                
                Button("Cancel", role: .cancel) {
                    customAmountText = ""
                }
                
                Button("OK") {
                    if let value = Double(customAmountText) {
                        amount = String(format: "%.2f", value)
                    }
                    customAmountText = ""
                }
            } message: {
                Text("Enter a custom amount for this expense")
            }
        }
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && Double(amount) != nil
    }
    
    private func addExpense() {
        let expense = Expense(context: viewContext)
        expense.id = UUID()
        expense.desc = description
        expense.amount = Double(amount) ?? 0
        expense.proposal = proposal
        
        // For future reference: if Expense entity is extended with category and recurring fields
        // expense.category = selectedCategory
        // expense.isRecurring = isRecurring
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            // Log activity
            ActivityLogger.logItemAdded(
                proposal: proposal,
                context: viewContext,
                itemType: "Expense",
                itemName: description
            )
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error adding expense: \(error)")
        }
    }
    
    private func updateProposalTotal() {
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating proposal total: \(error)")
        }
    }
}
