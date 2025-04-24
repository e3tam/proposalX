//
//  PaymentStatusSection.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 24.04.2025.
//


import SwiftUI
import CoreData

struct PaymentStatusSection: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // State for recording payment
    @State private var showingRecordPaymentSheet = false
    @State private var selectedPaymentTerm: PaymentTerm?
    
    // State for payment details
    @State private var paymentDate = Date()
    @State private var paymentReference = ""
    @State private var paymentMethod = "Bank Transfer"
    @State private var paymentNote = ""
    
    // Available payment methods
    private let paymentMethods = ["Bank Transfer", "Credit Card", "Check", "Cash", "PayPal", "Other"]
    
    // Dynamic colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.1) : Color(UIColor.tertiarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with payment status
            HStack {
                Text("Payment Status")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                // Payment status pill
                let (statusText, statusColor) = proposal.paymentStatusWithColor
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(20)
            }
            
            if proposal.sortedPaymentTerms.isEmpty {
                emptyPaymentTermsView
            } else {
                // Payment summary
                paymentSummaryCard
                
                // Payment schedule table
                paymentScheduleTable
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingRecordPaymentSheet) {
            if let term = selectedPaymentTerm {
                NavigationView {
                    recordPaymentView(for: term)
                        .navigationTitle("Record Payment")
                        .navigationBarItems(
                            leading: Button("Cancel") {
                                showingRecordPaymentSheet = false
                            },
                            trailing: Button("Save") {
                                recordPayment(for: term)
                                showingRecordPaymentSheet = false
                            }
                        )
                }
            } else {
                // Fallback view when no term is selected
                Text("No payment term selected")
                    .padding()
            }
        }
    }
    
    // Empty state view when no payment terms defined
    private var emptyPaymentTermsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 40))
                .foregroundColor(secondaryTextColor)
                .padding(.top, 20)
            
            Text("No payment schedule defined")
                .font(.headline)
                .foregroundColor(secondaryTextColor)
            
            Text("Add payment terms to track payments for this proposal.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
    
    // Payment summary card
    private var paymentSummaryCard: some View {
        VStack(spacing: 12) {
            // Paid vs total amount
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount Paid")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    
                    Text(Formatters.formatEuro(proposal.totalPaidAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(proposal.isFullyPaid ? .green : primaryTextColor)
                }
                
                Spacer()
                
                Text("of \(Formatters.formatEuro(proposal.totalAmount))")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
            }
            
            // Progress bar for payment completion
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress bar
                    Rectangle()
                        .fill(progressBarColor)
                        .frame(width: max(0, min(paymentProgress * geometry.size.width, geometry.size.width)), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Remaining amount and overdue status
            HStack {
                if !proposal.isFullyPaid {
                    Text("\(Formatters.formatEuro(proposal.totalDueAmount)) remaining")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                    
                    Spacer()
                    
                    if proposal.hasOverduePayments {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text("Overdue payment")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Text("Fully paid")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            // Late fees if applicable
            if proposal.totalLateFees > 0 {
                HStack {
                    Text("Late fees:")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text(Formatters.formatEuro(proposal.totalLateFees))
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
    
    // Payment schedule table
    private var paymentScheduleTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Payment")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Due Date")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 100, alignment: .trailing)
                
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 100, alignment: .trailing)
                
                Text("Status")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .center)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color(UIColor.secondarySystemBackground))
            
            // Payment terms rows
            ForEach(proposal.sortedPaymentTerms, id: \.id) { term in
                paymentTermRow(term)
            }
        }
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Individual payment term row
    // Individual payment term row
    private func paymentTermRow(_ term: PaymentTerm) -> some View {
        VStack(spacing: 0) {
            HStack {
                // Payment name and percentage
                VStack(alignment: .leading, spacing: 4) {
                    Text(term.name ?? "Payment")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                    
                    Text("\(Int(term.percentage))% of total")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Due date
                Text(term.formattedDueDate)
                    .font(.system(size: 14))
                    .foregroundColor(term.isOverdue && term.status != "Paid" ? .red : secondaryTextColor)
                    .frame(width: 100, alignment: .trailing)
                
                // Amount
                Text(Formatters.formatEuro(term.amount))
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .frame(width: 100, alignment: .trailing)
                
                // Status with action button
                Group {
                    if term.status == "Paid" {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Paid")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .frame(width: 80, alignment: .center)
                    } else {
                        Button(action: {
                            selectedPaymentTerm = term
                            showingRecordPaymentSheet = true
                        }) {
                            Text("Record")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .frame(width: 80, alignment: .center)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                term.status == "Paid"
                    ? (colorScheme == .dark ? Color.green.opacity(0.1) : Color.green.opacity(0.05))
                    : (colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.systemBackground))
            )
            
            // Payment info if paid
            if term.status == "Paid", let date = term.paymentDate {
                // Format date outside of view builder context
                let formattedDate = formatDate(date)
                
                HStack {
                    Text("Paid on \(formattedDate)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    
                    if let reference = term.paymentReference, !reference.isEmpty {
                        Text("•")
                            .foregroundColor(secondaryTextColor)
                        
                        Text("Ref: \(reference)")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Button to undo payment (for administrators)
                    Button(action: {
                        undoPayment(for: term)
                    }) {
                        Text("Undo")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 8)
                .padding(.horizontal, 12)
                .background(
                    colorScheme == .dark ? Color.green.opacity(0.1) : Color.green.opacity(0.05)
                )
            }
            
            Divider()
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
        }
    }

    // Helper function to format a date outside of view builder
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Form for recording a payment
    private func recordPaymentView(for term: PaymentTerm) -> some View {
        Form {
            Section(header: Text("PAYMENT DETAILS")) {
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(Formatters.formatEuro(term.amount))
                        .font(.headline)
                }
                
                DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                
                Picker("Payment Method", selection: $paymentMethod) {
                    ForEach(paymentMethods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                
                TextField("Reference/Transaction ID", text: $paymentReference)
            }
            
            Section(header: Text("NOTES")) {
                TextEditor(text: $paymentNote)
                    .frame(minHeight: 100)
            }
            
            Section {
                Button(action: {
                    recordPayment(for: term)
                }) {
                    HStack {
                        Spacer()
                        Text("Record Payment")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // Record payment for a term
    private func recordPayment(for term: PaymentTerm) {
        term.status = "Paid"
        term.paymentDate = paymentDate
        term.paymentReference = paymentReference
        
        // Create activity log
        ActivityLogger.logActivity(
            type: "PaymentReceived",
            description: "Payment received for \(term.name ?? "payment term")",
            proposal: proposal,
            context: viewContext,
            details: "Amount: \(Formatters.formatEuro(term.amount)), Method: \(paymentMethod), Reference: \(paymentReference)"
        )
        
        do {
            try viewContext.save()
            
            // Reset payment form for next use
            paymentDate = Date()
            paymentReference = ""
            paymentNote = ""
        } catch {
            print("Error recording payment: \(error)")
        }
    }
    
    // Undo payment for a term
    private func undoPayment(for term: PaymentTerm) {
        term.status = nil
        term.paymentDate = nil
        term.paymentReference = nil
        
        // Log activity
        ActivityLogger.logActivity(
            type: "PaymentReverted",
            description: "Payment reverted for \(term.name ?? "payment term")",
            proposal: proposal,
            context: viewContext
        )
        
        do {
            try viewContext.save()
        } catch {
            print("Error undoing payment: \(error)")
        }
    }
    
    // Helpers
    
    // Calculate payment progress (0.0 to 1.0)
    private var paymentProgress: CGFloat {
        if proposal.totalAmount <= 0 {
            return 0
        }
        return CGFloat(proposal.totalPaidAmount / proposal.totalAmount)
    }
    
    // Color for progress bar
    private var progressBarColor: Color {
        if proposal.isFullyPaid {
            return .green
        } else if proposal.hasOverduePayments {
            return .red
        } else if paymentProgress > 0 {
            return .blue
        } else {
            return .gray
        }
    }
}
