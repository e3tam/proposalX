// ProductTableView.swift
// Enhanced table view for displaying proposal items with proper scrolling and multiline product names

import SwiftUI
import CoreData

struct ProductTableView: View {
    @ObservedObject var proposal: Proposal
    let onDelete: (ProposalItem) -> Void
    let onEdit: (ProposalItem) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Color properties for consistent appearance
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.1) : Color(UIColor.tertiarySystemBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color(UIColor.secondarySystemBackground)
    }
    
    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.systemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Horizontal scrollable header
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    // Fixed columns
                    Group {
                        Text("Product Name")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 200, alignment: .leading)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Qty")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 40, alignment: .center)
                        
                        Divider().frame(height: 30)
                    }
                    
                    // Scrollable columns
                    Group {
                        Text("Unit Partner Price")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Unit List Price")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Multiplier")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 80, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Discount")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 80, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Ext Partner Price")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Ext List Price")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Ext Customer Price")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 120, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Total Profit")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.horizontal, 5)
                        
                        Divider().frame(height: 30)
                        
                        Text("Custom Tax?")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 90, alignment: .center)
                            .padding(.horizontal, 5)
                    }
                    
                    // Add Actions header with same spacing as in rows
                    Divider().frame(height: 30)
                    
                    Text("Actions")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 100, alignment: .center)
                        .padding(.horizontal, 5)
                }
                .padding(.vertical, 5)
                .background(headerBackgroundColor)
                .cornerRadius(6)
                .foregroundColor(primaryTextColor)
            }
            
            if proposal.itemsArray.isEmpty {
                emptyProductsView
            } else {
                // Scrollable table content with rows
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(proposal.itemsArray, id: \.self) { item in
                            ZStack {
                                // Main row in ScrollView
                                ScrollView(.horizontal, showsIndicators: true) {
                                    HStack(spacing: 0) {
                                        // Fixed columns
                                        Group {
                                            // Enhanced product name with multiline support
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.productName)
                                                    .font(.system(size: 14))
                                                    .lineLimit(3)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .padding(.vertical, 2)
                                                    .frame(width: 200, alignment: .leading)
                                                    .multilineTextAlignment(.leading)
                                                    .foregroundColor(primaryTextColor)
                                                    
                                                if let code = item.product?.code, !code.isEmpty {
                                                    Text(code)
                                                        .font(.caption)
                                                        .foregroundColor(secondaryTextColor)
                                                }
                                            }
                                            .frame(width: 200, alignment: .leading)
                                            .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 65)
                                            
                                            Text("\(Int(item.quantity))")
                                                .font(.system(size: 14))
                                                .frame(width: 40, alignment: .center)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                        }
                                        
                                        // Calculated columns
                                        Group {
                                            // Unit partner price
                                            let unitPartnerPrice = item.product?.partnerPrice ?? 0
                                            Text(Formatters.formatEuro(unitPartnerPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Unit list price
                                            let unitListPrice = item.product?.listPrice ?? 0
                                            Text(Formatters.formatEuro(unitListPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Multiplier
                                            let estimatedMultiplier = item.multiplier
                                            Text(String(format: "%.2f", estimatedMultiplier))
                                                .font(.system(size: 14))
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Discount
                                            Text(String(format: "%.1f%%", item.discount))
                                                .font(.system(size: 14))
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Extended partner price
                                            let extPartnerPrice = unitPartnerPrice * item.quantity
                                            Text(Formatters.formatEuro(extPartnerPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Extended list price
                                            let extListPrice = unitListPrice * item.quantity
                                            Text(Formatters.formatEuro(extListPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Extended customer price
                                            let extCustomerPrice = item.amount
                                            Text(Formatters.formatEuro(extCustomerPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 120, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(primaryTextColor)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Total profit
                                            let totalProfit = extCustomerPrice - extPartnerPrice
                                            Text(Formatters.formatEuro(totalProfit))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(totalProfit >= 0 ? .green : .red)
                                            
                                            Divider().frame(height: 65)
                                            
                                            // Custom tax
                                            Text(item.applyCustomTax ? "Yes" : "No")
                                                .font(.system(size: 14))
                                                .foregroundColor(item.applyCustomTax ? .green : secondaryTextColor)
                                                .frame(width: 90, alignment: .center)
                                                .padding(.horizontal, 5)
                                        }
                                        
                                        // Placeholder for action buttons width
                                        Divider().frame(height: 65)
                                        Spacer().frame(width: 100)
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                // Action buttons positioned at the end of the row
                                HStack {
                                    Spacer()
                                    
                                    // Action buttons - always visible
                                    HStack(spacing: 15) {
                                        Button(action: { onEdit(item) }) {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: { onDelete(item) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .frame(width: 100, alignment: .center)
                                    .padding(.horizontal, 5)
                                    .background(rowBackgroundColor)
                                }
                            }
                            .background(rowBackgroundColor)
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                        }
                        
                        // Total row
                        HStack {
                            Spacer()
                            Text("Total Products")
                                .fontWeight(.bold)
                                .foregroundColor(primaryTextColor)
                            
                            Text(Formatters.formatEuro(proposal.subtotalProducts))
                                .fontWeight(.bold)
                                .foregroundColor(primaryTextColor)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(headerBackgroundColor)
                    }
                }
                .frame(height: min(CGFloat(proposal.itemsArray.count) * 85 + 40, 400))
            }
        }
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Empty state view
    private var emptyProductsView: some View {
        Text("No products added yet")
            .foregroundColor(secondaryTextColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
    }
}
