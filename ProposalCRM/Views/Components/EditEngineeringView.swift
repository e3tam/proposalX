//
//  EditEngineeringView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 21.04.2025.
//


import SwiftUI
import CoreData

struct EditEngineeringView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var engineering: Engineering
    
    @State private var description: String
    @State private var days: String
    @State private var rate: String
    
    init(engineering: Engineering) {
        self.engineering = engineering
        _description = State(initialValue: engineering.desc ?? "")
        _days = State(initialValue: String(format: "%.1f", engineering.days))
        _rate = State(initialValue: String(format: "%.2f", engineering.rate))
    }
    
    var body: some View {
        Form {
            Section(header: Text("ENGINEERING DETAILS")) {
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
                HStack {
                    Text("Amount")
                    Spacer()
                    let amount = calculateAmount()
                    Text(String(format: "€%.2f", amount))
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Edit Engineering")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!isFormValid)
            }
        }
    }
    
    private func calculateAmount() -> Double {
        let daysValue = Double(days) ?? 0
        let rateValue = Double(rate) ?? 0
        return daysValue * rateValue
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && Double(days) != nil && Double(rate) != nil
    }
    
    private func saveChanges() {
        engineering.desc = description
        engineering.days = Double(days) ?? 0
        engineering.rate = Double(rate) ?? 0
        engineering.amount = calculateAmount()
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}