// ProductsTableSection.swift
// Properly connects to the refactored ProductTableView

import SwiftUI

import SwiftUI

struct ProductsTableSection: View {
    let proposal: Proposal
    let onAdd: () -> Void
    let onEdit: (ProposalItem) -> Void
    let onDelete: (ProposalItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Products")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add Products", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            // This is where we use our custom ProductTableView
            ProductTableView(
                proposal: proposal,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
    }
}



// This implementation can stay in the same file as ProductsTableSection
// or you can move it to its own file
struct EngineeringTableSection: View {
    let proposal: Proposal
    let onAdd: () -> Void
    let onEdit: (Engineering) -> Void
    let onDelete: (Engineering) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Engineering")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !proposal.engineeringArray.isEmpty {
                    Text("(\(proposal.engineeringArray.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            EngineeringTableView(
                proposal: proposal,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
    }
}

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
            
            ExpensesTableView(
                proposal: proposal,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
    }
}

struct CustomTaxesTableSection: View {
    let proposal: Proposal
    let onAdd: () -> Void
    let onEdit: (CustomTax) -> Void
    let onDelete: (CustomTax) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Custom Taxes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !proposal.taxesArray.isEmpty {
                    Text("(\(proposal.taxesArray.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            CustomTaxesTableView(
                proposal: proposal,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
    }
}
