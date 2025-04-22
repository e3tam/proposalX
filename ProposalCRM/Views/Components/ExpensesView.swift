import SwiftUI
import CoreData

struct ExpensesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    // Main form fields
    @State private var description = ""
    @State private var amount = ""
    @State private var selectedCategory = "Other"
    @State private var isRecurring = false
    
    // Template management
    @StateObject private var templateManager = TemplateManager.shared
    @State private var showingTemplates = false
    @State private var showingSaveTemplateDialog = false
    @State private var templateName = ""
    
    // UI states
    @State private var showingCustomAmountAlert = false
    @State private var customAmountText = ""
    @State private var showingCategoryOptions = false
    @State private var showingAmountOptions = false
    @State private var showingExpenseTemplates = false
    
    // Available categories
    let categories = ["Travel", "Materials", "Services", "Equipment", "Shipping", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Templates Section
                Section(header: Text("TEMPLATES").foregroundColor(.blue)) {
                    Button(action: { showingTemplates = true }) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.blue)
                            Text("Select from Saved Templates")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Quick expense templates button
                    Button(action: {
                        withAnimation { showingExpenseTemplates.toggle() }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(.blue)
                            Text("Quick Expense Templates")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: showingExpenseTemplates ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Quick expense templates (collapsible)
                    if showingExpenseTemplates {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(templateManager.getSortedExpenseTemplates().filter(\.isDefault), id: \.id) { template in
                                    Button(action: {
                                        // Apply the preset to our form fields
                                        description = template.description
                                        selectedCategory = template.category
                                        amount = String(format: "%.2f", template.amount)
                                        showingExpenseTemplates = false
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text(template.description)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            
                                            HStack {
                                                Text(template.category)
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 2)
                                                    .background(categoryColor(template.category).opacity(0.2))
                                                    .foregroundColor(categoryColor(template.category))
                                                    .cornerRadius(4)
                                                
                                                Spacer()
                                                
                                                Text(Formatters.formatEuro(template.amount))
                                                    .font(.callout)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(height: 250)
                    }
                }
                
                // MARK: - Expense Details
                Section(header: Text("EXPENSE DETAILS")) {
                    // Description field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter a description", text: $description)
                            .font(.body)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                    
                    // Category picker with visual indicator
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            withAnimation { showingCategoryOptions.toggle() }
                        }) {
                            HStack {
                                Text(selectedCategory)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 10)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Category options (collapsible)
                    if showingCategoryOptions {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 8)
                        ], spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                    showingCategoryOptions = false
                                }) {
                                    HStack {
                                        Image(systemName: categoryIcon(category))
                                            .foregroundColor(categoryColor(category))
                                        Text(category)
                                    }
                                    .padding(8)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .background(selectedCategory == category ?
                                        categoryColor(category).opacity(0.2) :
                                        Color.gray.opacity(0.1))
                                    .foregroundColor(selectedCategory == category ?
                                        categoryColor(category) :
                                        .primary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Amount field with options
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount (€)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            
                            Button(action: {
                                withAnimation { showingAmountOptions.toggle() }
                            }) {
                                Image(systemName: "eurosign.circle")
                                    .foregroundColor(.green)
                                    .padding(8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Amount presets (collapsible)
                    if showingAmountOptions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common Amounts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80), spacing: 8)
                            ], spacing: 8) {
                                ForEach([50.0, 100.0, 200.0, 500.0, 1000.0], id: \.self) { preset in
                                    Button(action: {
                                        amount = String(format: "%.2f", preset)
                                        showingAmountOptions = false
                                    }) {
                                        Text(Formatters.formatEuro(preset))
                                            .font(.body)
                                            .padding(8)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                Button(action: {
                                    showingCustomAmountAlert = true
                                    showingAmountOptions = false
                                }) {
                                    Text("Custom")
                                        .font(.body)
                                        .padding(8)
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Category-specific amounts based on selected category
                            let categoryAmounts = suggestedAmountsForCategory(selectedCategory)
                            if !categoryAmounts.isEmpty {
                                Text("\(selectedCategory) Typical Expenses")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 120), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(categoryAmounts, id: \.value) { item in
                                        Button(action: {
                                            amount = String(format: "%.2f", item.value)
                                            description = item.name
                                            showingAmountOptions = false
                                        }) {
                                            VStack(spacing: 2) {
                                                Text(Formatters.formatEuro(item.value))
                                                    .font(.subheadline)
                                                Text(item.name)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                            }
                                            .padding(8)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .background(categoryColor(selectedCategory).opacity(0.2))
                                            .foregroundColor(categoryColor(selectedCategory))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Toggle for recurring expense
                    Toggle("Recurring Expense", isOn: $isRecurring)
                        .padding(.vertical, 10)
                }
                
                // MARK: - Preview Section
                if !description.isEmpty && Double(amount) != nil {
                    Section(header:
                        HStack {
                            Text("PREVIEW")
                            Spacer()
                            SaveTemplateButton {
                                // Initialize with current values
                                templateName = description
                                showingSaveTemplateDialog = true
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Expense entry preview
                            VStack(alignment: .leading, spacing: 4) {
                                Text(description)
                                    .font(.headline)
                                
                                HStack {
                                    // Category badge
                                    HStack(spacing: 4) {
                                        Image(systemName: categoryIcon(selectedCategory))
                                        Text(selectedCategory)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(categoryColor(selectedCategory).opacity(0.2))
                                    .foregroundColor(categoryColor(selectedCategory))
                                    .cornerRadius(8)
                                    
                                    if isRecurring {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                            Text("Recurring")
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                    
                                    Spacer()
                                    
                                    if let amountValue = Double(amount) {
                                        Text(Formatters.formatEuro(amountValue))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
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
            // MARK: - Sheet Presentations
            .sheet(isPresented: $showingTemplates) {
                ExpenseTemplatesView(
                    isPresented: $showingTemplates,
                    onSelectTemplate: { template in
                        // Apply template values to form
                        description = template.description
                        selectedCategory = template.category
                        amount = String(format: "%.2f", template.amount)
                    }
                )
                .environmentObject(templateManager)
            }
            // MARK: - Template Save Dialog
            .overlay(
                Group {
                    if showingSaveTemplateDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingSaveTemplateDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingSaveTemplateDialog,
                            title: "Save as Template",
                            templateName: $templateName,
                            onSave: saveAsTemplate
                        ) {
                            // Dialog content
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Save the current expense as a template for future use:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Description: ")
                                            .fontWeight(.semibold)
                                        Text(description)
                                    }
                                    .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text("Category: ")
                                            .fontWeight(.semibold)
                                        Text(selectedCategory)
                                    }
                                    .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text("Amount: ")
                                            .fontWeight(.semibold)
                                        Text(Formatters.formatEuro(Double(amount) ?? 0))
                                    }
                                    .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                // Save as default option
                                Toggle("Save as default template", isOn: .constant(false))
                                    .font(.subheadline)
                            }
                        }
                        .transition(.scale)
                    }
                }
            )
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
        
        // For future reference: add these fields to the Expense entity
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
    
    // Save current expense settings as a template
    private func saveAsTemplate() {
        let amountValue = Double(amount) ?? 0.0
        
        let template = ExpenseTemplate(
            name: templateName,
            description: description,
            category: selectedCategory,
            amount: amountValue
        )
        
        templateManager.addExpenseTemplate(template)
    }
    
    // MARK: - Helper Functions
    
    // Return a color for each category
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Travel":
            return .blue
        case "Materials":
            return .orange
        case "Services":
            return .green
        case "Equipment":
            return .purple
        case "Shipping":
            return .red
        default:
            return .gray
        }
    }
    
    // Return an icon for each category
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Travel":
            return "airplane"
        case "Materials":
            return "shippingbox"
        case "Services":
            return "wrench.and.screwdriver"
        case "Equipment":
            return "desktopcomputer"
        case "Shipping":
            return "shippingbox.fill"
        default:
            return "doc"
        }
    }
    
    // Suggested amounts for each category
    private func suggestedAmountsForCategory(_ category: String) -> [(name: String, value: Double)] {
        switch category {
        case "Travel":
            return [
                ("Flight Tickets", 500.0),
                ("Hotel (3 nights)", 450.0),
                ("Car Rental", 350.0),
                ("Taxi Service", 75.0)
            ]
        case "Materials":
            return [
                ("Basic Materials", 200.0),
                ("Premium Package", 400.0),
                ("Custom Materials", 300.0)
            ]
        case "Services":
            return [
                ("Basic Installation", 250.0),
                ("Premium Installation", 500.0),
                ("Maintenance Contract", 1200.0)
            ]
        case "Equipment":
            return [
                ("Equipment Rental", 350.0),
                ("Tools Purchase", 500.0),
                ("Office Equipment", 250.0)
            ]
        case "Shipping":
            return [
                ("Standard Shipping", 75.0),
                ("Express Shipping", 150.0),
                ("International Shipping", 300.0)
            ]
        default:
            return [
                ("Miscellaneous", 100.0),
                ("Office Supplies", 50.0),
                ("Other Costs", 200.0)
            ]
        }
    }
}

// MARK: - Preview Provider
struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let proposal = Proposal(context: context)
        proposal.id = UUID()
        proposal.number = "PROP-2023-001"
        
        return ExpensesView(proposal: proposal)
            .environment(\.managedObjectContext, context)
    }
}
