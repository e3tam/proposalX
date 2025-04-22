import SwiftUI
struct FinancialSummarySection: View {
    @ObservedObject var proposal: Proposal
    var onViewDetails: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.secondarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Financial Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: onViewDetails) {
                    Label("View Details", systemImage: "chart.pie.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Summary card background
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                
                VStack(spacing: 15) {
                    // Revenue components
                    Group {
                        Text("REVENUE")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        summaryRow(title: "Products Subtotal", value: proposal.subtotalProducts)
                        summaryRow(title: "Engineering Subtotal", value: proposal.subtotalEngineering)
                        summaryRow(title: "Expenses Subtotal", value: proposal.subtotalExpenses)
                        summaryRow(title: "Custom Taxes", value: proposal.subtotalTaxes)
                    }
                    
                    Divider()
                        .background(colorScheme == .dark ? Color.gray : Color.gray.opacity(0.5))
                    
                    // Total revenue
                    summaryRow(
                        title: "TOTAL REVENUE",
                        value: proposal.totalAmount,
                        titleColor: primaryTextColor,
                        valueColor: primaryTextColor,
                        isBold: true
                    )
                    
                    Divider()
                        .background(colorScheme == .dark ? Color.gray : Color.gray.opacity(0.5))
                    
                    // COST STRUCTURE
                    Group {
                        Text("COST STRUCTURE")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Partner Cost for products
                        let partnerCost = calculatePartnerCost()
                        summaryRow(title: "Partner Product Costs", value: partnerCost)
                        
                        // Expenses are considered costs
                        summaryRow(title: "Expenses", value: proposal.subtotalExpenses)
                        
                        // Custom taxes are now included as costs
                        summaryRow(title: "Custom Taxes", value: proposal.subtotalTaxes)
                    }
                    
                    Divider()
                        .background(colorScheme == .dark ? Color.gray : Color.gray.opacity(0.5))
                    
                    // Total cost
                    let totalCost = proposal.totalCost
                    summaryRow(
                        title: "TOTAL COST",
                        value: totalCost,
                        titleColor: primaryTextColor,
                        valueColor: primaryTextColor,
                        isBold: true
                    )
                    
                    Divider()
                        .background(colorScheme == .dark ? Color.gray : Color.gray.opacity(0.5))
                    
                    // Profit analysis
                    let grossProfit = proposal.totalAmount - totalCost
                    let profitMargin = proposal.totalAmount > 0 ? (grossProfit / proposal.totalAmount) * 100 : 0
                    
                    summaryRow(
                        title: "Gross Profit",
                        value: grossProfit,
                        valueColor: grossProfit >= 0 ? .green : .red
                    )
                    summaryRow(
                        title: "Profit Margin",
                        value: profitMargin,
                        valueFormatter: { String(format: "%.1f%%", $0) },
                        valueColor: profitMargin >= 30 ? .green : (profitMargin >= 15 ? .blue : .red)
                    )
                }
                .padding()
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
    }
    
    private func summaryRow(
        title: String,
        value: Double,
        valueFormatter: (Double) -> String = { Formatters.formatEuro($0) },
        titleColor: Color? = nil,
        valueColor: Color? = nil,
        isBold: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(isBold ? .headline : .subheadline)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(titleColor ?? secondaryTextColor)
            
            Spacer()
            
            Text(valueFormatter(value))
                .font(isBold ? .headline : .subheadline)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(valueColor ?? primaryTextColor)
        }
    }
    
    private func calculatePartnerCost() -> Double {
        var totalCost = 0.0
        
        // Sum partner cost for all products
        for item in proposal.itemsArray {
            if let product = item.product {
                totalCost += product.partnerPrice * item.quantity
            }
        }
        
        return totalCost
    }
}
