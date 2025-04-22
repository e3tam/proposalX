//
//  CustomTaxEditMenu.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// CustomTaxEditMenu.swift
// Popup menu for editing custom tax entries inline

import SwiftUI
import CoreData

struct CustomTaxEditMenu: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customTax: CustomTax
    @Binding var isPresented: Bool
    var onSave: () -> Void
    
    @State private var name: String
    @State private var rate: Double
    
    @ObservedObject var proposal: Proposal
    
    // Initialize with the current values
    init(customTax: CustomTax, proposal: Proposal, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.customTax = customTax
        self.proposal = proposal
        self._isPresented = isPresented
        self.onSave = onSave
        
        _name = State(initialValue: customTax.name ?? "")
        _rate = State(initialValue: customTax.rate)
    }
    
    // Calculate the base amount on which tax applies
    private var subtotal: Double {
        return proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
    }
    
    // Calculate the tax amount
    private var amount: Double {
        return subtotal * (rate / 100)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Custom Tax")
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
            
            // Tax name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Tax Name:")
                    .foregroundColor(.white)
                
                TextField("", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Tax presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["VAT", "GST", "Sales Tax", "Service Tax", "Import Tax"], id: \.self) { preset in
                        Button(action: {
                            name = preset
                        }) {
                            Text(preset)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(name == preset ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            
            // Rate slider
            VStack(spacing: 5) {
                HStack {
                    Text("Rate:")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", rate))
                        .foregroundColor(.white)
                }
                
                Slider(value: $rate, in: 0...30, step: 0.5)
                    .accentColor(.blue)
            }
            .padding()
            
            // Common rates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach([5.0, 10.0, 15.0, 18.0, 20.0], id: \.self) { preset in
                        Button(action: {
                            rate = preset
                        }) {
                            Text(String(format: "%.1f%%", preset))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(rate == preset ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Base amount and calculated tax
            VStack(spacing: 10) {
                HStack {
                    Text("Subtotal:")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", subtotal))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Tax Amount:")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", amount))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
            .padding()
            
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
    
    private func saveChanges() {
        customTax.name = name
        customTax.rate = rate
        customTax.amount = amount
        
        do {
            try viewContext.save()
            onSave()
            isPresented = false
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}