import SwiftUI
import CoreData

struct CustomTaxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    @State private var name = ""
    @State private var rate = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TAX DETAILS")) {
                    TextField("Tax Name", text: $name)
                    
                    HStack {
                        Text("Rate (%)")
                        Spacer()
                        TextField("", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    // Display calculated amount
                    if let rateValue = Double(rate) {
                        let taxBase = proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
                        let calculatedAmount = (taxBase * rateValue) / 100
                        
                        HStack {
                            Text("Calculated Amount")
                            Spacer()
                            Text(String(format: "€%.2f", calculatedAmount))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Based on total taxable amount: €\(String(format: "%.2f", taxBase))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Common tax templates
                Section(header: Text("COMMON TAXES")) {
                    Button("VAT (19%)") {
                        name = "VAT"
                        rate = "19"
                    }
                    
                    Button("Sales Tax (7%)") {
                        name = "Sales Tax"
                        rate = "7"
                    }
                    
                    Button("Special Tax (5%)") {
                        name = "Special Tax"
                        rate = "5"
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
        let taxBase = proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
        tax.amount = (taxBase * tax.rate) / 100
        
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
}
