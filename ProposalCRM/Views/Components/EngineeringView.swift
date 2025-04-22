import SwiftUI
import CoreData

struct EngineeringView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    @State private var description = ""
    @State private var days = ""
    @State private var rate = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ENGINEERING SERVICE")) {
                    TextField("Description", text: $description)
                    
                    TextField("Days", text: $days)
                        .keyboardType(.decimalPad)
                    
                    HStack {
                        Text("Rate (€)")
                        Spacer()
                        TextField("", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    // Amount (calculated)
                    if let daysValue = Double(days), let rateValue = Double(rate) {
                        let amount = daysValue * rateValue
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text(String(format: "€%.2f", amount))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Engineering")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addEngineering()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && Double(days) != nil && Double(rate) != nil
    }
    
    private func addEngineering() {
        let engineering = Engineering(context: viewContext)
        engineering.id = UUID()
        engineering.desc = description
        engineering.days = Double(days) ?? 0
        engineering.rate = Double(rate) ?? 0
        engineering.amount = engineering.days * engineering.rate
        engineering.proposal = proposal
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            // Log activity
            ActivityLogger.logItemAdded(
                proposal: proposal,
                context: viewContext,
                itemType: "Engineering",
                itemName: description
            )
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error adding engineering: \(error)")
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
