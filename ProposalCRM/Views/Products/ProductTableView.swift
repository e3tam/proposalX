// ProductTableView.swift
// Table view for displaying proposal products with pricing information

import SwiftUI
import CoreData

struct ProductTableView: View {
    @ObservedObject var proposal: Proposal
    var onDelete: (ProposalItem) -> Void
    var onEdit: (ProposalItem) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header
            productTableHeader()
            
            if proposal.itemsArray.isEmpty {
                emptyProductsView()
            } else {
                // Table content
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(proposal.itemsArray, id: \.self) { item in
                            ProductTableRow(item: item, onEdit: onEdit, onDelete: onDelete)
                            Divider().background(Color.gray.opacity(0.3))
                        }
                    }
                }
                .background(Color.black.opacity(0.1))
                
                // Totals row
                totalRow()
            }
        }
        .background(Color.black.opacity(0.15))
        .cornerRadius(10)
    }
    
    private func productTableHeader() -> some View {
        HStack(spacing: 0) {
            Text("Product Name")
                .frame(width: 200, alignment: .leading)
                .padding(.leading, 8)
            
            Divider().frame(height: 30)
            
            Text("Qty")
                .frame(width: 60, alignment: .center)
            
            Divider().frame(height: 30)
            
            Text("Unit Partner Price")
                .frame(width: 120, alignment: .trailing)
            
            Divider().frame(height: 30)
            
            Text("Unit List Price")
                .frame(width: 120, alignment: .trailing)
            
            Divider().frame(height: 30)
            
            Text("Multiplier")
                .frame(width: 80, alignment: .trailing)
            
            Divider().frame(height: 30)
            
            Text("Discount")
                .frame(width: 80, alignment: .trailing)
            
            Divider().frame(height: 30)
            
            Text("Ext Partner Price")
                .frame(width: 120, alignment: .trailing)
            
            Divider().frame(height: 30)
            
            Text("Ext List Price")
                .frame(width: 120, alignment: .trailing)
            
            Divider().frame(height: 30)
            
            Text("Ext Customer")
                .frame(width: 120, alignment: .trailing)
                .padding(.trailing, 8)
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
    
    private func emptyProductsView() -> some View {
        Text("No products added yet")
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.1))
    }
    
    private func totalRow() -> some View {
        HStack(spacing: 0) {
            Text("Total Products")
                .fontWeight(.bold)
                .frame(width: 680, alignment: .trailing)
                .padding(.leading, 8)
            
            Divider().frame(height: 30)
            
            Text(Formatters.formatEuro(proposal.subtotalProducts))
                .fontWeight(.bold)
                .frame(width: 120, alignment: .trailing)
                .padding(.trailing, 8)
        }
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.4))
    }
}

struct ProductTableRow: View {
    @ObservedObject var item: ProposalItem
    var onEdit: (ProposalItem) -> Void
    var onDelete: (ProposalItem) -> Void
    
    var body: some View {
        Button(action: { onEdit(item) }) {
            HStack(spacing: 0) {
                // Product Name
                Text(item.product?.name ?? "Unknown Product")
                    .lineLimit(2)
                    .font(.system(size: 14))
                    .frame(width: 200, alignment: .leading)
                    .padding(.leading, 8)
                
                Divider().frame(height: 40)
                
                // Quantity
                Text("\(Int(item.quantity))")
                    .font(.system(size: 14))
                    .frame(width: 60, alignment: .center)
                
                Divider().frame(height: 40)
                
                // Unit Partner Price
                Text(item.product != nil ? Formatters.formatEuro(item.product!.partnerPrice) : "-")
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                
                Divider().frame(height: 40)
                
                // Unit List Price
                Text(item.product != nil ? Formatters.formatEuro(item.product!.listPrice) : "-")
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                
                Divider().frame(height: 40)
                
                // Multiplier
                let multiplier = item.product?.listPrice ?? 0 > 0 ? item.unitPrice / (item.product?.listPrice ?? 1) : 0
                Text(String(format: "%.2f", multiplier))
                    .font(.system(size: 14))
                    .frame(width: 80, alignment: .trailing)
                
                Divider().frame(height: 40)
                
                // Discount
                Text("\(String(format: "%.1f", item.discount))%")
                    .font(.system(size: 14))
                    .frame(width: 80, alignment: .trailing)
                
                Divider().frame(height: 40)
                
                // Extended Partner Price
                let extPartnerPrice = (item.product?.partnerPrice ?? 0) * item.quantity
                Text(Formatters.formatEuro(extPartnerPrice))
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                
                Divider().frame(height: 40)
                
                // Extended List Price
                let extListPrice = (item.product?.listPrice ?? 0) * item.quantity
                Text(Formatters.formatEuro(extListPrice))
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .trailing)
                
                Divider().frame(height: 40)
                
                // Extended Customer Price (Amount)
                Text(Formatters.formatEuro(item.amount))
                    .font(.system(size: 14))
                    .frame(width: 100, alignment: .trailing)
                
                // Edit/Delete buttons
                HStack(spacing: 4) {
                    Button(action: { onEdit(item) }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .padding(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { onDelete(item) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 20, alignment: .center)
                .padding(.trailing, 8)
            }
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.2))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
