import SwiftUI
import CoreData

struct EditExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var expense: Expense
    
    @State private var description: String
    @State private var amount: String
    @State private var selectedCategory = "Other"  // For UI only until model is extended
    @State private var showingAmountOptions = false
    @State private var showingCustomAmountAlert = false
    @State private var customAmountText = ""
    
    let categories = ["Travel", "Materials", "Services", "Equipment", "Shipping", "Other"]
    
    init(expense: Expense) {
        self.expense = expense
        _description = State(initialValue: expense.desc ?? "")
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        // If model is extended later: _selectedCategory = State(initialValue: expense.category ?? "Other")
    }
    
    var body: some View {
        Form {
            Section(header: Text("EXPENSE DETAILS")) {
                TextField("Description", text: $description)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (€)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        
                        Button(action: {
                            showingAmountOptions.toggle()
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if showingAmountOptions {
                        VStack(spacing: 10) {
                            Text("Quick Amounts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
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
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Common expense templates by category
            Section(header: Text("QUICK OPTIONS")) {
                let categoryOptions = getOptionsForCategory(selectedCategory)
                if !categoryOptions.isEmpty {
                    ForEach(categoryOptions, id: \.name) { option in
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
                } else {
                    Text("No quick options for this category")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Preview section
            Section(header: Text("PREVIEW")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(description.isEmpty ? "No description" : description)
                            .font(.headline)
                        
                        Text(selectedCategory)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(amount.isEmpty ? "€0.00" : Formatters.formatEuro(Double(amount) ?? 0))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Edit Expense")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
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
    
    private var isFormValid: Bool {
        !description.isEmpty && Double(amount) != nil
    }
    
    private func saveChanges() {
        expense.desc = description
        expense.amount = Double(amount) ?? 0
        // If model is extended: expense.category = selectedCategory
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    // Helper function to get options for a specific category
    private func getOptionsForCategory(_ category: String) -> [(name: String, description: String, amount: Double)] {
        switch category {
        case "Travel":
            return [
                ("Flight Tickets", "Round-trip flight tickets", 500.00),
                ("Hotel Accommodation", "Hotel stay for 3 nights", 450.00),
                ("Car Rental", "Car rental for 5 days", 350.00)
            ]
        case "Shipping":
            return [
                ("Standard Shipping", "Standard shipping service", 75.00),
                ("Express Shipping", "Express shipping service", 150.00),
                ("International Shipping", "International shipping and customs", 300.00)
            ]
        case "Services":
            return [
                ("Basic Installation", "Basic installation service", 250.00),
                ("Premium Installation", "Premium installation service", 500.00),
                ("Maintenance Contract", "Annual maintenance contract", 1200.00)
            ]
        case "Materials":
            return [
                ("Standard Package", "Standard materials package", 200.00),
                ("Premium Package", "Premium materials package", 400.00),
                ("Custom Materials", "Custom materials selection", 300.00)
            ]
        case "Equipment":
            return [
                ("Equipment Rental", "Equipment rental for 1 week", 350.00),
                ("Tools Purchase", "Specialized tools purchase", 500.00)
            ]
        default:
            return []
        }
    }
}
