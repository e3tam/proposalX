//
//  EditProposalItemView.swift
//  ProposalCRM
//

import SwiftUI
import CoreData

struct EditProposalItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    let item: ProposalItem
    @Binding var didSave: Bool
    var onSave: () -> Void
    
    // Local state for editing values
    @State private var quantity: Double = 1.0
    @State private var quantityText: String = "1"
    @State private var discount: Double = 0.0
    @State private var multiplier: Double = 1.0
    @State private var multiplierText: String = "1.00"
    @State private var unitPrice: Double = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("PRODUCT DETAILS")) {
                    HStack {
                        Text("Product:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(item.product?.name ?? "Unknown Product")
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Code:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(item.product?.code ?? "No Code")
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Quantity:")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("", text: $quantityText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .onChange(of: quantityText) { newValue in
                                if let value = Double(newValue), value >= 1 {
                                    quantity = value
                                } else {
                                    quantityText = String(format: "%.0f", quantity)
                                }
                            }
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Discount (%)")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.0f%%", discount))
                                .foregroundColor(.white)
                        }
                        
                        Slider(value: $discount, in: 0...50, step: 1.0)
                            .accentColor(.blue)
                            .onChange(of: discount) { _ in
                                updateUnitPrice()
                            }
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                Section(header: Text("PRICING")) {
                    HStack {
                        Text("List Price")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.2f", item.product?.listPrice ?? 0))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Partner Price")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.2f", item.product?.partnerPrice ?? 0))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Multiplier")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 16) {
                            TextField("", text: $multiplierText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .onChange(of: multiplierText) { newValue in
                                    if let value = Double(newValue), value > 0 {
                                        multiplier = value
                                        updateUnitPrice()
                                    }
                                }
                            
                            Text("×")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 8) {
                            ForEach([0.8, 0.9, 1.0, 1.1, 1.2, 1.5], id: \.self) { value in
                                Button(action: {
                                    multiplier = value
                                    multiplierText = String(format: "%.2f", value)
                                    updateUnitPrice()
                                }) {
                                    Text(String(format: "%.1f×", value))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(multiplier == value ? Color.blue : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Text("Unit Price")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.2f", unitPrice))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Amount")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.2f", unitPrice * quantity))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                Section(header: Text("PROFIT & MARGIN")) {
                    HStack {
                        Text("Profit")
                            .foregroundColor(.gray)
                        Spacer()
                        let profit = (unitPrice - (item.product?.partnerPrice ?? 0)) * quantity
                        Text(String(format: "%.2f", profit))
                            .foregroundColor(profit > 0 ? .green : .red)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Margin")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f%%", calculateMargin()))
                            .foregroundColor(marginColor())
                            .fontWeight(.bold)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
            }
            .navigationTitle("Edit Product")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadItemData()
        }
    }
    
    private func loadItemData() {
        // Initialize from the item's current values
        quantity = max(1.0, item.quantity)
        quantityText = String(format: "%.0f", quantity)
        discount = item.discount
        unitPrice = item.unitPrice
        
        // Calculate initial multiplier
        let listPrice = item.product?.listPrice ?? 1.0 // Avoid division by zero
        let discountFactor = 1.0 - (discount / 100.0)
        if listPrice > 0 && discountFactor > 0 {
            multiplier = unitPrice / (listPrice * discountFactor)
        } else {
            multiplier = 1.0
        }
        multiplierText = String(format: "%.2f", multiplier)
    }
    
    private func updateUnitPrice() {
        let listPrice = item.product?.listPrice ?? 0
        unitPrice = listPrice * multiplier * (1 - discount/100)
    }
    
    private func calculateMargin() -> Double {
        let amount = unitPrice * quantity
        let cost = (item.product?.partnerPrice ?? 0) * quantity
        let profit = amount - cost
        
        if amount <= 0 {
            return 0
        }
        return (profit / amount) * 100
    }
    
    private func marginColor() -> Color {
        let margin = calculateMargin()
        if margin >= 20 {
            return .green
        } else if margin >= 10 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func saveChanges() {
        // Update the item with new values
        item.quantity = quantity
        item.discount = discount
        item.unitPrice = unitPrice
        item.amount = unitPrice * quantity
        
        do {
            try viewContext.save()
            
            // Update proposal totals
            if let proposal = item.proposal {
                let productsTotal = proposal.subtotalProducts
                let engineeringTotal = proposal.subtotalEngineering
                let expensesTotal = proposal.subtotalExpenses
                let taxesTotal = proposal.subtotalTaxes
                
                proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
                
                try viewContext.save()
            }
            
            // Notify that save was successful
            didSave = true
            onSave()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}
