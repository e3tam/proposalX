// ProductsTableSection.swift
// Wrapper for ProductTableView with header and actions

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
                
                if !proposal.itemsArray.isEmpty {
                    Text("(\(proposal.itemsArray.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add Products", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            // This is where we use our improved ProductTableView
            ProductTableView(
                proposal: proposal,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
    }
}
