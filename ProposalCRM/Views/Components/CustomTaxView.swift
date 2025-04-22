import SwiftUI
import CoreData

struct CustomTaxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    // Form fields
    @State private var name = ""
    @State private var rate = ""
    
    // Template management
    @StateObject private var templateManager = TemplateManager.shared
    @State private var showingTemplates = false
    @State private var showingSaveTemplateDialog = false
    @State private var templateName = ""
    
    // UI states
    @State private var showingRatePresets = false
    @State private var showingCommonTaxes = false
    
    // Calculate tax base
    // Replace the existing taxBase calculation in CustomTaxView.swift
    private var taxBase: Double {
        return proposal.taxableProductsAmount
    }
    
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
                    
                    // Common Tax Templates Button
                    Button(action: {
                        withAnimation { showingCommonTaxes.toggle() }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(.blue)
                            Text("Common Tax Templates")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: showingCommonTaxes ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Common Tax Templates (collapsible)
                    if showingCommonTaxes {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(templateManager.getSortedTaxTemplates().filter(\.isDefault), id: \.id) { template in
                                    Button(action: {
                                        // Apply the template to our form fields
                                        name = template.taxName
                                        rate = String(format: "%.1f", template.rate)
                                        showingCommonTaxes = false
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            HStack {
                                                Text(template.taxName)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                Spacer()
                                                
                                                Text(Formatters.formatPercent(template.rate))
                                                    .font(.callout)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red.opacity(0.2))
                                                    .foregroundColor(.red)
                                                    .cornerRadius(8)
                                            }
                                            
                                            // Show calculated amount based on current tax base
                                            let calculatedAmount = taxBase * (template.rate / 100)
                                            Text("Calculated amount: \(Formatters.formatEuro(calculatedAmount))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
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

                // MARK: - Tax Details
                Section(header: Text("TAX DETAILS")) {
                    // Tax name field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tax Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter tax name", text: $name)
                            .font(.body)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                    
                    // Common tax types
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(["VAT", "GST", "Sales Tax", "Service Tax", "Import Tax"], id: \.self) { taxType in
                                Button(action: { name = taxType }) {
                                    Text(taxType)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(name == taxType ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(name == taxType ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Rate field with presets
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rate (%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Tax rate", text: $rate)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            
                            Button(action: {
                                withAnimation { showingRatePresets.toggle() }
                            }) {
                                Image(systemName: "percent")
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Rate presets (collapsible)
                    if showingRatePresets {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common Tax Rates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80), spacing: 8)
                            ], spacing: 8) {
                                ForEach([5.0, 7.0, 10.0, 15.0, 18.0, 19.0, 20.0, 21.0, 25.0], id: \.self) { preset in
                                    Button(action: {
                                        rate = String(format: "%.1f", preset)
                                        showingRatePresets = false
                                    }) {
                                        Text(Formatters.formatPercent(preset))
                                            .font(.body)
                                            .padding(8)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            // Country-specific tax rates
                            Text("By Country")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120), spacing: 8)
                            ], spacing: 8) {
                                ForEach([
                                    ("Germany", 19.0),
                                    ("France", 20.0),
                                    ("Italy", 22.0),
                                    ("Spain", 21.0),
                                    ("UK", 20.0),
                                    ("Sweden", 25.0),
                                    ("Denmark", 25.0),
                                    ("Netherlands", 21.0)
                                ], id: \.0) { country, taxRate in
                                    Button(action: {
                                        rate = String(format: "%.1f", taxRate)
                                        showingRatePresets = false
                                    }) {
                                        VStack(spacing: 2) {
                                            Text(Formatters.formatPercent(taxRate))
                                                .font(.subheadline)
                                            Text(country)
                                                .font(.caption)
                                        }
                                        .padding(8)
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Tax Base Section
                Section(header: Text("TAX CALCULATION")) {
                                   // Display tax base components
                                   VStack(alignment: .leading, spacing: 8) {
                                       Text("Tax Base Components:")
                                           .font(.subheadline)
                                           .foregroundColor(.secondary)
                                       
                                       HStack {
                                           Text("Products (taxable, partner price):")
                                               .font(.caption)
                                               .foregroundColor(.secondary)
                                           Spacer()
                                           Text(Formatters.formatEuro(proposal.taxableProductsAmount))
                                               .font(.caption)
                                       }
                                       
                                       Divider()
                                       
                                       HStack {
                                           Text("Total Tax Base:")
                                               .font(.subheadline)
                                               .fontWeight(.medium)
                                           Spacer()
                                           Text(Formatters.formatEuro(taxBase))
                                               .font(.subheadline)
                                               .fontWeight(.medium)
                                       }
                                       
                                       Text("Note: Only products marked with 'Apply Custom Tax' are included, calculated using partner price × quantity")
                                           .font(.caption2)
                                           .foregroundColor(.secondary)
                                   }
                                   .padding()
                                   .background(Color(.systemGray6))
                                   .cornerRadius(8)
                                   
                                   // Calculated tax amount
                                   if let rateValue = Double(rate), rateValue > 0 {
                                       let calculatedAmount = taxBase * (rateValue / 100)
                                       VStack(alignment: .leading, spacing: 8) {
                                           HStack {
                                               Text("Tax Rate:")
                                                   .font(.subheadline)
                                               Spacer()
                                               Text(Formatters.formatPercent(rateValue))
                                                   .font(.subheadline)
                                           }
                                           
                                           HStack {
                                               Text("Calculated Tax:")
                                                   .font(.headline)
                                               Spacer()
                                               Text(Formatters.formatEuro(calculatedAmount))
                                                   .font(.headline)
                                                   .foregroundColor(.red)
                                           }
                                       }
                                       .padding()
                                       .background(Color.red.opacity(0.1))
                                       .cornerRadius(8)
                                   }
                               }
                
                // MARK: - Preview Section
                if !name.isEmpty && Double(rate) != nil {
                    Section(header:
                        HStack {
                            Text("PREVIEW")
                            Spacer()
                            SaveTemplateButton {
                                // Initialize with current values
                                templateName = name + " " + rate + "%"
                                showingSaveTemplateDialog = true
                            }
                        }
                    ) {
                        // Preview what the tax will look like
                        if let rateValue = Double(rate) {
                            let calculatedAmount = taxBase * (rateValue / 100)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Applied to total: \(Formatters.formatEuro(taxBase))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(Formatters.formatPercent(rateValue))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(8)
                                        
                                        Text(Formatters.formatEuro(calculatedAmount))
                                            .font(.headline)
                                            .foregroundColor(.primary)
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
            .navigationTitle("Add Custom Tax")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addCustomTax()
                    }
                    .disabled(!isFormValid)
                }
            }
            // MARK: - Sheet Presentations
            .sheet(isPresented: $showingTemplates) {
                TaxTemplatesView(
                    isPresented: $showingTemplates,
                    onSelectTemplate: { template in
                        // Apply template values to form
                        name = template.taxName
                        rate = String(format: "%.1f", template.rate)
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
                                Text("Save the current tax as a template for future use:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Tax Name: ")
                                            .fontWeight(.semibold)
                                        Text(name)
                                    }
                                    .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text("Rate: ")
                                            .fontWeight(.semibold)
                                        Text(Formatters.formatPercent(Double(rate) ?? 0))
                                    }
                                    .foregroundColor(.primary)
                                    
                                    if let rateValue = Double(rate) {
                                        let calculatedExample = 1000 * (rateValue / 100)
                                        HStack {
                                            Text("Example: ")
                                                .fontWeight(.semibold)
                                            Text("\(Formatters.formatPercent(rateValue)) of €1,000 = \(Formatters.formatEuro(calculatedExample))")
                                        }
                                        .foregroundColor(.secondary)
                                    }
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
        !name.isEmpty && Double(rate) != nil
    }
    
    private func addCustomTax() {
           let tax = CustomTax(context: viewContext)
           tax.id = UUID()
           tax.name = name
           tax.rate = Double(rate) ?? 0
           
           // Calculate amount based on tax base
           tax.amount = taxBase * (tax.rate / 100)
           tax.proposal = proposal
           
           do {
               try viewContext.save()
               
               // Update proposal total
               updateProposalTotal()
               
               // Log activity
               ActivityLogger.logItemAdded(
                   proposal: proposal,
                   context: viewContext,
                   itemType: "Tax",
                   itemName: name
               )
               
               presentationMode.wrappedValue.dismiss()
           } catch {
               print("Error adding custom tax: \(error)")
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
    
    // Save current tax settings as a template
    private func saveAsTemplate() {
        let rateValue = Double(rate) ?? 0.0
        
        let template = TaxTemplate(
            name: templateName,
            taxName: name,
            rate: rateValue
        )
        
        templateManager.addTaxTemplate(template)
    }
}

// MARK: - Preview Provider
struct CustomTaxView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let proposal = Proposal(context: context)
        proposal.id = UUID()
        proposal.number = "PROP-2023-001"
        
        // Create some sample products for the preview
        let product = Product(context: context)
        product.id = UUID()
        product.name = "Sample Product"
        product.listPrice = 1000
        product.partnerPrice = 800
        
        // Create a proposal item with applyCustomTax = true
        let item = ProposalItem(context: context)
        item.id = UUID()
        item.product = product
        item.proposal = proposal
        item.quantity = 1
        item.applyCustomTax = true
        
        try? context.save()
        
        return CustomTaxView(proposal: proposal)
            .environment(\.managedObjectContext, context)
    }
}
