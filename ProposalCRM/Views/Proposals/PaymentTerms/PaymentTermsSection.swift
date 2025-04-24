import SwiftUI
import CoreData

struct PaymentTermsSection: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditSheet = false
    
    // State for refresh triggers
    @State private var refreshTrigger = UUID()
    
    // MARK: - Dynamic Colors
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.1) : Color(UIColor.tertiarySystemBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color(UIColor.secondarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    // MARK: - Helper Methods for Payment Term Ordering
    
    // Helper function to get month order from a term name
    private func getMonthOrder(_ term: PaymentTerm) -> Int {
        guard let name = term.name?.lowercased() else { return Int.max }
        
        if name.contains("first") {
            return 1
        } else if name.contains("second") {
            return 2
        } else if name.contains("third") {
            return 3
        } else if name.contains("fourth") || name.contains("final") {
            return 4
        }
        
        return Int.max // Unknown month order
    }
    
    // MARK: - Data Properties
    
    // Improved payment terms fetch with proper error handling and refresh capability
    private var paymentTermsArray: [PaymentTerm] {
        // First try to get terms through the relationship
        if let terms = proposal.paymentTerms as? Set<PaymentTerm>, !terms.isEmpty {
            // Sort by due days or creation order to ensure consistent display
            return terms.sorted { term1, term2 in
                // Special handling for monthly installments
                let month1 = getMonthOrder(term1)
                let month2 = getMonthOrder(term2)
                
                // If both terms have month ordering, use that
                if month1 != Int.max && month2 != Int.max {
                    return month1 < month2
                }
                
                // Otherwise sort by due days
                if term1.dueDays != term2.dueDays {
                    return term1.dueDays < term2.dueDays
                }
                
                // Last resort: sort by percentage (higher first)
                return term1.percentage > term2.percentage
            }
        }
        
        // If relationship access fails, use a direct fetch request
        let fetchRequest: NSFetchRequest<PaymentTerm> = PaymentTerm.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "proposal == %@", proposal)
        
        do {
            let terms = try viewContext.fetch(fetchRequest)
            // Apply the same sorting logic
            return terms.sorted { term1, term2 in
                // Special handling for monthly installments
                let month1 = getMonthOrder(term1)
                let month2 = getMonthOrder(term2)
                
                // If both terms have month ordering, use that
                if month1 != Int.max && month2 != Int.max {
                    return month1 < month2
                }
                
                // Otherwise sort by due days
                if term1.dueDays != term2.dueDays {
                    return term1.dueDays < term2.dueDays
                }
                
                // Last resort: sort by percentage (higher first)
                return term1.percentage > term2.percentage
            }
        } catch {
            print("Error fetching payment terms: \(error)")
            return []
        }
    }
    
    // Get payment methods from serialized data
    private var paymentMethods: [String] {
        if let data = proposal.paymentMethodsData,
           let methods = try? JSONDecoder().decode([String].self, from: data) {
            return methods
        }
        return []
    }
    
    // MARK: - Main View
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header with Edit button
            HStack {
                Text("Payment Terms")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingEditSheet = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            // Payment terms content
            paymentTermsContent
        }
        .padding(.horizontal)
        .onAppear {
            // Refresh the view when it appears
            refreshTrigger = UUID()
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            // Refresh the view when sheet is dismissed
            refreshTrigger = UUID()
        }) {
            NavigationView {
                PaymentTermsEditView(proposal: proposal)
                    .navigationTitle("Edit Payment Terms")
            }
        }
        .id(refreshTrigger) // Force view refresh when ID changes
    }
    
    // MARK: - Content Views
    
    // Main content container
    private var paymentTermsContent: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Payment Schedule")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Calculate total percentage for validation
                let totalPercentage = paymentTermsArray.reduce(0.0) { $0 + $1.percentage }
                if totalPercentage != 100 && !paymentTermsArray.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Total: \(Int(totalPercentage))%")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(headerBackgroundColor)
            
            if paymentTermsArray.isEmpty {
                emptyTermsView
            } else {
                termsListView
            }
            
            // Payment methods section
            paymentMethodsSection
        }
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(dividerColor, lineWidth: 1)
        )
    }
    
    // View shown when no payment terms are defined
    private var emptyTermsView: some View {
        Text("No payment terms defined")
            .foregroundColor(secondaryTextColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
    }
    
    // List of payment terms
    private var termsListView: some View {
        VStack(spacing: 0) {
            ForEach(paymentTermsArray, id: \.id) { term in
                VStack(spacing: 0) {
                    // Term details row
                    HStack {
                        // Percentage with emphasized styling
                        Text("\(Int(term.percentage))%")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 50, alignment: .leading)
                        
                        // Term name with proper capitalization
                        Text(term.name ?? "Payment Term")
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        // Equal sign for clearer format
                        Text("=")
                            .foregroundColor(secondaryTextColor)
                            .padding(.horizontal, 4)
                        
                        // Amount in Euro
                        Text(Formatters.formatEuro(term.amount))
                            .font(.headline)
                            .foregroundColor(primaryTextColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    
                    // Description and due date subrow
                    HStack {
                        // Use description text or generate one
                        if let description = term.descriptionText, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        } else {
                            Text(getDetailedDescription(for: term))
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        // Due date information
                        Text(formattedDueDate(for: term))
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    
                    if term != paymentTermsArray.last {
                        Divider()
                            .background(dividerColor)
                    }
                }
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
            }
            
            // Total row
            HStack {
                Text("Total")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Add percentage total
                let totalPercentage = paymentTermsArray.reduce(0.0) { $0 + $1.percentage }
                if totalPercentage != 100 {
                    Text("\(Int(totalPercentage))%")
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                        .padding(.trailing, 4)
                } else {
                    Text("100%")
                        .foregroundColor(primaryTextColor)
                        .fontWeight(.bold)
                        .padding(.trailing, 4)
                }
                
                Text(Formatters.formatEuro(proposal.totalAmount))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(headerBackgroundColor)
        }
    }
    
    // Helper function to get a detailed description for a payment term
    private func getDetailedDescription(for term: PaymentTerm) -> String {
        let percentage = Int(term.percentage)
        
        if let name = term.name?.lowercased() {
            if name.contains("first") {
                return "\(percentage)% first installment"
            } else if name.contains("second") {
                return "\(percentage)% second installment"
            } else if name.contains("third") {
                return "\(percentage)% third installment"
            } else if name.contains("initial") || name.contains("advance") || name.contains("deposit") || name.contains("pre") {
                return "\(percentage)% pre-payment"
            } else if name.contains("delivery") || name.contains("progress") {
                return "\(percentage)% after delivery"
            } else if name.contains("final") || name.contains("complete") {
                return "\(percentage)% upon completion"
            }
        }
        
        return "\(percentage)% of total"
    }
    
    // Helper function to format the due date
    private func formattedDueDate(for term: PaymentTerm) -> String {
        if let dueDate = term.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: dueDate)
        } else if term.dueDays > 0 {
            return "Net \(Int(term.dueDays)) days"
        } else if let dueCondition = term.dueCondition, !dueCondition.isEmpty {
            return dueCondition
        }
        
        return "Due date not specified"
    }
    
    // Payment methods section
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Methods:")
                .font(.headline)
                .foregroundColor(primaryTextColor)
                .padding(.top, 16)
            
            if paymentMethods.isEmpty {
                Text("No payment methods specified")
                    .foregroundColor(secondaryTextColor)
                    .padding(.vertical, 4)
            } else {
                ForEach(paymentMethods, id: \.self) { method in
                    HStack(spacing: 10) {
                        Image(systemName: paymentMethodIcon(method))
                            .foregroundColor(.blue)
                        
                        Text(method)
                            .foregroundColor(primaryTextColor)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Payment notes if available
            if let notes = proposal.paymentNotes, !notes.isEmpty {
                Divider()
                    .background(dividerColor)
                    .padding(.vertical, 8)
                
                Text("Notes:")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                
                Text(notes)
                    .foregroundColor(primaryTextColor)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
    
    // MARK: - Helper Methods
    
    // Get icon for payment method
    private func paymentMethodIcon(_ method: String) -> String {
        switch method.lowercased() {
        case "bank transfer", "wire transfer", "bank":
            return "building.columns.fill"
        case "credit card", "card":
            return "creditcard.fill"
        case "cash":
            return "banknote.fill"
        case "paypal":
            return "p.circle.fill"
        case "check", "cheque":
            return "doc.text.fill"
        case "mobile payment":
            return "iphone"
        default:
            return "euro.circle.fill"
        }
    }
}
