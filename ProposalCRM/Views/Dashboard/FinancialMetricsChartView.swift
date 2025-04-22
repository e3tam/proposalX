//
//  FinancialMetricsChartView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


import SwiftUI
import Charts

struct FinancialMetricsChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    @State private var selectedMetric = "Revenue"
    let metricOptions = ["Revenue", "Profit", "Margin", "Deal Size"]
    
    @State private var selectedTimePeriod = "3 Months"
    let timePeriods = ["1 Month", "3 Months", "6 Months", "1 Year", "All Time"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            HStack {
                Text("Financial Performance")
                    .font(.headline)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(metricOptions, id: \.self) { metric in
                        Text(metric).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
            }
            
            HStack {
                Text("Time Period:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Time Period", selection: $selectedTimePeriod) {
                    ForEach(timePeriods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                summaryText
            }
            
            // Main Chart
            metricChart
                .frame(height: 240)
            
            // Additional insights
            VStack(spacing: 10) {
                Divider()
                
                // Different insights based on selected metric
                HStack(spacing: 20) {
                    switch selectedMetric {
                    case "Revenue":
                        revenueInsights
                    case "Profit":
                        profitInsights
                    case "Margin":
                        marginInsights
                    case "Deal Size":
                        dealSizeInsights
                    default:
                        revenueInsights
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Main Chart Views
    
    private var metricChart: some View {
        Chart {
            ForEach(chartData, id: \.period) { item in
                BarMark(
                    x: .value("Period", item.period),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [metricColor.opacity(0.6), metricColor],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .annotation(position: .top) {
                    if selectedMetric == "Margin" {
                        Text("\(String(format: "%.1f", item.value))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(currencyFormatter.string(from: NSNumber(value: item.value)) ?? "$\(Int(item.value))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Average line
            RuleMark(
                y: .value("Average", averageValue)
            )
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .foregroundStyle(.black.opacity(0.5))
            .annotation(position: .trailing) {
                if selectedMetric == "Margin" {
                    Text("Avg: \(String(format: "%.1f", averageValue))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Avg: \(currencyFormatter.string(from: NSNumber(value: averageValue)) ?? "$\(Int(averageValue))")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Target line (only for certain metrics)
            if let targetValue = targetMetricValue, targetValue > 0 {
                RuleMark(
                    y: .value("Target", targetValue)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(.green)
                .annotation(position: .top, alignment: .leading) {
                    if selectedMetric == "Margin" {
                        Text("Target: \(String(format: "%.1f", targetValue))%")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Target: \(currencyFormatter.string(from: NSNumber(value: targetValue)) ?? "$\(Int(targetValue))")")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Insight Views
    
    private var revenueInsights: some View {
        Group {
            MetricCard(
                title: "Top Customer",
                value: topCustomer.name,
                subtitle: currencyFormatter.string(from: NSNumber(value: topCustomer.value)) ?? "$\(Int(topCustomer.value))",
                icon: "person.fill",
                trend: "+12% from prev.",
                trendUp: true
            )
            
            MetricCard(
                title: "Top Product",
                value: topProduct.name,
                subtitle: "\(topProduct.count) sold",
                icon: "cube.fill",
                trend: currencyFormatter.string(from: NSNumber(value: topProduct.value)) ?? "$\(Int(topProduct.value))",
                trendUp: true
            )
            
            MetricCard(
                title: "Forecast",
                value: currencyFormatter.string(from: NSNumber(value: forecastValue)) ?? "$\(Int(forecastValue))",
                subtitle: "Next \(selectedTimePeriod)",
                icon: "chart.line.uptrend.xyaxis",
                trend: forecastGrowth >= 0 ? "+\(String(format: "%.1f", forecastGrowth))%" : "\(String(format: "%.1f", forecastGrowth))%",
                trendUp: forecastGrowth >= 0
            )
        }
    }
    
    private var profitInsights: some View {
        Group {
            MetricCard(
                title: "Most Profitable",
                value: topProfitableProposal.name,
                subtitle: currencyFormatter.string(from: NSNumber(value: topProfitableProposal.profit)) ?? "$\(Int(topProfitableProposal.profit))",
                icon: "arrow.up.forward",
                trend: "\(String(format: "%.1f", topProfitableProposal.margin))% margin",
                trendUp: true
            )
            
            MetricCard(
                title: "Least Profitable",
                value: lowestProfitableProposal.name,
                subtitle: currencyFormatter.string(from: NSNumber(value: lowestProfitableProposal.profit)) ?? "$\(Int(lowestProfitableProposal.profit))",
                icon: "arrow.down.forward",
                trend: "\(String(format: "%.1f", lowestProfitableProposal.margin))% margin",
                trendUp: false
            )
            
            MetricCard(
                title: "Profit Ratio",
                value: "\(String(format: "%.1f", overallProfitRatio * 100))%",
                subtitle: "of total revenue",
                icon: "percent",
                trend: "Target: 25%",
                trendUp: overallProfitRatio >= 0.25
            )
        }
    }
    
    private var marginInsights: some View {
        Group {
            MetricCard(
                title: "Highest Margin",
                value: "\(String(format: "%.1f", highestMargin.margin))%",
                subtitle: highestMargin.name,
                icon: "arrow.up.forward",
                trend: currencyFormatter.string(from: NSNumber(value: highestMargin.value)) ?? "$\(Int(highestMargin.value))",
                trendUp: true
            )
            
            MetricCard(
                title: "Lowest Margin",
                value: "\(String(format: "%.1f", lowestMargin.margin))%",
                subtitle: lowestMargin.name,
                icon: "arrow.down.forward",
                trend: currencyFormatter.string(from: NSNumber(value: lowestMargin.value)) ?? "$\(Int(lowestMargin.value))",
                trendUp: false
            )
            
            MetricCard(
                title: "Engr. vs Product",
                value: "\(String(format: "%.1f", engineeringMargin))% vs \(String(format: "%.1f", productMargin))%",
                subtitle: "margin comparison",
                icon: "gearshape.2",
                trend: "Average: \(String(format: "%.1f", averageValue))%",
                trendUp: engineeringMargin > productMargin
            )
        }
    }
    
    private var dealSizeInsights: some View {
        Group {
            MetricCard(
                title: "Largest Deal",
                value: currencyFormatter.string(from: NSNumber(value: largestDeal.value)) ?? "$\(Int(largestDeal.value))",
                subtitle: largestDeal.name,
                icon: "arrow.up.forward",
                trend: largestDeal.date,
                trendUp: true
            )
            
            MetricCard(
                title: "Growth Trend",
                value: "\(String(format: "%.1f", dealSizeGrowth))%",
                subtitle: "vs previous period",
                icon: "chart.line.uptrend.xyaxis",
                trend: "Goal: 15%",
                trendUp: dealSizeGrowth >= 15
            )
            
            MetricCard(
                title: "Deal Distribution",
                value: "See chart →",
                subtitle: "Click for details",
                icon: "chart.pie",
                trend: "",
                trendUp: true
            )
        }
    }
    
    // MARK: - Helper Views
    
    private var summaryText: some View {
        switch selectedMetric {
        case "Revenue":
            return Text("Total: \(currencyFormatter.string(from: NSNumber(value: totalRevenue)) ?? "$\(Int(totalRevenue))")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        case "Profit":
            return Text("Total: \(currencyFormatter.string(from: NSNumber(value: totalProfit)) ?? "$\(Int(totalProfit))")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        case "Margin":
            return Text("Average: \(String(format: "%.1f", averageMargin))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
        case "Deal Size":
            return Text("Average: \(currencyFormatter.string(from: NSNumber(value: averageDealSize)) ?? "$\(Int(averageDealSize))")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        default:
            return Text("")
        }
    }
    
    // MARK: - Computed Properties
    
    private struct ChartDataPoint {
        let period: String
        let value: Double
    }
    
    private var chartData: [ChartDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        let numberOfPeriods: Int
        switch selectedTimePeriod {
        case "1 Month": numberOfPeriods = 4 // Show weeks
        case "3 Months": numberOfPeriods = 3
        case "6 Months": numberOfPeriods = 6
        case "1 Year": numberOfPeriods = 6 // Bi-monthly
        default: numberOfPeriods = 12
        }
        
        var result: [ChartDataPoint] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Generate periods based on selected time range
        for i in 0..<numberOfPeriods {
            // Calculate period start and end
            let periodOffset = selectedTimePeriod == "1 Month" ? 
                calendar.date(byAdding: .weekOfYear, value: -i, to: now) :
                calendar.date(byAdding: .month, value: -i, to: now)
            
            if let periodDate = periodOffset {
                let periodName = selectedTimePeriod == "1 Month" ? 
                    "W\(numberOfPeriods-i)" : 
                    dateFormatter.string(from: periodDate)
                
                // Calculate metric value for this period
                let value: Double
                switch selectedMetric {
                case "Revenue":
                    value = revenueForPeriod(periodDate, isWeekly: selectedTimePeriod == "1 Month")
                case "Profit":
                    value = profitForPeriod(periodDate, isWeekly: selectedTimePeriod == "1 Month")
                case "Margin":
                    value = marginForPeriod(periodDate, isWeekly: selectedTimePeriod == "1 Month")
                case "Deal Size":
                    value = dealSizeForPeriod(periodDate, isWeekly: selectedTimePeriod == "1 Month")
                default:
                    value = 0
                }
                
                result.append(ChartDataPoint(period: periodName, value: value))
            }
        }
        
        // Reverse to show chronological order
        return result.reversed()
    }
    
    private var averageValue: Double {
        if chartData.isEmpty {
            return 0
        }
        let total = chartData.reduce(0) { $0 + $1.value }
        return total / Double(chartData.count)
    }
    
    private var targetMetricValue: Double? {
        switch selectedMetric {
        case "Revenue":
            return averageValue * 1.2 // Target is 20% above average
        case "Profit":
            return averageValue * 1.15 // Target is 15% above average
        case "Margin":
            return 25 // Target margin is 25%
        case "Deal Size":
            return averageValue * 1.1 // Target is 10% above average
        default:
            return nil
        }
    }
    
    private var metricColor: Color {
        switch selectedMetric {
        case "Revenue": return .blue
        case "Profit": return .green
        case "Margin": return .purple
        case "Deal Size": return .orange
        default: return .blue
        }
    }
    
    // Filtered proposals for current time period
    private var filteredProposals: [Proposal] {
        let cutoffDate: Date?
        
        switch selectedTimePeriod {
        case "1 Month":
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        case "3 Months":
            cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        case "6 Months":
            cutoffDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())
        case "1 Year":
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        default:
            cutoffDate = nil
        }
        
        if let cutoff = cutoffDate {
            return proposals.filter { proposal in
                guard let creationDate = proposal.creationDate else { return false }
                return creationDate >= cutoff
            }
        } else {
            return Array(proposals)
        }
    }
    
    // Only consider won proposals for many metrics
    private var wonProposals: [Proposal] {
        return filteredProposals.filter { $0.status == "Won" }
    }
    
    // MARK: - Metric Calculation Methods
    
    private func revenueForPeriod(_ date: Date, isWeekly: Bool = false) -> Double {
        let calendar = Calendar.current
        
        return wonProposals.reduce(0) { total, proposal in
            guard let creationDate = proposal.creationDate else { return total }
            
            let isSamePeriod = isWeekly ?
                calendar.isDate(creationDate, equalTo: date, toGranularity: .weekOfYear) :
                calendar.isDate(creationDate, equalTo: date, toGranularity: .month)
            
            return isSamePeriod ? total + proposal.totalAmount : total
        }
    }
    
    private func profitForPeriod(_ date: Date, isWeekly: Bool = false) -> Double {
        let calendar = Calendar.current
        
        return wonProposals.reduce(0) { total, proposal in
            guard let creationDate = proposal.creationDate else { return total }
            
            let isSamePeriod = isWeekly ?
                calendar.isDate(creationDate, equalTo: date, toGranularity: .weekOfYear) :
                calendar.isDate(creationDate, equalTo: date, toGranularity: .month)
            
            return isSamePeriod ? total + proposal.grossProfit : total
        }
    }
    
    private func marginForPeriod(_ date: Date, isWeekly: Bool = false) -> Double {
        let calendar = Calendar.current
        
        var periodRevenue = 0.0
        var periodProfit = 0.0
        
        for proposal in wonProposals {
            guard let creationDate = proposal.creationDate else { continue }
            
            let isSamePeriod = isWeekly ?
                calendar.isDate(creationDate, equalTo: date, toGranularity: .weekOfYear) :
                calendar.isDate(creationDate, equalTo: date, toGranularity: .month)
            
            if isSamePeriod {
                periodRevenue += proposal.totalAmount
                periodProfit += proposal.grossProfit
            }
        }
        
        if periodRevenue == 0 {
            return 0
        }
        
        return (periodProfit / periodRevenue) * 100
    }
    
    private func dealSizeForPeriod(_ date: Date, isWeekly: Bool = false) -> Double {
        let calendar = Calendar.current
        
        var periodTotal = 0.0
        var proposalCount = 0
        
        for proposal in wonProposals {
            guard let creationDate = proposal.creationDate else { continue }
            
            let isSamePeriod = isWeekly ?
                calendar.isDate(creationDate, equalTo: date, toGranularity: .weekOfYear) :
                calendar.isDate(creationDate, equalTo: date, toGranularity: .month)
            
            if isSamePeriod {
                periodTotal += proposal.totalAmount
                proposalCount += 1
            }
        }
        
        if proposalCount == 0 {
            return 0
        }
        
        return periodTotal / Double(proposalCount)
    }
    
    // MARK: - Insight Computation
    
    private var totalRevenue: Double {
        wonProposals.reduce(0) { $0 + $1.totalAmount }
    }
    
    private var totalProfit: Double {
        wonProposals.reduce(0) { $0 + $1.grossProfit }
    }
    
    private var averageMargin: Double {
        if totalRevenue == 0 {
            return 0
        }
        return (totalProfit / totalRevenue) * 100
    }
    
    private var averageDealSize: Double {
        if wonProposals.isEmpty {
            return 0
        }
        return totalRevenue / Double(wonProposals.count)
    }
    
    // Top customer insight
    private struct CustomerInsight {
        let name: String
        let value: Double
    }
    
    private var topCustomer: CustomerInsight {
        // Group proposals by customer and sum values
        var customerRevenue: [String: Double] = [:]
        
        for proposal in wonProposals {
            let customerName = proposal.customerName
            customerRevenue[customerName, default: 0] += proposal.totalAmount
        }
        
        // Find the customer with highest revenue
        if let topEntry = customerRevenue.max(by: { $0.value < $1.value }) {
            return CustomerInsight(name: topEntry.key, value: topEntry.value)
        }
        
        return CustomerInsight(name: "None", value: 0)
    }
    
    // Top product insight
    private struct ProductInsight {
        let name: String
        let count: Int
        let value: Double
    }
    
    private var topProduct: ProductInsight {
        // This would require deeper data access than available
        // Using sample data for demonstration
        return ProductInsight(name: "Imaging System", count: 5, value: 6249.99)
    }
    
    // Forecasting 
    private var forecastValue: Double {
        // Simple forecast based on current trend
        if chartData.count < 2 {
            return averageValue * 1.1 // Default 10% growth if insufficient data
        }
        
        // Calculate the average growth rate
        var growthRates: [Double] = []
        for i in 1..<chartData.count {
            let previousValue = chartData[i-1].value
            let currentValue = chartData[i].value
            
            if previousValue > 0 {
                let growthRate = (currentValue - previousValue) / previousValue
                growthRates.append(growthRate)
            }
        }
        
        if growthRates.isEmpty {
            return averageValue * 1.1
        }
        
        let avgGrowthRate = growthRates.reduce(0, +) / Double(growthRates.count)
        return chartData.last?.value ?? 0 * (1 + avgGrowthRate)
    }
    
    private var forecastGrowth: Double {
        if chartData.isEmpty || chartData.last?.value == 0 {
            return 10 // Default 10% growth
        }
        
        return ((forecastValue - (chartData.last?.value ?? 0)) / (chartData.last?.value ?? 1)) * 100
    }
    
    // Profitability insights
    private struct ProfitInsight {
        let name: String
        let profit: Double
        let margin: Double
    }
    
    private var topProfitableProposal: ProfitInsight {
        if wonProposals.isEmpty {
            return ProfitInsight(name: "None", profit: 0, margin: 0)
        }
        
        if let top = wonProposals.max(by: { $0.grossProfit < $1.grossProfit }) {
            return ProfitInsight(
                name: top.formattedNumber,
                profit: top.grossProfit,
                margin: top.profitMargin
            )
        }
        
        return ProfitInsight(name: "None", profit: 0, margin: 0)
    }
    
    private var lowestProfitableProposal: ProfitInsight {
        if wonProposals.isEmpty {
            return ProfitInsight(name: "None", profit: 0, margin: 0)
        }
        
        if let lowest = wonProposals.min(by: { $0.grossProfit < $1.grossProfit }) {
            return ProfitInsight(
                name: lowest.formattedNumber,
                profit: lowest.grossProfit,
                margin: lowest.profitMargin
            )
        }
        
        return ProfitInsight(name: "None", profit: 0, margin: 0)
    }
    
    private var overallProfitRatio: Double {
        if totalRevenue == 0 {
            return 0
        }
        return totalProfit / totalRevenue
    }
    
    // Margin insights
    private struct MarginInsight {
        let name: String
        let value: Double
        let margin: Double
    }
    
    private var highestMargin: MarginInsight {
        if wonProposals.isEmpty {
            return MarginInsight(name: "None", value: 0, margin: 0)
        }
        
        if let highest = wonProposals.max(by: { $0.profitMargin < $1.profitMargin }) {
            return MarginInsight(
                name: highest.formattedNumber,
                value: highest.totalAmount,
                margin: highest.profitMargin
            )
        }
        
        return MarginInsight(name: "None", value: 0, margin: 0)
    }
    
    private var lowestMargin: MarginInsight {
        if wonProposals.isEmpty {
            return MarginInsight(name: "None", value: 0, margin: 0)
        }
        
        if let lowest = wonProposals.min(by: { $0.profitMargin < $1.profitMargin }) {
            return MarginInsight(
                name: lowest.formattedNumber,
                value: lowest.totalAmount,
                margin: lowest.profitMargin
            )
        }
        
        return MarginInsight(name: "None", value: 0, margin: 0)
    }
    
    // Engineering vs product margin (simulated)
    private var engineeringMargin: Double {
        // This would require more detailed data access than available
        // Using sample values for demonstration
        return 32.5
    }
    
    private var productMargin: Double {
        // This would require more detailed data access than available
        // Using sample values for demonstration
        return 24.8
    }
    
    // Deal size insights
    private struct DealInsight {
        let name: String
        let value: Double
        let date: String
    }
    
    private var largestDeal: DealInsight {
        if wonProposals.isEmpty {
            return DealInsight(name: "None", value: 0, date: "")
        }
        
        if let largest = wonProposals.max(by: { $0.totalAmount < $1.totalAmount }) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateStr = largest.creationDate != nil ? 
                dateFormatter.string(from: largest.creationDate!) : ""
            
            return DealInsight(
                name: largest.formattedNumber,
                value: largest.totalAmount,
                date: dateStr
            )
        }
        
        return DealInsight(name: "None", value: 0, date: "")
    }
    
    private var dealSizeGrowth: Double {
        // Calculate growth compared to previous period
        // This is simplified and would need real historical data
        return 8.7
    }
    
    // MARK: - Formatters
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}



struct FinancialMetricsChartView_Previews: PreviewProvider {
    static var previews: some View {
        FinancialMetricsChartView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
