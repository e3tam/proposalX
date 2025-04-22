//
//  ExpensesTableSection.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// ExpensesTableSection.swift
// Section for displaying expenses in proposal detail view

import SwiftUI

struct ExpensesTableSection: View {
    let proposal: Proposal
    let onAdd: () -> Void
    let onEdit: (Expense) -> Void
    let onDelete: (Expense) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Expenses")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !proposal.expensesArray.isEmpty {
                    Text("(\(proposal.expensesArray.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            // Expenses table view
            if proposal.expensesArray.isEmpty {
                emptyExpensesView()
            } else {
                expensesTableView()
            }
        }
        .padding(.horizontal)
    }
    
    private func emptyExpensesView() -> some View {
        Text("No expenses added yet")
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.15))
            .cornerRadius(10)
    }
    
    private func expensesTableView() -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("Description")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                
                Text("Amount (€)")
                    .frame(width: 150, alignment: .trailing)
                
                Text("Actions")
                    .frame(width: 100, alignment: .center)
                    .padding(.trailing, 8)
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Expense rows
            ForEach(proposal.expensesArray, id: \.self) { expense in
                HStack(spacing: 0) {
                    Text(expense.desc ?? "No description")
                        .font(.system(size: 14))
                        .lineLimit(2)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    
                    Text(Formatters.formatEuro(expense.amount))
                        .font(.system(size: 14))
                        .frame(width: 150, alignment: .trailing)
                    
                    HStack(spacing: 10) {
                        Button(action: { onEdit(expense) }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { onDelete(expense) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(width: 100, alignment: .center)
                    .padding(.trailing, 8)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                
                Divider().background(Color.gray.opacity(0.3))
            }
            
            // Total row
            HStack(spacing: 0) {
                Text("Total Expenses")
                    .fontWeight(.bold)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 8)
                
                Text(Formatters.formatEuro(proposal.subtotalExpenses))
                    .fontWeight(.bold)
                    .frame(width: 150, alignment: .trailing)
                
                Spacer()
                    .frame(width: 100)
                    .padding(.trailing, 8)
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
        }
        .background(Color.black.opacity(0.15))
        .cornerRadius(10)
    }
}