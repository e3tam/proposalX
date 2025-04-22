//
//  ExpensesEditMenu.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// ExpensesEditMenu.swift
// Popup menu for editing expense entries inline

import SwiftUI
import CoreData

struct ExpensesEditMenu: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var expense: Expense
    @Binding var isPresented: Bool
    var onSave: () -> Void
    
    @State private var description: String
    @State private var amount: Double
    
    // Initialize with the current values
    init(expense: Expense, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.expense = expense
        self._isPresented = isPresented
        self.onSave = onSave
        
        _description = State(initialValue: expense.desc ?? "")
        _amount = State(initialValue: expense.amount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Expense")
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
            
            // Description field
            VStack(alignment: .leading, spacing: 8) {
                Text("Description:")
                    .foregroundColor(.white)
                
                TextField("", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Common expense presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["Travel", "Accommodation", "Food", "Equipment", "Supplies"], id: \.self) { preset in
                        Button(action: {
                            description = preset
                        }) {
                            Text(preset)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(description == preset ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            
            // Amount field
            HStack {
                Text("Amount:")
                    .foregroundColor(.white)
                
                Spacer()
                
                TextField("", value: $amount, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
            }
            .padding()
            
            // Common amounts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach([100.0, 200.0, 500.0, 1000.0, 1500.0], id: \.self) { preset in
                        Button(action: {
                            amount = preset
                        }) {
                            Text(String(format: "%.0f", preset))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(amount == preset ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
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
        expense.desc = description
        expense.amount = amount
        
        do {
            try viewContext.save()
            onSave()
            isPresented = false
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}