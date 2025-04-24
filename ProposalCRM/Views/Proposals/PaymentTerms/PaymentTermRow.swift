import SwiftUI

struct PaymentTermRow: View {
    let term: PaymentTerm
    let totalAmount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row with percentage and name
            HStack {
                Text("\(Int(term.percentage))%")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(width: 50, alignment: .leading)
                
                Text(term.name ?? "Payment Term")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Amount for this term
                Text(Formatters.formatEuro(term.amount))
                    .font(.headline)
            }
            
            // Description and due date details
            HStack {
                Text(getPaymentDescription())
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Spacer()
                
                Text(formattedDueDate)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
    
    // Get a human-readable payment description
    private func getPaymentDescription() -> String {
        // First use the descriptionText if available
        if let desc = term.descriptionText, !desc.isEmpty {
            return desc
        }
        
        let percentage = Int(term.percentage)
        if let name = term.name?.lowercased() {
            if name.contains("initial") || name.contains("advance") || name.contains("deposit") || name.contains("pre") {
                return "\(percentage)% pre-payment"
            } else if name.contains("delivery") || name.contains("progress") {
                return "\(percentage)% after delivery"
            } else if name.contains("final") || name.contains("complete") {
                return "\(percentage)% upon completion"
            }
        }
        
        // Generic description based on percentage
        if term.percentage <= 30 {
            return "\(percentage)% initial payment"
        } else if term.percentage >= 70 {
            return "\(percentage)% final payment"
        } else {
            return "\(percentage)% progress payment"
        }
    }
    
    // Format the due date based on type
    private var formattedDueDate: String {
        if let dueDate = term.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "Due: \(formatter.string(from: dueDate))"
        } else if term.dueDays > 0 {
            return "Net \(Int(term.dueDays)) days"
        } else if let dueCondition = term.dueCondition, !dueCondition.isEmpty {
            return dueCondition
        } else {
            return "Due date not specified"
        }
    }
}
