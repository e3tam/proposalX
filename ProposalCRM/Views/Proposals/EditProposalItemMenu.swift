//
//  EditProposalItemMenu.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// EditProposalItemMenu.swift
// Popup menu for editing proposal items inline

import SwiftUI
import CoreData

struct EditProposalItemMenu: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: ProposalItem
    @Binding var isPresented: Bool
    var onSave: () -> Void
    
    @State private var quantity: Double
    @State private var discount: Double
    @State private var unitPrice: Double
    
    // Initialize with the current values
    init(item: ProposalItem, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.item = item
        self._isPresented = isPresented
        self.onSave = onSave
        
        _quantity = State(initialValue: item.quantity)
        _discount = State(initialValue: item.discount)
        _unitPrice = State(initialValue: item.unitPrice)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Item")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // Product info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.productName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(item.productCode)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.black.opacity(0.5))
            
            // Quantity control
            HStack {
                Text("Quantity:")
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        if quantity > 1 {
                            quantity -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    
                    Text("\(Int(quantity))")
                        .foregroundColor(.white)
                        .font(.title3)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        quantity += 1
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
            .padding()
            
            // Discount slider
            VStack(spacing: 5) {
                HStack {
                    Text("Discount:")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(discount))%")
                        .foregroundColor(.white)
                }
                
                Slider(value: $discount, in: 0...50, step: 1)
                    .accentColor(.blue)
            }
            .padding()
            
            // Unit price
            HStack {
                Text("Unit Price:")
                    .foregroundColor(.white)
                
                Spacer()
                
                TextField("", value: $unitPrice, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
            }
            .padding()
            
            // Amount (calculated)
            HStack {
                Text("Total Amount:")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(String(format: "%.2f", calculateAmount()))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            .padding()
            
            // Profit information
            if let product = item.product {
                VStack(spacing: 8) {
                    HStack {
                        Text("Partner Price:")
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(String(format: "%.2f", product.partnerPrice * quantity))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Profit:")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        let profit = calculateAmount() - (product.partnerPrice * quantity)
                        Text(String(format: "%.2f", profit))
                            .foregroundColor(profit > 0 ? .green : .red)
                    }
                    
                    HStack {
                        Text("Margin:")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        let amount = calculateAmount()
                        let cost = product.partnerPrice * quantity
                        let margin = amount > 0 ? ((amount - cost) / amount) * 100 : 0
                        Text(String(format: "%.1f%%", margin))
                            .foregroundColor(margin > 20 ? .green : (margin > 10 ? .orange : .red))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    saveChanges()
                }) {
                    Text("Save")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(width: 350)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
    
    private func calculateAmount() -> Double {
        return unitPrice * quantity
    }
    
    private func saveChanges() {
        item.quantity = quantity
        item.discount = discount
        item.unitPrice = unitPrice
        item.amount = calculateAmount()
        
        do {
            try viewContext.save()
            onSave()
            isPresented = false
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}