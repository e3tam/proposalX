//
//  EditPaymentTermsView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// EditPaymentTermsView.swift
// View for editing payment terms and conditions for a proposal

import SwiftUI
import CoreData

struct EditPaymentTermsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    // Reference to the payment manager
    @ObservedObject private var paymentManager = ProposalPaymentManager.shared
    
    // State variables for form fields
    @State private var paymentTerms: String
    @State private var depositRequired: Bool
    @State private var depositType: String // "percentage" or "fixed"
    @State private var depositPercentage: String
    @State private var depositAmount: String
    @State private var selectedPaymentMethods: Set<String>
    @State private var latePenalty: String
    @State private var invoiceSchedule: String
    @State private var customTerms: String
    
    // Payment method options
    let paymentMethodOptions = [
        "Bank Transfer", "Credit Card", "PayPal", "Check", "Cash",
        "Direct Debit", "Wire Transfer", "Mobile Payment"
    ]
    
    // Common payment terms presets
    let paymentTermsPresets = [
        "Due on receipt",
        "Net 15",
        "Net 30",
        "Net 45",
        "Net 60",
        "50% advance, 50% upon delivery",
        "30% advance, 70% upon completion"
    ]
    
    // Initialize with existing values from the proposal
    init(proposal: Proposal) {
        self.proposal = proposal
        let manager = ProposalPaymentManager.shared
        
        // Initialize state variables with current values
        _paymentTerms = State(initialValue: manager.getTerms(for: proposal))
        _depositRequired = State(initialValue: manager.isDepositRequired(for: proposal))
        
        let percentage = manager.getDepositPercentage(for: proposal)
        _depositType = State(initialValue: percentage > 0 ? "percentage" : "fixed")
        _depositPercentage = State(initialValue: String(format: "%.1f", percentage))
        _depositAmount = State(initialValue: String(format: "%.2f", manager.getDepositAmount(for: proposal)))
        _selectedPaymentMethods = State(initialValue: Set(manager.getPaymentMethods(for: proposal)))
        _latePenalty = State(initialValue: manager.getLatePenalty(for: proposal))
        _invoiceSchedule = State(initialValue: manager.getInvoiceSchedule(for: proposal))
        _customTerms = State(initialValue: manager.getCustomTerms(for: proposal))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Payment Terms Section
                Section(header: Text("PAYMENT TERMS")) {
                    // Payment terms text field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Terms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter payment terms", text: $paymentTerms)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    // Common payment terms presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(paymentTermsPresets, id: \.self) { preset in
                                Button(action: {
                                    paymentTerms = preset
                                }) {
                                    Text(preset)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(paymentTerms == preset ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(paymentTerms == preset ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Deposit Requirements
                Section(header: Text("DEPOSIT REQUIREMENTS")) {
                    Toggle("Deposit Required", isOn: $depositRequired)
                    
                    if depositRequired {
                        Picker("Deposit Type", selection: $depositType) {
                            Text("Percentage").tag("percentage")
                            Text("Fixed Amount").tag("fixed")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if depositType == "percentage" {
                            HStack {
                                Text("Percentage")
                                Spacer()
                                TextField("0.0", text: $depositPercentage)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("%")
                            }
                            
                            // Show the calculated amount for reference
                            if let percentage = Double(depositPercentage), percentage > 0 {
                                let amount = (proposal.totalAmount * percentage) / 100
                                Text("Calculated amount: \(Formatters.formatEuro(amount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Text("Amount")
                                Spacer()
                                TextField("0.00", text: $depositAmount)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
                
                // MARK: - Payment Methods
                Section(header: Text("PAYMENT METHODS")) {
                    ForEach(paymentMethodOptions, id: \.self) { method in
                        Button(action: {
                            if selectedPaymentMethods.contains(method) {
                                selectedPaymentMethods.remove(method)
                            } else {
                                selectedPaymentMethods.insert(method)
                            }
                        }) {
                            HStack {
                                Text(method)
                                Spacer()
                                if selectedPaymentMethods.contains(method) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // MARK: - Additional Terms
                Section(header: Text("ADDITIONAL TERMS")) {
                    // Late payment penalty
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Late Payment Penalty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., 2% monthly interest on overdue amounts", text: $latePenalty)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    // Invoice schedule
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invoice Schedule")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Monthly invoicing on the first of each month", text: $invoiceSchedule)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    // Custom terms
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Terms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $customTerms)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Preview
                Section(header: Text("PREVIEW")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Terms: \(paymentTerms)")
                            .font(.subheadline)
                        
                        if depositRequired {
                            let depositDescription = depositType == "percentage" ?
                                "\(depositPercentage)% deposit required" :
                                "Deposit of \(Formatters.formatEuro(Double(depositAmount) ?? 0)) required"
                            
                            Text(depositDescription)
                                .font(.subheadline)
                        }
                        
                        Text("Payment Methods: \(Array(selectedPaymentMethods).joined(separator: ", "))")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Edit Payment Terms")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        // Update payment terms via the manager
        paymentManager.setTerms(paymentTerms, for: proposal)
        paymentManager.setDepositRequired(depositRequired, for: proposal)
        
        if depositType == "percentage" {
            paymentManager.setDepositPercentage(Double(depositPercentage) ?? 0, for: proposal)
            paymentManager.setDepositAmount(0, for: proposal) // Reset fixed amount when using percentage
        } else {
            paymentManager.setDepositAmount(Double(depositAmount) ?? 0, for: proposal)
            paymentManager.setDepositPercentage(0, for: proposal) // Reset percentage when using fixed amount
        }
        
        // Update payment methods
        paymentManager.setPaymentMethods(Array(selectedPaymentMethods), for: proposal)
        
        // Update additional terms
        paymentManager.setLatePenalty(latePenalty, for: proposal)
        paymentManager.setInvoiceSchedule(invoiceSchedule, for: proposal)
        paymentManager.setCustomTerms(customTerms, for: proposal)
        
        // Log activity
        ActivityLogger.logProposalUpdated(
            proposal: proposal,
            context: viewContext,
            fieldChanged: "Payment Terms"
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}
