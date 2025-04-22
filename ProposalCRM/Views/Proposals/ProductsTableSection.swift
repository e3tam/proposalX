// Modifications for ProductsTableSection.swift
// Maintain the same interface while improving visual consistency
import SwiftUI
struct ProductsTableSection: View {
    let proposal: Proposal
    let onAdd: () -> Void
    let onEdit: (ProposalItem) -> Void
    let onDelete: (ProposalItem) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Add color properties for consistency
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Products")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                if !proposal.itemsArray.isEmpty {
                    Text("(\(proposal.itemsArray.count))")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add Products", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            // This calls the improved ProductTableView with better alignment
            ProductTableView(
                proposal: proposal,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
    }
}
