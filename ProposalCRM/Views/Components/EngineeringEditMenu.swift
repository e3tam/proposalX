//
//  EngineeringEditMenu.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// EngineeringEditMenu.swift
// Popup menu for editing engineering entries inline

import SwiftUI
import CoreData

struct EngineeringEditMenu: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var engineering: Engineering
    @Binding var isPresented: Bool
    var onSave: () -> Void
    
    @State private var description: String
    @State private var days: Double
    @State private var rate: Double
    
    // Initialize with the current values
    init(engineering: Engineering, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.engineering = engineering
        self._isPresented = isPresented
        self.onSave = onSave
        
        _description = State(initialValue: engineering.desc ?? "")
        _days = State(initialValue: engineering.days)
        _rate = State(initialValue: engineering.rate)
    }
    
    private var amount: Double {
        return days * rate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Engineering")
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
            
            // Days control
            HStack {
                Text("Days:")
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        if days > 0.5 {
                            days -= 0.5
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    
                    Text(String(format: "%.1f", days))
                        .foregroundColor(.white)
                        .font(.title3)
                        .frame(minWidth: 40)
                    
                    Button(action: {
                        days += 0.5
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
            .padding()
            
            // Rate field
            HStack {
                Text("Daily Rate:")
                    .foregroundColor(.white)
                
                Spacer()
                
                TextField("", value: $rate, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
            }
            .padding(.horizontal)
            
            // Amount (calculated)
            HStack {
                Text("Total Amount:")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(String(format: "%.2f", amount))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
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
        engineering.desc = description
        engineering.days = days
        engineering.rate = rate
        engineering.amount = amount
        
        do {
            try viewContext.save()
            onSave()
            isPresented = false
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}