//
//  CustomTaxesTableSection.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// CustomTaxesTableSection.swift
// Section for displaying custom taxes in proposal detail view

import SwiftUI

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
            
            // Taxes table view
            if proposal.taxesArray.isEmpty {
                emptyTaxesView()
            } else {
                taxesTableView()
            }
        }
        .padding(.horizontal)
    }
    
    private func emptyTaxesView() -> some View {
        Text("No custom taxes added yet")
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.15))
            .cornerRadius(10)
    }
    
    private func taxesTableView() -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("Tax Name")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                
                Text("Rate (%)")
                    .frame(width: 100, alignment: .center)
                
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
            
            // Tax rows
            ForEach(proposal.taxesArray, id: \.self) { tax in
                HStack(spacing: 0) {
                    Text(tax.name ?? "Unnamed Tax")
                        .font(.system(size: 14))
                        .lineLimit(2)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    
                    Text(String(format: "%.1f%%", tax.rate))
                        .font(.system(size: 14))
                        .frame(width: 100, alignment: .center)
                    
                    Text(Formatters.formatEuro(tax.amount))
                        .font(.system(size: 14))
                        .frame(width: 150, alignment: .trailing)
                    
                    HStack(spacing: 10) {
                        Button(action: { onEdit(tax) }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { onDelete(tax) }) {
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
                Text("Total Taxes")
                    .fontWeight(.bold)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 8)
                
                Text(Formatters.formatEuro(proposal.subtotalTaxes))
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