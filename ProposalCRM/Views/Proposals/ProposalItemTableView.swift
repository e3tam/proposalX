// EnhancedProductTableView.swift
// Comprehensive table view for displaying proposal items with all requested columns

import SwiftUI

struct EnhancedProductTableView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var proposal: Proposal
    
    // Whether the table should be scrollable horizontally
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with column titles - Scrollable header
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    // Fixed columns
                    Group {
                        Text("Product Name")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 150, alignment: .leading)
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
                }
                .padding(.vertical, 5)
                .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray5))
                .cornerRadius(6)
            }
            
            if proposal.itemsArray.isEmpty {
                HStack {
                    Spacer()
                    Text("No products added yet")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                // Scrollable table rows
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(proposal.itemsArray, id: \.self) { item in
                            VStack(spacing: 0) {
                                // Row
                                ScrollView(.horizontal, showsIndicators: true) {
                                    HStack(spacing: 0) {
                                        // Fixed columns
                                        Group {
                                            Text(item.productName)
                                                .font(.system(size: 14))
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.horizontal, 5)
                                                .lineLimit(1)
                                            
                                            Divider().frame(height: 30)
                                            
                                            Text("\(Int(item.quantity))")
                                                .font(.system(size: 14))
                                                .frame(width: 40, alignment: .center)
                                            
                                            Divider().frame(height: 30)
                                        }
                                        
                                        // Calculated columns
                                        Group {
                                            // Unit partner price
                                            let unitPartnerPrice = item.product?.partnerPrice ?? 0
                                            Text(formatPrice(unitPartnerPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Unit list price
                                            let unitListPrice = item.product?.listPrice ?? 0
                                            Text(formatPrice(unitListPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Multiplier (estimating from unit price and list price)
                                            let estimatedMultiplier = unitListPrice > 0 ?
                                                (item.unitPrice / unitListPrice) * (1 + item.discount/100) : 1.0
                                            Text(String(format: "%.2f", estimatedMultiplier))
                                                .font(.system(size: 14))
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Discount
                                            // For the formula discount = unit partner price / unit list price
                                            // (I think there might be a formula error - typically discount would be (1 - partner/list) * 100)
                                            // Using the formula provided
                                            let calculatedDiscount = unitListPrice > 0 ?
                                                (unitPartnerPrice / unitListPrice) * 100 : 0
                                            Text(String(format: "%.1f%%", calculatedDiscount))
                                                .font(.system(size: 14))
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Extended partner price
                                            let extPartnerPrice = unitPartnerPrice * item.quantity
                                            Text(formatPrice(extPartnerPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Extended list price
                                            let extListPrice = unitListPrice * item.quantity
                                            Text(formatPrice(extListPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Extended customer price
                                            let extCustomerPrice = item.amount
                                            Text(formatPrice(extCustomerPrice))
                                                .font(.system(size: 14))
                                                .frame(width: 120, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Total profit
                                            let totalProfit = extCustomerPrice - extPartnerPrice
                                            Text(formatPrice(totalProfit))
                                                .font(.system(size: 14))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.horizontal, 5)
                                                .foregroundColor(totalProfit >= 0 ? .green : .red)
                                            
                                            Divider().frame(height: 30)
                                            
                                            // Custom tax (assuming not applied by default)
                                            Text("No")
                                                .font(.system(size: 14))
                                                .frame(width: 90, alignment: .center)
                                                .padding(.horizontal, 5)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color.white)
                                }
                                
                                Divider()
                            }
                        }
                    }
                }
                .frame(height: min(CGFloat(proposal.itemsArray.count) * 50, 400))
            }
        }
    }
    
    private func formatPrice(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}

struct EnhancedProductTableView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let proposal = Proposal(context: context)
        proposal.id = UUID()
        proposal.number = "PROP-20250416-001"
        proposal.status = "Draft"
        
        return EnhancedProductTableView(proposal: proposal)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
