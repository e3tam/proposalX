import SwiftUI
import CoreData

struct ExpensesTableView: View {
    @ObservedObject var proposal: Proposal
    let onDelete: (Expense) -> Void
    let onEdit: (Expense) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Optimize by caching categories from UserDefaults
    @State private var categoryCache: [String: String] = [:]
    @State private var loadingState = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header with simpler styling
            HStack(spacing: 0) {
                Text("Description")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                
                Text("Amount (€)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 100, alignment: .trailing)
                    .padding(.trailing, 5)
                
                Text("Actions")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 70, alignment: .center)
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Table content - either empty state or filled rows
            Group {
                if proposal.expensesArray.isEmpty {
                    Text("No expenses added yet")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.2))
                } else {
                    // Use LazyVStack for better performance with many items
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: []) {
                            ForEach(proposal.expensesArray, id: \.self) { expense in
                                OptimizedExpenseRowView(
                                    expense: expense,
                                    categoryCache: $categoryCache,
                                    onEdit: onEdit,
                                    onDelete: onDelete
                                )
                            }
                        }
                    }
                    
                    // Total summary row
                    HStack(spacing: 0) {
                        Text("Total Expenses")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 10)
                        
                        Text(Formatters.formatEuro(proposal.subtotalExpenses))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.trailing, 5)
                        
                        Spacer()
                            .frame(width: 70)
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                }
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            // Pre-cache categories for better performance
            loadCategories()
        }
    }
    
    private func loadCategories() {
        // Load categories from UserDefaults for all expenses
        loadingState = true
        let defaults = UserDefaults.standard
        
        for expense in proposal.expensesArray {
            if let id = expense.id?.uuidString {
                let expenseKey = "expense_\(id)"
                if let category = defaults.string(forKey: "\(expenseKey)_category") {
                    categoryCache[id] = category
                }
            }
        }
        
        loadingState = false
    }
}

// Optimized row component with cached category information
struct OptimizedExpenseRowView: View {
    let expense: Expense
    @Binding var categoryCache: [String: String]
    let onEdit: (Expense) -> Void
    let onDelete: (Expense) -> Void
    
    // Cached properties for better performance
    private var expenseId: String {
        expense.id?.uuidString ?? ""
    }
    
    private var category: String {
        categoryCache[expenseId] ?? "Other"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { onEdit(expense) }) {
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(expense.desc ?? "No Description")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Use cached category for better performance
                        Text(category)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    
                    Text(Formatters.formatEuro(expense.amount))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: .trailing)
                        .padding(.trailing, 5)
                    
                    HStack(spacing: 8) {
                        Button(action: { onEdit(expense) }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: { onDelete(expense) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .frame(width: 70, alignment: .center)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.2))
            
            Divider()
                .frame(height: 1)
                .background(Color.gray.opacity(0.3))
        }
    }
}

// A helper view to show a breakdown of expenses by category
// Can be used elsewhere in the app if categories are tracked
struct ExpenseBreakdownView: View {
    let expenses: [Expense]
    
    // This would need a way to get categories from expenses
    // For now we'll simulate with a manual calculation
    func calculateBreakdown() -> [(category: String, amount: Double)] {
        // This is a placeholder. In a real implementation with categories in the model:
        // let categories = Dictionary(grouping: expenses, by: { $0.category ?? "Other" })
        // return categories.map { (category, items) in
        //    (category, items.reduce(0) { $0 + $1.amount })
        // }.sorted { $0.amount > $1.amount }
        
        // Placeholder implementation:
        return [
            ("Services", expenses.reduce(0) { $0 + $1.amount } * 0.4),
            ("Travel", expenses.reduce(0) { $0 + $1.amount } * 0.3),
            ("Materials", expenses.reduce(0) { $0 + $1.amount } * 0.2),
            ("Other", expenses.reduce(0) { $0 + $1.amount } * 0.1)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expense Breakdown")
                .font(.headline)
            
            ForEach(calculateBreakdown(), id: \.category) { item in
                HStack {
                    Text(item.category)
                    Spacer()
                    Text(Formatters.formatEuro(item.amount))
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}
