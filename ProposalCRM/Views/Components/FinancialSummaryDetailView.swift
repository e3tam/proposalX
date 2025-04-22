import SwiftUI
import Charts // Ensure Charts framework is imported

struct FinancialSummaryDetailView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Computed properties for financial analysis
    
    // Revenue breakdown data
    private var revenueData: [(name: String, value: Double, color: Color)] {
        var data: [(String, Double, Color)] = []
        if proposal.subtotalProducts > 0 { 
            data.append(("Products", proposal.subtotalProducts, .blue)) 
        }
        if proposal.subtotalEngineering > 0 { 
            data.append(("Engineering", proposal.subtotalEngineering, .green)) 
        }
        if proposal.subtotalExpenses > 0 { 
            data.append(("Expenses", proposal.subtotalExpenses, .orange)) 
        }
        if proposal.subtotalTaxes > 0 { 
            data.append(("Taxes", proposal.subtotalTaxes, .red)) 
        }
        return data
    }
    
    // Product categories data for bar chart
    private var productsByCategory: [(category: String, total: Double, profit: Double, margin: Double)] {
        var categoryTotals: [String: (total: Double, cost: Double)] = [:]
        for item in proposal.itemsArray {
            let category = item.product?.category ?? "Uncategorized"
            let amount = item.amount
            let cost = (item.product?.partnerPrice ?? 0) * item.quantity
            
            if let existing = categoryTotals[category] {
                categoryTotals[category] = (
                    total: existing.total + amount,
                    cost: existing.cost + cost
                )
            } else {
                categoryTotals[category] = (total: amount, cost: cost)
            }
        }
        
        return categoryTotals.map { category, values in
            let profit = values.total - values.cost
            let margin = values.total > 0 ? (profit / values.total) * 100 : 0
            return (category, values.total, profit, margin)
        }.sorted { $0.total > $1.total }
    }
    
    // Cost breakdown data
    private var costBreakdown: [(name: String, value: Double, color: Color)] {
        var costs: [(String, Double, Color)] = []
        
        // Product costs
        let productsCost = proposal.itemsArray.reduce(0.0) { total, item in
            total + ((item.product?.partnerPrice ?? 0) * item.quantity)
        }
        if productsCost > 0 { costs.append(("Products", productsCost, .blue)) }
        
        // Categorize expenses if possible
        let travelExpenses = proposal.expensesArray.filter { 
            ($0.desc?.lowercased().contains("travel") ?? false) || 
            ($0.desc?.lowercased().contains("flight") ?? false) ||
            ($0.desc?.lowercased().contains("hotel") ?? false)
        }.reduce(0.0) { $0 + $1.amount }
        
        let shippingExpenses = proposal.expensesArray.filter { 
            ($0.desc?.lowercased().contains("shipping") ?? false) || 
            ($0.desc?.lowercased().contains("delivery") ?? false)
        }.reduce(0.0) { $0 + $1.amount }
        
        let otherExpenses = proposal.subtotalExpenses - travelExpenses - shippingExpenses
        
        if travelExpenses > 0 { costs.append(("Travel", travelExpenses, .orange)) }
        if shippingExpenses > 0 { costs.append(("Shipping", shippingExpenses, .purple)) }
        if otherExpenses > 0 { costs.append(("Other Expenses", otherExpenses, .gray)) }
        
        return costs
    }
    
    // Total cost for calculations
    private var totalCost: Double {
        proposal.totalCost
    }
    
    // Profit margins for different product categories
    private var profitByCategoryData: [(category: String, revenue: Double, profit: Double, margin: Double)] {
        return productsByCategory.map { category, revenue, profit, margin in
            return (category, revenue, profit, margin)
        }
    }
    
    // Discount analysis data
    private var discountAnalysisData: [(category: String, avgDiscount: Double, items: Int)] {
        var categoryDiscounts: [String: [Double]] = [:]
        var categoryCounts: [String: Int] = [:]
        
        for item in proposal.itemsArray {
            let category = item.product?.category ?? "Uncategorized"
            categoryDiscounts[category, default: []].append(item.discount)
            categoryCounts[category, default: 0] += 1
        }
        
        return categoryDiscounts.map { category, discounts in
            let totalDiscount = discounts.reduce(0, +)
            let avgDiscount = discounts.isEmpty ? 0 : totalDiscount / Double(discounts.count)
            return (category, avgDiscount, categoryCounts[category] ?? 0)
        }.sorted { $0.avgDiscount > $1.avgDiscount }
    }
    
    // Key performance indicators
    private var keyMetrics: [(name: String, value: Double, formatter: (Double) -> String, colorBasedOnValue: Bool)] {
        let grossProfit = proposal.grossProfit
        let profitMargin = proposal.profitMargin
        let avgProductProfit = proposal.itemsArray.isEmpty ? 0 : 
                              (grossProfit / Double(proposal.itemsArray.count))
        let roi = totalCost > 0 ? (grossProfit / totalCost) * 100 : 0
        let revenuePerCategory = productsByCategory.isEmpty ? 0 : 
                               (proposal.subtotalProducts / Double(productsByCategory.count))
        let engineeringPercent = proposal.totalAmount > 0 ? 
                                (proposal.subtotalEngineering / proposal.totalAmount) * 100 : 0
        
        return [
            ("Gross Profit", grossProfit, Formatters.formatEuro, true),
            ("Profit Margin", profitMargin, Formatters.formatPercent, true),
            ("Return on Investment", roi, Formatters.formatPercent, true),
            ("Avg. Profit per Product", avgProductProfit, Formatters.formatEuro, true),
            ("Revenue per Category", revenuePerCategory, Formatters.formatEuro, false),
            ("Engineering % of Total", engineeringPercent, Formatters.formatPercent, false)
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overall financial metrics
                    overallMetricsSection
                    
                    // Revenue breakdown with pie chart
                    revenueBreakdownSection
                    
                    // Product category performance
                    categoryPerformanceSection
                    
                    // Cost breakdown
                    costBreakdownSection
                    
                    // Profit analysis by category
                    profitAnalysisSection
                    
                    // Discount analysis
                    discountAnalysisSection
                    
                    // Engineering analysis if applicable
                    if !proposal.engineeringArray.isEmpty {
                        engineeringAnalysisSection
                    }
                    
                    // Tax breakdown if applicable
                    if !proposal.taxesArray.isEmpty {
                        taxBreakdownSection
                    }
                    
                    // Key metrics
                    keyMetricsSection
                }
                .padding()
            }
            .navigationTitle("Financial Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        presentationMode.wrappedValue.dismiss() 
                    }
                }
            }
        }
    }
    
    // MARK: - Section Views
    
    private var overallMetricsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Financial Summary")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 15) {
                MetricCard(
                    title: "Total Revenue",
                    value: Formatters.formatEuro(proposal.totalAmount),
                    subtitle: "All revenue sources",
                    icon: "dollarsign.circle.fill",
                    trend: "",
                    trendUp: true
                )
                
                MetricCard(
                    title: "Total Cost",
                    value: Formatters.formatEuro(totalCost),
                    subtitle: "Products & expenses",
                    icon: "cart.fill",
                    trend: "",
                    trendUp: false
                )
            }
            
            HStack(spacing: 15) {
                MetricCard(
                    title: "Gross Profit",
                    value: Formatters.formatEuro(proposal.grossProfit),
                    subtitle: "Revenue - Costs",
                    icon: "chart.line.uptrend.xyaxis",
                    trend: "",
                    trendUp: proposal.grossProfit > 0
                )
                
                MetricCard(
                    title: "Profit Margin",
                    value: Formatters.formatPercent(proposal.profitMargin),
                    subtitle: "Profit ÷ Revenue",
                    icon: "percent",
                    trend: "",
                    trendUp: proposal.profitMargin > 30
                )
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var revenueBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Revenue Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(revenueData, id: \.name) { item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(5)
                        .annotation(position: .overlay) {
                            Text(item.value > (proposal.totalAmount * 0.1) ? 
                                 String(format: "%.0f%%", (item.value/proposal.totalAmount)*100) : "")
                                .font(.caption)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                .frame(height: 240)
            } else {
                // Fallback for iOS 15 - Simple color squares legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(revenueData, id: \.name) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            Text(item.name)
                                .font(.caption)
                            Text(Formatters.formatEuro(item.value))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "(%.0f%%)", (item.value/proposal.totalAmount)*100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 100)
            }
            
            ForEach(revenueData, id: \.name) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    Text(item.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(Formatters.formatPercent((item.value / proposal.totalAmount) * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(Formatters.formatEuro(item.value))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total Revenue")
                    .font(.headline)
                Spacer()
                Text(Formatters.formatEuro(proposal.totalAmount))
                    .font(.headline)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var categoryPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Product Category Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(productsByCategory, id: \.category) { category in
                        BarMark(
                            x: .value("Revenue", category.total),
                            y: .value("Category", category.category)
                        )
                        .foregroundStyle(category.profit > 0 ? Color.blue.gradient : Color.red.gradient)
                        .annotation(position: .trailing) {
                            Text(Formatters.formatEuro(category.total))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .frame(height: CGFloat(productsByCategory.count * 50))
                .padding(.vertical)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 8) {
                    ForEach(productsByCategory, id: \.category) { category in
                        HStack {
                            Text(category.category)
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: geo.size.width, height: 20)
                                        .cornerRadius(4)
                                    
                                    let maxRevenue = productsByCategory.map { $0.total }.max() ?? 1.0
                                    let width = geo.size.width * (category.total / maxRevenue)
                                    
                                    Rectangle()
                                        .fill(category.profit > 0 ? Color.blue : Color.red)
                                        .frame(width: width, height: 20)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 20)
                            
                            Text(Formatters.formatEuro(category.total))
                                .font(.caption)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                .frame(height: CGFloat(productsByCategory.count * 30 + 20))
            }
            
            Divider()
            
            ForEach(productsByCategory, id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.subheadline)
                    Spacer()
                    
                    HStack(spacing: 15) {
                        VStack(alignment: .trailing) {
                            Text("Revenue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(Formatters.formatEuro(item.total))
                                .font(.subheadline)
                        }
                        
                        VStack(alignment: .trailing) {
                            Text("Margin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(Formatters.formatPercent(item.margin))
                                .font(.subheadline)
                                .foregroundColor(item.margin > 20 ? .green : (item.margin > 10 ? .orange : .red))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var costBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Cost Structure")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(costBreakdown, id: \.name) { item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(5)
                        .annotation(position: .overlay) {
                            Text(item.value > (totalCost * 0.1) ? 
                                 String(format: "%.0f%%", (item.value/totalCost)*100) : "")
                                .font(.caption)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                .frame(height: 200)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 10) {
                    ForEach(costBreakdown, id: \.name) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            Text(item.name)
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f%%", (item.value/totalCost)*100))
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .frame(height: 120)
            }
            
            ForEach(costBreakdown, id: \.name) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    Text(item.name)
                        .font(.subheadline)
                    Spacer()
                    Text(Formatters.formatPercent((item.value / totalCost) * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.formatEuro(item.value))
                        .font(.subheadline)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total Cost")
                    .font(.headline)
                Spacer()
                Text(Formatters.formatEuro(totalCost))
                    .font(.headline)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var profitAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Profit Analysis by Category")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(profitByCategoryData, id: \.category) { item in
                        BarMark(
                            x: .value("Profit", item.profit),
                            y: .value("Category", item.category)
                        )
                        .foregroundStyle(item.profit > 0 ? Color.green.gradient : Color.red.gradient)
                        .annotation(position: .trailing) {
                            Text(Formatters.formatEuro(item.profit))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .frame(height: CGFloat(profitByCategoryData.count * 50))
                .padding(.vertical)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 8) {
                    ForEach(profitByCategoryData, id: \.category) { item in
                        HStack {
                            Text(item.category)
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: geo.size.width, height: 20)
                                        .cornerRadius(4)
                                    
                                    let maxProfit = profitByCategoryData.map { abs($0.profit) }.max() ?? 1.0
                                    let width = geo.size.width * (abs(item.profit) / maxProfit)
                                    
                                    Rectangle()
                                        .fill(item.profit > 0 ? Color.green : Color.red)
                                        .frame(width: width, height: 20)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 20)
                            
                            Text(Formatters.formatEuro(item.profit))
                                .font(.caption)
                                .foregroundColor(item.profit > 0 ? .green : .red)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                .frame(height: CGFloat(profitByCategoryData.count * 30 + 20))
            }
            
            Divider()
            
            ForEach(profitByCategoryData, id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 20) {
                        Text(Formatters.formatPercent(item.margin))
                            .font(.subheadline)
                            .foregroundColor(item.margin > 20 ? .green : (item.margin > 10 ? .orange : .red))
                        
                        Text(Formatters.formatEuro(item.profit))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(item.profit >= 0 ? .green : .red)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Text("Total Profit")
                    .font(.headline)
                Spacer()
                Text(Formatters.formatEuro(proposal.grossProfit))
                    .font(.headline)
                    .foregroundColor(proposal.grossProfit >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var discountAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Discount Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(discountAnalysisData, id: \.category) { item in
                        BarMark(
                            x: .value("Discount", item.avgDiscount),
                            y: .value("Category", item.category)
                        )
                        .foregroundStyle(Color.orange.gradient)
                        .annotation(position: .trailing) {
                            Text(Formatters.formatPercent(item.avgDiscount))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        if let percentage = value.as(Double.self) {
                            AxisValueLabel {
                                Text(Formatters.formatPercent(percentage))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: CGFloat(discountAnalysisData.count * 50))
            } else {
                // Fallback for iOS 15
                VStack(spacing: 8) {
                    ForEach(discountAnalysisData, id: \.category) { item in
                        HStack {
                            Text(item.category)
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: geo.size.width, height: 20)
                                        .cornerRadius(4)
                                    
                                    let maxDiscount = discountAnalysisData.map { $0.avgDiscount }.max() ?? 1.0
                                    let width = geo.size.width * (item.avgDiscount / max(maxDiscount, 1.0))
                                    
                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(width: width, height: 20)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 20)
                            
                            Text(Formatters.formatPercent(item.avgDiscount))
                                .font(.caption)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                .frame(height: CGFloat(discountAnalysisData.count * 30 + 20))
            }
            
            Divider()
            
            ForEach(discountAnalysisData, id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.subheadline)
                        
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Text("\(item.items) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                        Text(Formatters.formatPercent(item.avgDiscount))
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Average discount across all products
            if !proposal.itemsArray.isEmpty {
                Divider()
                
                let totalDiscount = proposal.itemsArray.reduce(0.0) { $0 + $1.discount }
                let avgDiscount = totalDiscount / Double(proposal.itemsArray.count)
                
                HStack {
                    Text("Average Discount")
                        .font(.headline)
                    Spacer()
                    Text(Formatters.formatPercent(avgDiscount))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var engineeringAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Engineering Services")
                .font(.title2)
                .fontWeight(.bold)
            
            let totalDays = proposal.engineeringArray.reduce(0.0) { $0 + $1.days }
            let avgRate = totalDays > 0 ? proposal.subtotalEngineering / totalDays : 0
            
            HStack {
                MetricCard(
                    title: "Total Days",
                    value: String(format: "%.1f", totalDays),
                    subtitle: "Engineering time",
                    icon: "clock.fill",
                    trend: "",
                    trendUp: true
                )
                
                MetricCard(
                    title: "Avg Daily Rate",
                    value: Formatters.formatEuro(avgRate),
                    subtitle: "Per engineer day",
                    icon: "eurosign.circle.fill",
                    trend: "",
                    trendUp: true
                )
            }
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(proposal.engineeringArray, id: \.id) { engineering in
                        BarMark(
                            x: .value("Amount", engineering.amount),
                            y: .value("Description", engineering.desc ?? "Engineering")
                        )
                        .foregroundStyle(Color.green.gradient)
                    }
                }
                .frame(height: CGFloat(proposal.engineeringArray.count * 40 + 30))
                .padding(.vertical)
            }
            
            Divider()
            
            ForEach(proposal.engineeringArray, id: \.id) { engineering in
                HStack {
                    VStack(alignment: .leading) {
                        Text(engineering.desc ?? "Engineering Service")
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Text("\(String(format: "%.1f", engineering.days)) days @ \(Formatters.formatEuro(engineering.rate))/day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(Formatters.formatEuro(engineering.amount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            HStack {
                Text("Total Engineering")
                    .font(.headline)
                Spacer()
                Text(Formatters.formatEuro(proposal.subtotalEngineering))
                    .font(.headline)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var taxBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tax Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            // Calculate the tax base
            let taxBase = proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(proposal.taxesArray, id: \.id) { tax in
                        BarMark(
                            x: .value("Amount", tax.amount),
                            y: .value("Name", tax.name ?? "Tax")
                        )
                        .foregroundStyle(Color.red.gradient)
                    }
                }
                .frame(height: CGFloat(proposal.taxesArray.count * 40 + 30))
                .padding(.vertical)
            }
            
            ForEach(proposal.taxesArray, id: \.id) { tax in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tax.name ?? "Tax")
                            .font(.subheadline)
                        
                        Text("Rate: \(Formatters.formatPercent(tax.rate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(Formatters.formatEuro(tax.amount))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(String(format: "%.1f%% of base", (tax.amount / taxBase) * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tax Base")
                        .font(.subheadline)
                    Spacer()
                    Text(Formatters.formatEuro(taxBase))
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Total Taxes")
                        .font(.headline)
                    Spacer()
                    Text(Formatters.formatEuro(proposal.subtotalTaxes))
                        .font(.headline)
                }
                
                HStack {
                    Text("Effective Tax Rate")
                        .font(.subheadline)
                    Spacer()
                    Text(Formatters.formatPercent(taxBase > 0 ? (proposal.subtotalTaxes / taxBase) * 100 : 0))
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Key Financial Indicators")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(keyMetrics, id: \.name) { metric in
                HStack {
                    Text(metric.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(metric.formatter(metric.value))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(
                            metric.colorBasedOnValue ? 
                            (metric.value > 0 ? .green : .red) : nil
                        )
                }
                .padding(.vertical, 2)
            }
            
            Divider()
            
            // Benchmark comparisons
            VStack(alignment: .leading, spacing: 10) {
                Text("Benchmark Comparison")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                let margin = proposal.profitMargin
                let industryBenchmark = 25.0 // Example industry benchmark
                
                HStack {
                    Text("Current Margin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Formatters.formatPercent(margin))
                        .font(.caption)
                        .foregroundColor(margin > industryBenchmark ? .green : .red)
                }
                
                HStack {
                    Text("Industry Benchmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Formatters.formatPercent(industryBenchmark))
                        .font(.caption)
                }
                
                HStack {
                    Text("Difference")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Formatters.formatPercent(margin - industryBenchmark))
                        .font(.caption)
                        .foregroundColor(margin > industryBenchmark ? .green : .red)
                }
                
                // Simple benchmark visualization
                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 2) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(margin > industryBenchmark ? Color.green : Color.red)
                                .frame(width: geo.size.width * min(max(margin / 50.0, 0), 1), height: 8)
                                .cornerRadius(4)
                            
                            // Benchmark line
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 2, height: 12)
                                .offset(x: geo.size.width * (industryBenchmark / 50.0) - 1)
                        }
                        
                        // Legend
                        HStack {
                            Text("0%")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("25%")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .offset(x: geo.size.width * 0.06)
                            
                            Spacer()
                            
                            Text("50%")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 20)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// Supporting component for the financial summary view
struct KPICard: View {
    let title: String
    let value: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
                .lineLimit(1)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(10)
    }
}