import SwiftUI
import CoreData

struct PaymentTemplatesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var proposal: Proposal
    var onApply: () -> Void
    
    // MARK: - Template Models
    
    // Define the structure for payment templates
    struct PaymentTemplate: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let terms: [TermInfo]
    }
    
    // Define the structure for term information
    struct TermInfo {
        let name: String
        let percentage: Double
        let dueCondition: String?
        let dueDays: Double?
        let description: String? // Added description
    }
    
    // Define payment term templates
    let templates = [
        PaymentTemplate(
            name: "50/50 Split",
            description: "50% upfront, 50% upon completion",
            terms: [
                TermInfo(name: "Initial Payment", percentage: 50, dueCondition: "Upon signing", dueDays: nil, description: "50% pre-payment"),
                TermInfo(name: "Final Payment", percentage: 50, dueCondition: nil, dueDays: 30, description: "50% upon project completion")
            ]
        ),
        PaymentTemplate(
            name: "30/70 Split",
            description: "30% upfront, 70% upon completion",
            terms: [
                TermInfo(name: "Deposit", percentage: 30, dueCondition: "Upon signing", dueDays: nil, description: "30% pre-payment"),
                TermInfo(name: "Final Payment", percentage: 70, dueCondition: nil, dueDays: 30, description: "70% upon project completion")
            ]
        ),
        PaymentTemplate(
            name: "Progressive",
            description: "Three-stage payment plan",
            terms: [
                TermInfo(name: "Deposit", percentage: 20, dueCondition: "Upon signing", dueDays: nil, description: "20% pre-payment"),
                TermInfo(name: "Progress Payment", percentage: 30, dueCondition: "Upon delivery", dueDays: nil, description: "30% after delivery"),
                TermInfo(name: "Final Payment", percentage: 50, dueCondition: nil, dueDays: 30, description: "50% upon project completion")
            ]
        ),
        PaymentTemplate(
            name: "Milestone-Based",
            description: "Payments tied to project milestones",
            terms: [
                TermInfo(name: "Project Start", percentage: 25, dueCondition: "Upon signing", dueDays: nil, description: "25% at project start"),
                TermInfo(name: "Design Approval", percentage: 25, dueCondition: "Upon design approval", dueDays: nil, description: "25% after design approval"),
                TermInfo(name: "Implementation", percentage: 25, dueCondition: "Upon implementation", dueDays: nil, description: "25% after implementation"),
                TermInfo(name: "Final Delivery", percentage: 25, dueCondition: "Upon final delivery", dueDays: nil, description: "25% upon final delivery")
            ]
        ),
        PaymentTemplate(
            name: "Monthly Installments",
            description: "Equal monthly payments",
            terms: [
                TermInfo(name: "First Month", percentage: 25, dueCondition: "First installment", dueDays: nil, description: "25% first installment"),
                TermInfo(name: "Second Month", percentage: 25, dueCondition: nil, dueDays: 30, description: "25% second installment"),
                TermInfo(name: "Third Month", percentage: 25, dueCondition: nil, dueDays: 60, description: "25% third installment"),
                TermInfo(name: "Final Month", percentage: 25, dueCondition: nil, dueDays: 90, description: "25% final installment")
            ]
        )
    ]
    
    // MARK: - Main View
    
    var body: some View {
        List {
            ForEach(templates) { template in
                TemplateCard(
                    template: template,
                    proposal: proposal,
                    onApply: {
                        applyTemplate(template)
                        onApply()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Payment Templates")
    }
    
    // MARK: - Template Application
    
    private func applyTemplate(_ template: PaymentTemplate) {
        // First delete existing payment terms
        let existingTerms = fetchExistingTerms()
        for term in existingTerms {
            viewContext.delete(term)
        }
        
        // Create new terms from template
        for termInfo in template.terms {
            let term = PaymentTerm(context: viewContext)
            term.id = UUID()
            term.name = termInfo.name
            term.percentage = termInfo.percentage
            term.amount = proposal.totalAmount * (termInfo.percentage / 100)
            term.descriptionText = termInfo.description // Make sure to set the description text
            term.proposal = proposal
            
            if let condition = termInfo.dueCondition {
                term.dueCondition = condition
                term.dueDays = 0
                term.dueDate = nil
            } else if let days = termInfo.dueDays {
                term.dueCondition = nil
                term.dueDays = days
                // For Monthly Installments, set a more descriptive condition
                if template.name == "Monthly Installments" && termInfo.name.contains("Month") {
                    if termInfo.name.contains("First") {
                        term.dueCondition = "First installment"
                    } else if termInfo.name.contains("Second") {
                        term.dueCondition = "Second installment"
                    } else if termInfo.name.contains("Third") {
                        term.dueCondition = "Third installment"
                    } else if termInfo.name.contains("Final") {
                        term.dueCondition = "Final installment"
                    }
                }
                term.dueDate = nil
            }
        }
        
        // Save the changes
        do {
            try viewContext.save()
            
            // Log activity
            ActivityLogger.logProposalUpdated(
                proposal: proposal,
                context: viewContext,
                fieldChanged: "Payment Terms Template"
            )
        } catch {
            print("Error applying payment template: \(error)")
        }
    }
    
    private func fetchExistingTerms() -> [PaymentTerm] {
        let fetchRequest: NSFetchRequest<PaymentTerm> = PaymentTerm.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "proposal == %@", proposal)
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching existing terms: \(error)")
            return []
        }
    }
}

// Template card component
struct TemplateCard: View {
    let template: PaymentTemplatesView.PaymentTemplate
    let proposal: Proposal
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text(template.name)
                .font(.headline)
            
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 4)
            
            // Terms preview
            ForEach(template.terms.indices, id: \.self) { index in
                let term = template.terms[index]
                HStack {
                    Text("\(term.name): \(Int(term.percentage))%")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    if let condition = term.dueCondition {
                        Text(condition)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let days = term.dueDays {
                        Text("Net \(Int(days)) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Show amount for each term
                let amount = proposal.totalAmount * (term.percentage / 100)
                Text(formatCurrency(amount))
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                if index < template.terms.count - 1 {
                    Divider()
                        .padding(.vertical, 2)
                }
            }
            
            // Apply button
            Button(action: onApply) {
                Text("Apply Template")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}
