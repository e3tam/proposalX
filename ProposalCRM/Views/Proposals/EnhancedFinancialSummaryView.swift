import SwiftUI

struct EnhancedFinancialSummaryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var proposal: Proposal
    
    // State variables for interactive elements
    @State private var showingPartnerPriceDetails = false
    @State private var showingTaxDetails = false
    @State private var selectedTab = 0
    
    // Color palette
    private let revenueColor = Color.blue
    private let costColor = Color.red
    private let profitColor = Color.green
    private let secondaryBgColor: Color
    
    // Initialize with proper background color based on color scheme
    init(proposal: Proposal) {
        self.proposal = proposal
        self.secondaryBgColor = Color(UIColor.secondarySystemBackground)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards at the top
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Revenue",
                            amount: proposal.totalAmount,
                            icon: "dollarsign.circle.fill",
                            color: revenueColor
                        )
                        
                        SummaryCard(
                            title: "Cost",
                            amount: proposal.totalCost,
                            icon: "cart.fill",
                            color: costColor
                        )
                        
                        SummaryCard(
                            title: "Profit",
                            amount: proposal.totalAmount - proposal.totalCost,
                            icon: "chart.line.uptrend.xyaxis",
                            color: profitColor
                        )
                    }
                    
                    // Tab view for different sections
                    Picker("View", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Revenue").tag(1)
                        Text("Cost").tag(2)
                        Text("Profit").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        overviewSection
                    } else if selectedTab == 1 {
                        revenueBreakdownSection
                    } else if selectedTab == 2 {
                        costStructureSection
                    } else {
                        profitAnalysisSection
                    }
                }
                .padding()
            }
            .navigationTitle("Financial Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // Overview section combining key elements from all sections
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Financial distribution chart
            VStack(alignment: .leading, spacing: 12) {
                Text("FINANCIAL OVERVIEW")
                    .font(.headline)
                
                // Calculate values for chart
                let totalRevenue = proposal.totalAmount
                let totalCost = proposal.totalCost
                let profit = totalRevenue - totalCost
                
                // Stacked bar or donut chart
                FinancialDistributionChart(
                    revenue: totalRevenue,
                    cost: totalCost
                )
                .frame(height: 200)
                
                // Legend for chart
                HStack(spacing: 24) {
                    ChartLegendItem(color: costColor, label: "Cost", percentage: (totalCost/totalRevenue) * 100)
                    ChartLegendItem(color: profitColor, label: "Profit", percentage: (profit/totalRevenue) * 100)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Key metrics grid
            VStack(alignment: .leading, spacing: 12) {
                Text("KEY METRICS")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    KeyMetricCard(
                        title: "Profit Margin",
                        value: String(format: "%.1f%%", calculateProfitMargin()),
                        icon: "percent",
                        color: profitMarginColor(calculateProfitMargin())
                    )
                    
                    KeyMetricCard(
                        title: "Total Taxes",
                        value: Formatters.formatEuro(proposal.subtotalTaxes),
                        icon: "percent",
                        color: .red
                    )
                    
                    KeyMetricCard(
                        title: "Partner Cost %",
                        value: String(format: "%.1f%%", calculatePartnerCostPercentage()),
                        icon: "cube.box.fill",
                        color: .blue
                    )
                    
                    KeyMetricCard(
                        title: "Tax on Items",
                        value: String(format: "%d of %d", countTaxableItems(), proposal.itemsArray.count),
                        icon: "checkmark.circle",
                        color: .orange
                    )
                }
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Summary table with high-level numbers
            VStack(alignment: .leading, spacing: 12) {
                Text("FINANCIAL SUMMARY")
                    .font(.headline)
                
                summaryRow(title: "Total Revenue", value: proposal.totalAmount, isBold: true)
                Divider()
                summaryRow(title: "Partner Product Costs", value: calculatePartnerCost())
                summaryRow(title: "Expenses", value: proposal.subtotalExpenses)
                summaryRow(title: "Custom Taxes", value: proposal.subtotalTaxes)
                summaryRow(title: "Total Cost", value: proposal.totalCost, isBold: true)
                Divider()
                summaryRow(
                    title: "Gross Profit",
                    value: proposal.totalAmount - proposal.totalCost,
                    isBold: true,
                    valueColor: profitColor
                )
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
        }
    }
    
    // Revenue Breakdown Section
    private var revenueBreakdownSection: some View {
        VStack(spacing: 20) {
            // Main revenue breakdown
            VStack(alignment: .leading, spacing: 16) {
                Text("REVENUE COMPONENTS")
                    .font(.headline)
                    .foregroundColor(revenueColor)
                
                // Revenue donut chart
                RevenueDonutChart(
                    productsRevenue: proposal.subtotalProducts,
                    engineeringRevenue: proposal.subtotalEngineering,
                    expensesRevenue: proposal.subtotalExpenses,
                    taxesRevenue: proposal.subtotalTaxes
                )
                .frame(height: 220)
                .padding(.vertical)
                
                // Revenue component list
                Group {
                    revenueRow(
                        title: "Products Subtotal",
                        value: proposal.subtotalProducts,
                        percentage: (proposal.subtotalProducts / proposal.totalAmount) * 100,
                        color: .blue,
                        icon: "cube.box.fill"
                    )
                    
                    revenueRow(
                        title: "Engineering Subtotal",
                        value: proposal.subtotalEngineering,
                        percentage: (proposal.subtotalEngineering / proposal.totalAmount) * 100,
                        color: .purple,
                        icon: "wrench.and.screwdriver.fill"
                    )
                    
                    revenueRow(
                        title: "Expenses Subtotal",
                        value: proposal.subtotalExpenses,
                        percentage: (proposal.subtotalExpenses / proposal.totalAmount) * 100,
                        color: .orange,
                        icon: "creditcard.fill"
                    )
                    
                    revenueRow(
                        title: "Custom Taxes",
                        value: proposal.subtotalTaxes,
                        percentage: (proposal.subtotalTaxes / proposal.totalAmount) * 100,
                        color: .red,
                        icon: "percent"
                    )
                    
                    Divider()
                    
                    // Total revenue row
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(revenueColor)
                            .frame(width: 24)
                        
                        Text("TOTAL REVENUE")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(Formatters.formatEuro(proposal.totalAmount))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Products revenue detail
            if proposal.subtotalProducts > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PRODUCT REVENUE DETAILS")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    // Product summary
                    ForEach(proposal.itemsArray.prefix(5), id: \.self) { item in
                        if let product = item.product {
                            HStack {
                                Text(product.name ?? "Unknown Product")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(Formatters.formatEuro(item.amount))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("qty: \(Int(item.quantity))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            Divider()
                        }
                    }
                    
                    if proposal.itemsArray.count > 5 {
                        HStack {
                            Spacer()
                            Text("+ \(proposal.itemsArray.count - 5) more products")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(secondaryBgColor)
                .cornerRadius(10)
            }
        }
    }
    
    // Cost Structure Section - WITH CUSTOM TAXES
    private var costStructureSection: some View {
        VStack(spacing: 20) {
            // Cost breakdown main section
            VStack(alignment: .leading, spacing: 16) {
                Text("COST STRUCTURE")
                    .font(.headline)
                    .foregroundColor(costColor)
                
                // Cost breakdown chart
                CostBreakdownChart(
                    partnerCost: calculatePartnerCost(),
                    expensesCost: proposal.subtotalExpenses,
                    taxCost: proposal.subtotalTaxes
                )
                .frame(height: 200)
                .padding(.vertical)
                
                // Detailed cost breakdown
                Group {
                    costRow(
                        title: "Partner Product Costs",
                        value: calculatePartnerCost(),
                        percentage: (calculatePartnerCost() / proposal.totalCost) * 100,
                        color: .blue,
                        icon: "cube.box.fill"
                    )
                    
                    costRow(
                        title: "Expenses",
                        value: proposal.subtotalExpenses,
                        percentage: (proposal.subtotalExpenses / proposal.totalCost) * 100,
                        color: .orange,
                        icon: "creditcard.fill"
                    )
                    
                    // Add custom taxes to the cost structure
                    costRow(
                        title: "Custom Taxes",
                        value: proposal.subtotalTaxes,
                        percentage: (proposal.subtotalTaxes / proposal.totalCost) * 100,
                        color: .red,
                        icon: "percent"
                    )
                    
                    // Note about tax calculation
                    if proposal.subtotalTaxes > 0 {
                        Button(action: { showingTaxDetails.toggle() }) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text("How are taxes calculated?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Image(systemName: showingTaxDetails ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                        
                        if showingTaxDetails {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom taxes are calculated as:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Tax Amount = Tax Rate × Sum(Partner Price × Quantity)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("Only for products marked with 'Apply Custom Tax'")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Display how many items are marked
                                Text("\(countTaxableItems()) of \(proposal.itemsArray.count) products have custom tax applied")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                    
                    // Total cost row
                    HStack {
                        Image(systemName: "cart.fill")
                            .foregroundColor(costColor)
                            .frame(width: 24)
                        
                        Text("TOTAL COST")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(Formatters.formatEuro(proposal.totalCost))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Partner pricing details - collapsible section
            VStack {
                Button(action: { showingPartnerPriceDetails.toggle() }) {
                    HStack {
                        Text("Partner Price Details")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: showingPartnerPriceDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if showingPartnerPriceDetails {
                    // Partner cost detail table
                    VStack(alignment: .leading, spacing: 12) {
                        // Header row
                        HStack {
                            Text("Product")
                                .font(.caption)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Qty")
                                .font(.caption)
                                .fontWeight(.bold)
                                .frame(width: 40)
                            
                            Text("Partner")
                                .font(.caption)
                                .fontWeight(.bold)
                                .frame(width: 70, alignment: .trailing)
                            
                            Text("Total")
                                .font(.caption)
                                .fontWeight(.bold)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .foregroundColor(.secondary)
                        
                        Divider()
                        
                        // Product rows
                        ForEach(proposal.itemsArray, id: \.self) { item in
                            if let product = item.product {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.name ?? "Unknown")
                                            .font(.subheadline)
                                            .lineLimit(1)
                                        
                                        // Show tax status
                                        if item.applyCustomTax {
                                            Text("Taxable")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(Int(item.quantity))")
                                        .font(.subheadline)
                                        .frame(width: 40)
                                    
                                    Text(Formatters.formatEuro(product.partnerPrice))
                                        .font(.subheadline)
                                        .frame(width: 70, alignment: .trailing)
                                    
                                    Text(Formatters.formatEuro(product.partnerPrice * item.quantity))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(width: 70, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                
                                Divider()
                            }
                        }
                        
                        // Total row
                        HStack {
                            Text("TOTAL PARTNER COST")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(Formatters.formatEuro(calculatePartnerCost()))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top, 12)
                }
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Custom Tax Details
            if proposal.taxesArray.count > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CUSTOM TAX DETAILS")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ForEach(proposal.taxesArray, id: \.self) { tax in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tax.name ?? "Custom Tax")
                                    .font(.subheadline)
                                
                                Text("Base: \(Formatters.formatEuro(proposal.taxableProductsAmount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Formatters.formatEuro(tax.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Rate: \(String(format: "%.1f%%", tax.rate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                    }
                }
                .padding()
                .background(secondaryBgColor)
                .cornerRadius(10)
            }
        }
    }
    
    // Profit Analysis Section
    private var profitAnalysisSection: some View {
        VStack(spacing: 20) {
            // Overall profit metrics
            VStack(alignment: .leading, spacing: 16) {
                Text("PROFIT ANALYSIS")
                    .font(.headline)
                    .foregroundColor(profitColor)
                
                // Profit calculation
                let totalRevenue = proposal.totalAmount
                let totalCost = proposal.totalCost
                let grossProfit = totalRevenue - totalCost
                let profitMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0
                
                // Profit visualization
                ProfitVisualization(
                    revenue: totalRevenue,
                    cost: totalCost
                )
                .frame(height: 120)
                .padding()
                
                // Profit metrics
                VStack(spacing: 12) {
                    // Gross profit
                    HStack {
                        Text("Gross Profit")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(Formatters.formatEuro(grossProfit))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(grossProfit >= 0 ? profitColor : .red)
                    }
                    
                    // Profit margin
                    HStack {
                        Text("Profit Margin")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", profitMargin))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(profitMarginColor(profitMargin))
                    }
                }
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Profit by category breakdown
            VStack(alignment: .leading, spacing: 16) {
                Text("PROFIT CONTRIBUTION")
                    .font(.headline)
                    .foregroundColor(profitColor)
                
                // Product profit analysis
                let productRevenue = proposal.subtotalProducts
                let productCost = calculateProductPartnerCost()
                let productProfit = productRevenue - productCost
                let productMargin = productRevenue > 0 ? (productProfit / productRevenue) * 100 : 0
                
                // Engineering profit analysis (typically 100% profit)
                let engineeringRevenue = proposal.subtotalEngineering
                let engineeringCost = 0.0 // Typically no cost for engineering
                let engineeringProfit = engineeringRevenue - engineeringCost
                let engineeringMargin = engineeringRevenue > 0 ? (engineeringProfit / engineeringRevenue) * 100 : 0
                
                // Expenses have no profit
                let expensesRevenue = proposal.subtotalExpenses
                let expensesCost = proposal.subtotalExpenses
                let expensesProfit = 0.0
                
                // Custom taxes are just cost
                let taxCost = proposal.subtotalTaxes
                
                // Category profit rows
                Group {
                    categoryProfitRow(
                        title: "Products",
                        revenue: productRevenue,
                        cost: productCost,
                        icon: "cube.box.fill",
                        color: .blue
                    )
                    
                    categoryProfitRow(
                        title: "Engineering",
                        revenue: engineeringRevenue,
                        cost: engineeringCost,
                        icon: "wrench.and.screwdriver.fill",
                        color: .purple
                    )
                    
                    categoryProfitRow(
                        title: "Expenses",
                        revenue: expensesRevenue,
                        cost: expensesCost,
                        icon: "creditcard.fill",
                        color: .orange
                    )
                    
                    // Show custom taxes as pure cost with no revenue
                    if proposal.subtotalTaxes > 0 {
                        HStack {
                            Image(systemName: "percent")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Custom Taxes")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Cost: \(Formatters.formatEuro(taxCost))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                
                                Text("Profit: -\(Formatters.formatEuro(taxCost))")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Divider()
                    
                    // Total profit row
                    let totalProfit = proposal.totalAmount - proposal.totalCost
                    let totalMargin = proposal.totalAmount > 0 ? (totalProfit / proposal.totalAmount) * 100 : 0
                    
                    HStack {
                        Text("TOTAL PROFIT")
                            .font(.headline)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Amount: \(Formatters.formatEuro(totalProfit))")
                                .font(.headline)
                                .foregroundColor(totalProfit >= 0 ? profitColor : .red)
                            
                            Text("Margin: \(String(format: "%.1f%%", totalMargin))")
                                .font(.subheadline)
                                .foregroundColor(profitMarginColor(totalMargin))
                        }
                    }
                }
            }
            .padding()
            .background(secondaryBgColor)
            .cornerRadius(10)
            
            // Profit margin improvement suggestions
            if calculateProfitMargin() < 30 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MARGIN IMPROVEMENT SUGGESTIONS")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        improvementSuggestion(
                            title: "Apply price multiplier",
                            description: "Increase product prices by applying a multiplier to list prices."
                        )
                        
                        improvementSuggestion(
                            title: "Reduce discount percentage",
                            description: "Review discounts applied to high-value items."
                        )
                        
                        if proposal.subtotalTaxes > 0 {
                            improvementSuggestion(
                                title: "Optimize custom taxes",
                                description: "Review which items have custom tax applied - this reduces profit."
                            )
                        }
                        
                        improvementSuggestion(
                            title: "Add engineering services",
                            description: "Engineering services typically have higher margins than products."
                        )
                    }
                }
                .padding()
                .background(secondaryBgColor)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Summary card component
    private func SummaryCard(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(Formatters.formatEuro(amount))
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(secondaryBgColor)
        .cornerRadius(10)
    }
    
    // Key metric card component
    private func KeyMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    // Helper view for summary rows
    private func summaryRow(title: String, value: Double, isBold: Bool = false, valueColor: Color? = nil) -> some View {
        HStack {
            Text(title)
                .fontWeight(isBold ? .bold : .regular)
            
            Spacer()
            
            Text(Formatters.formatEuro(value))
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(valueColor ?? .primary)
        }
        .padding(.vertical, 4)
    }
    
    // Helper view for cost rows
    private func costRow(title: String, value: Double, percentage: Double, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.formatEuro(value))
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper view for revenue rows
    private func revenueRow(title: String, value: Double, percentage: Double, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.formatEuro(value))
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper view for category profit rows
    private func categoryProfitRow(title: String, revenue: Double, cost: Double, icon: String, color: Color) -> some View {
        let profit = revenue - cost
        let margin = revenue > 0 ? (profit / revenue) * 100 : 0
        
        return HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("R: \(Formatters.formatEuro(revenue))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("C: \(Formatters.formatEuro(cost))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text("Profit: \(Formatters.formatEuro(profit))")
                        .font(.subheadline)
                        .foregroundColor(profit >= 0 ? profitColor : .red)
                    
                    Text("(\(String(format: "%.1f%%", margin)))")
                        .font(.caption)
                        .foregroundColor(profitMarginColor(margin))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper view for improvement suggestions
    private func improvementSuggestion(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 24)
        }
        .padding(.vertical, 4)
    }
    
    // Chart legend item
    private func ChartLegendItem(color: Color, label: String, percentage: Double) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Method to calculate partner cost
    private func calculatePartnerCost() -> Double {
        var partnerCost = 0.0
        for item in proposal.itemsArray {
            if let product = item.product {
                partnerCost += item.quantity * product.partnerPrice
            }
        }
        return partnerCost
    }
    
    // Method to calculate product partner cost only
    private func calculateProductPartnerCost() -> Double {
        var partnerCost = 0.0
        for item in proposal.itemsArray {
            if let product = item.product {
                partnerCost += item.quantity * product.partnerPrice
            }
        }
        return partnerCost
    }
    
    // Method to calculate profit margin
    private func calculateProfitMargin() -> Double {
        let totalRevenue = proposal.totalAmount
        let totalCost = proposal.totalCost
        let profit = totalRevenue - totalCost
        
        return totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0
    }
    
    // Method to calculate partner cost percentage
    private func calculatePartnerCostPercentage() -> Double {
        let partnerCost = calculatePartnerCost()
        let totalCost = proposal.totalCost
        
        return totalCost > 0 ? (partnerCost / totalCost) * 100 : 0
    }
    
    // Method to count taxable items
    private func countTaxableItems() -> Int {
        return proposal.itemsArray.filter { $0.applyCustomTax }.count
    }
    
    // Method to get color based on profit margin
    private func profitMarginColor(_ margin: Double) -> Color {
        if margin >= 30 {
            return .green
        } else if margin >= 15 {
            return .blue
        } else if margin >= 0 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Chart Components

// Financial Distribution Chart
struct FinancialDistributionChart: View {
    let revenue: Double
    let cost: Double
    
    private var profit: Double {
        return revenue - cost
    }
    
    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width
            let chartHeight = geometry.size.height * 0.6
            let yPos = geometry.size.height * 0.2
            
            // Draw the bars
            HStack(spacing: 0) {
                // Cost bar
                Rectangle()
                    .fill(Color.red)
                    .frame(width: chartWidth * CGFloat(cost / revenue), height: chartHeight)
                
                // Profit bar
                Rectangle()
                    .fill(Color.green)
                    .frame(width: chartWidth * CGFloat(profit / revenue), height: chartHeight)
            }
            .position(x: chartWidth / 2, y: yPos + chartHeight / 2)
            
            // Add labels
            VStack {
                Text("Total Revenue: \(Formatters.formatEuro(revenue))")
                    .font(.headline)
                    .position(x: chartWidth / 2, y: yPos + chartHeight + 30)
                
                HStack(spacing: 20) {
                    VStack(alignment: .center) {
                        Text("Cost")
                            .font(.subheadline)
                        Text(Formatters.formatEuro(cost))
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    .position(x: chartWidth * CGFloat(cost / revenue) / 2, y: yPos + chartHeight + 60)
                    
                    VStack(alignment: .center) {
                        Text("Profit")
                            .font(.subheadline)
                        Text(Formatters.formatEuro(profit))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .position(x: chartWidth * CGFloat(cost / revenue) + chartWidth * CGFloat(profit / revenue) / 2, y: yPos + chartHeight + 60)
                }
            }
        }
    }
}

// Revenue Donut Chart
struct RevenueDonutChart: View {
    let productsRevenue: Double
    let engineeringRevenue: Double
    let expensesRevenue: Double
    let taxesRevenue: Double
    
    private var totalRevenue: Double {
        return productsRevenue + engineeringRevenue + expensesRevenue + taxesRevenue
    }
    
    private var segments: [DonutSegment] {
        var segments: [DonutSegment] = []
        
        if productsRevenue > 0 {
            segments.append(DonutSegment(
                value: productsRevenue,
                color: .blue,
                label: "Products"
            ))
        }
        
        if engineeringRevenue > 0 {
            segments.append(DonutSegment(
                value: engineeringRevenue,
                color: .purple,
                label: "Engineering"
            ))
        }
        
        if expensesRevenue > 0 {
            segments.append(DonutSegment(
                value: expensesRevenue,
                color: .orange,
                label: "Expenses"
            ))
        }
        
        if taxesRevenue > 0 {
            segments.append(DonutSegment(
                value: taxesRevenue,
                color: .red,
                label: "Taxes"
            ))
        }
        
        return segments
    }
    
    var body: some View {
        VStack {
            // Donut chart
            ZStack {
                ForEach(0..<segments.count, id: \.self) { i in
                    DonutSegmentShape(
                        index: i,
                        segments: segments,
                        total: totalRevenue
                    )
                    .fill(segments[i].color)
                }
                
                // Inner circle with total
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: 100, height: 100)
                
                VStack {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(Formatters.formatEuro(totalRevenue))
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .frame(height: 180)
            
            // Legend
            HStack(spacing: 16) {
                ForEach(segments, id: \.label) { segment in
                    HStack {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(segment.label)
                                .font(.caption)
                            
                            let percentage = (segment.value / totalRevenue) * 100
                            Text(String(format: "%.1f%%", percentage))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// Cost Breakdown Chart
struct CostBreakdownChart: View {
    let partnerCost: Double
    let expensesCost: Double
    let taxCost: Double
    
    private var totalCost: Double {
        return partnerCost + expensesCost + taxCost
    }
    
    private var partnerPercentage: Double {
        return totalCost > 0 ? (partnerCost / totalCost) * 100 : 0
    }
    
    private var expensesPercentage: Double {
        return totalCost > 0 ? (expensesCost / totalCost) * 100 : 0
    }
    
    private var taxPercentage: Double {
        return totalCost > 0 ? (taxCost / totalCost) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Pie chart
            ZStack {
                PieChart(
                    values: [partnerCost, expensesCost, taxCost],
                    colors: [.blue, .orange, .red],
                    labels: ["Partner", "Expenses", "Taxes"],
                    showLabels: false
                )
                .frame(height: 150)
                
                // Center text
                VStack {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(Formatters.formatEuro(totalCost))
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            
            // Legend with percentages
            HStack(spacing: 24) {
                legendItem(color: .blue, label: "Products", value: partnerCost, percentage: partnerPercentage)
                legendItem(color: .orange, label: "Expenses", value: expensesCost, percentage: expensesPercentage)
                legendItem(color: .red, label: "Taxes", value: taxCost, percentage: taxPercentage)
            }
        }
    }
    
    private func legendItem(color: Color, label: String, value: Double, percentage: Double) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
            
            Text(String(format: "%.1f%%", percentage))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// Profit Visualization
struct ProfitVisualization: View {
    let revenue: Double
    let cost: Double
    
    private var profit: Double {
        return revenue - cost
    }
    
    private var profitMargin: Double {
        return revenue > 0 ? (profit / revenue) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Profit gauge
            GeometryReader { geometry in
                ZStack {
                    // Background track
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    // Revenue track
                    HStack(spacing: 0) {
                        // Cost portion
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geometry.size.width * CGFloat(min(cost / revenue, 1.0)), height: 20)
                        
                        // Profit portion
                        if profit > 0 {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * CGFloat(min(profit / revenue, 1.0)), height: 20)
                        }
                    }
                    .clipShape(Capsule())
                    
                    // Markers and labels
                    HStack {
                        Spacer()
                        
                        // 0% marker
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 30)
                        
                        // 50% marker
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 20)
                            .offset(x: geometry.size.width * 0.25)
                        
                        // 100% marker (end)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 30)
                            .offset(x: geometry.size.width * 0.5)
                        
                        Spacer()
                    }
                    
                    // Profit margin label
                    Text(String(format: "%.1f%% margin", profitMargin))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(profitMarginColor(profitMargin))
                        .cornerRadius(4)
                        .offset(y: -30)
                }
            }
            
            // Labels
            HStack {
                Text("COST")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("PROFIT")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
        }
    }
    
    // Helper for profit margin color
    private func profitMarginColor(_ margin: Double) -> Color {
        if margin >= 30 {
            return .green
        } else if margin >= 15 {
            return .blue
        } else if margin >= 0 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Chart Helper Structures

struct DonutSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let label: String
}

struct DonutSegmentShape: Shape {
    let index: Int
    let segments: [DonutSegment]
    let total: Double
    
    func path(in rect: CGRect) -> Path {
        let diameter = min(rect.width, rect.height)
        let radius = diameter / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let innerRadius = radius * 0.6 // Inner radius for donut
        
        // Calculate start and end angles
        var startAngle = Angle(degrees: 0)
        for i in 0..<index {
            startAngle += Angle(degrees: 360 * (segments[i].value / total))
        }
        
        let endAngle = startAngle + Angle(degrees: 360 * (segments[index].value / total))
        
        var path = Path()
        
        // Move to inner start point
        path.move(to: CGPoint(
            x: center.x + innerRadius * cos(CGFloat(startAngle.radians)),
            y: center.y + innerRadius * sin(CGFloat(startAngle.radians))
        ))
        
        // Line to outer start point
        path.addLine(to: CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        ))
        
        // Arc to outer end point
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Line to inner end point
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * cos(CGFloat(endAngle.radians)),
            y: center.y + innerRadius * sin(CGFloat(endAngle.radians))
        ))
        
        // Arc back to start
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        return path
    }
}

// Generic Pie Chart
struct PieChart: View {
    let values: [Double]
    let colors: [Color]
    let labels: [String]
    let showLabels: Bool
    
    private var total: Double {
        values.reduce(0, +)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<values.count, id: \.self) { i in
                    PieSlice(
                        startAngle: startAngle(for: i),
                        endAngle: endAngle(for: i)
                    )
                    .fill(colors[i % colors.count])
                    
                    if showLabels {
                        // Calculate position for label
                        let percentage = values[i] / total
                        let midAngle = startAngle(for: i) + Angle(degrees: percentage * 360 / 2)
                        let radius = min(geometry.size.width, geometry.size.height) / 2
                        let labelDistance = radius * 0.7
                        
                        let x = geometry.size.width/2 + labelDistance * cos(CGFloat(midAngle.radians))
                        let y = geometry.size.height/2 + labelDistance * sin(CGFloat(midAngle.radians))
                        
                        Text(labels[i])
                            .font(.caption2)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
    
    // Helper to calculate start angle
    private func startAngle(for index: Int) -> Angle {
        if index == 0 { return .degrees(0) }
        
        var totalAngle: Double = 0
        for i in 0..<index {
            totalAngle += (values[i] / total) * 360
        }
        return .degrees(totalAngle)
    }
    
    // Helper to calculate end angle
    private func endAngle(for index: Int) -> Angle {
        return startAngle(for: index + 1)
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addLine(to: CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        ))
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        path.addLine(to: center)
        return path
    }
}

struct EnhancedFinancialSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample proposal
        let proposal = Proposal(context: context)
        proposal.id = UUID()
        proposal.number = "PROP-2023-001"
        proposal.totalAmount = 10000
        
        // Add sample tax
        let tax = CustomTax(context: context)
        tax.id = UUID()
        tax.name = "VAT"
        tax.rate = 20
        tax.amount = 2000
        tax.proposal = proposal
        
        return EnhancedFinancialSummaryView(proposal: proposal)
            .environment(\.managedObjectContext, context)
            .preferredColorScheme(.dark)
    }
}
