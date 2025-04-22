// File: ProposalCRM/Views/Products/ProductTableView.swift
// Displays the table of products within a proposal detail view.
// CORRECTED: Ensures non-optional item.productCode is handled correctly.

import SwiftUI
import CoreData

// MARK: - Main Product Table View
struct ProductTableView: View {
    @ObservedObject var proposal: Proposal
    let onDelete: (ProposalItem) -> Void
    let onEdit: (ProposalItem) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            ProductTableHeader() // Uses HeaderCell internally

            Divider().background(Color.gray)

            // Main table content with rows
            if proposal.itemsArray.isEmpty {
                EmptyProductsView()
            } else {
                ProductRowsView(
                    proposal: proposal,
                    onDelete: onDelete,
                    onEdit: onEdit
                )
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Empty State View
struct EmptyProductsView: View {
    var body: some View {
        Text("No products added yet")
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.2))
    }
}

// MARK: - Table Header - Uses HeaderCell
struct ProductTableHeader: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                HeaderCell(title: "Product Name", width: 180, alignment: .leading)
                VerticalDivider()
                HeaderCell(title: "Qty", width: 50, alignment: .center)
                VerticalDivider()
                HeaderCell(title: "Unit Partner Price", width: 120, alignment: .trailing)
                VerticalDivider()
                HeaderCell(title: "Unit List Price", width: 120, alignment: .trailing)
                VerticalDivider()
                HeaderCell(title: "Multiplier", width: 80, alignment: .center)
                VerticalDivider()
                HeaderCell(title: "Discount", width: 80, alignment: .center)
                VerticalDivider()
                HeaderCell(title: "Ext Partner Price", width: 120, alignment: .trailing)
                VerticalDivider()
                HeaderCell(title: "Ext List Price", width: 120, alignment: .trailing)
                VerticalDivider()
                HeaderCell(title: "Ext Customer Price", width: 120, alignment: .trailing)
                VerticalDivider()
                HeaderCell(title: "Total Profit", width: 100, alignment: .trailing)
                VerticalDivider()
                HeaderCell(title: "Custom Tax?", width: 90, alignment: .center) // Assumed based on header
                VerticalDivider()
                HeaderCell(title: "Act", width: 60, alignment: .center)
            }
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))
        }
    }
}

// MARK: - Product Rows View
struct ProductRowsView: View {
    @ObservedObject var proposal: Proposal
    let onDelete: (ProposalItem) -> Void
    let onEdit: (ProposalItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(proposal.itemsArray, id: \.self) { item in
                    ProductRow(
                        item: item,
                        onDelete: onDelete,
                        onEdit: onEdit
                    )
                    Divider().background(Color.gray.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Individual Product Row - Corrected productCode handling
struct ProductRow: View {
    let item: ProposalItem
    let onDelete: (ProposalItem) -> Void
    let onEdit: (ProposalItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                // Product Name & Code
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.productName)
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    // --- CORRECT HANDLING for non-optional productCode ---
                    let code = item.productCode // Directly assign the non-optional String
                    if !code.isEmpty && code != "Unknown Code" { // Check if it's not empty AND not the default placeholder
                        Text(code) // Line 124 (Now inside a standard 'if')
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    // --- End Correct Handling ---

                }
                .frame(width: 180, alignment: .leading)
                .padding(.horizontal, 5)
                VerticalDivider()

                // Quantity
                Text("\(Int(item.quantity))")
                    .font(.system(size: 14))
                    .frame(width: 50, alignment: .center)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Unit Partner Price (Uses extension which now formats)
                Text(item.formattedUnitPartnerPrice)
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Unit List Price (Uses extension which now formats)
                Text(item.formattedUnitListPrice)
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Multiplier (Uses extension which now formats)
                Text(item.formattedMultiplier)
                    .font(.system(size: 14))
                    .frame(width: 80, alignment: .center)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Discount (Uses extension which now formats)
                 Text(Formatters.formatPercent(item.discount)) // Use % formatter directly
                    .font(.system(size: 14))
                    .frame(width: 80, alignment: .center)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Ext Partner Price (Uses extension which now formats)
                Text(item.formattedExtendedPartnerPrice)
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Ext List Price (Uses extension which now formats)
                Text(item.formattedExtendedListPrice)
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Ext Customer Price (Uses extension which now formats)
                Text(item.formattedExtendedCustomerPrice) // Uses item.amount via extension
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Total Profit (Uses extension which now formats)
                Text(item.formattedProfit)
                    .font(.system(size: 14))
                    .foregroundColor(item.calculatedProfit >= 0 ? .green : .red) // Use calculated value for color
                    .frame(width: 100, alignment: .trailing)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Custom Tax?
                Text(item.applyCustomTax ? "Yes" : "No")
                    .font(.system(size: 14))
                    .frame(width: 90, alignment: .center)
                    .padding(.horizontal, 5)
                VerticalDivider()

                // Action buttons
                HStack(spacing: 15) {
                    Button(action: { onEdit(item) }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    Button(action: { onDelete(item) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .frame(width: 60, alignment: .center)
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
        }
    }
}

// MARK: - Reusable Components

struct HeaderCell: View {
    let title: String
    let width: CGFloat
    let alignment: Alignment

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 5)
            .foregroundColor(.white)
    }
}

struct VerticalDivider: View {
    var body: some View {
        Divider()
            .frame(height: 36)
            .background(Color.gray)
            .opacity(0.5)
    }
}
