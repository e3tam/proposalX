//
//  EditCustomTaxView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 21.04.2025.
//


import SwiftUI
import CoreData

struct EditCustomTaxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var customTax: CustomTax
    @ObservedObject var proposal: Proposal
    
    @State private var name: String
    @State private var rate: String
    
    init(customTax: CustomTax, proposal: Proposal) {
        self.customTax = customTax
        self.proposal = proposal
        _name = State(initialValue: customTax.name ?? "")
        _rate = State(initialValue: String(format: "%.1f", customTax.rate))
    }
    
    var body: some View {
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
                    
                    // Show tax base for reference
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tax Base Calculation:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Products: €\(String(format: "%.2f", proposal.subtotalProducts))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Engineering: €\(String(format: "%.2f", proposal.subtotalEngineering))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Expenses: €\(String(format: "%.2f", proposal.subtotalExpenses))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Total Base: €\(String(format: "%.2f", taxBase))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Custom Tax")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!isFormValid)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && Double(rate) != nil
    }
    
    private func saveChanges() {
        customTax.name = name
        customTax.rate = Double(rate) ?? 0
        
        // Recalculate amount based on tax base
        let taxBase = proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
        customTax.amount = (taxBase * customTax.rate) / 100
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}