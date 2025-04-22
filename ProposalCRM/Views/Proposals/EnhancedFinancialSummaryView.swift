// EnhancedFinancialSummaryView.swift
// Detailed financial view separated from the main proposal view to improve build performance

import SwiftUI
import CoreData

struct EnhancedFinancialSummaryView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header Summary
                headerSummarySection
                
                // MARK: - Revenue Breakdown
                revenueBreakdownSection
                
                // MARK: - Cost Structure
                costBreakdownSection
                
                // MARK: - Financial Ratios
                financialRatiosSection
                
                // MARK: - Performance Comparison
                performanceComparisonSection
            }
            .padding()
        }
        .navigationTitle("Financial Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    // MARK: - Section Views
    
    private var headerSummarySection: some View {
        VStack(spacing: 16) {
            Text("Financial Summary")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Key metrics cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard(
                    title: "Total Revenue",
                    value: Formatters.formatEuro(proposal.totalAmount),
                    subtitle: "All revenue sources",
                    icon: "dollarsign.circle.fill",
                    trendUp: true
                )
                
                metricCard(
                    title: "Total Cost",
                    value: Formatters.formatEuro(proposal.totalCost),
                    subtitle: "Products & expenses",
                    icon: "cart.fill",
                    trendUp: false
                )
                
                metricCard(
                    title: "Gross Profit",
                    value: Formatters.formatEuro(proposal.grossProfit),
                    subtitle: "Revenue - Costs",
                    icon: "chart.line.uptrend.xyaxis",
                    trendUp: proposal.grossProfit > 0
                )
                
                metricCard(
                    title: "Profit Margin",
                    value: Formatters.formatPercent(proposal.profitMargin),
                    subtitle: "Profit ÷ Revenue",
                    icon: "percent",
                    trendUp: proposal.profitMargin > 30
                )
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(15)
    }
    
    private var revenueBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Revenue Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            pieChartView(
                products: proposal.subtotalProducts,
                engineering: proposal.subtotalEngineering,
                expenses: proposal.subtotalExpenses,
                taxes: proposal.subtotalTaxes
            )
            .frame(height: 240)
            
            // Revenue details
            VStack(spacing: 8) {
                // Products
                if proposal.subtotalProducts > 0 {
                    breakdownRow(
                        name: "Products",
                        value: proposal.subtotalProducts,
                        total: proposal.totalAmount,
                        color: .blue
                    )
                }
                
                // Engineering
                if proposal.subtotalEngineering > 0 {
                    breakdownRow(
                        name: "Engineering",
                        value: proposal.subtotalEngineering,
                        total: proposal.totalAmount,
                        color: .green
                    )
                }
                
                // Expenses
                if proposal.subtotalExpenses > 0 {
                    breakdownRow(
                        name: "Expenses",
                        value: proposal.subtotalExpenses,
                        total: proposal.totalAmount,
                        color: .orange
                    )
                }
                
                // Taxes
                if proposal.subtotalTaxes > 0 {
                    breakdownRow(
                        name: "Taxes",
                        value: proposal.subtotalTaxes,
                        total: proposal.totalAmount,
                        color: .red
                    )
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
            .padding(.top, 8)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(15)
    }
    
    private var costBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Structure")
                .font(.title2)
                .fontWeight(.bold)
            
            // Cost details
            let productsCost = costByType(type: "product")
            let expensesCost = proposal.subtotalExpenses
            let totalCost = proposal.totalCost
            
            VStack(spacing: 10) {
                // Products cost
                if productsCost > 0 {
                    costRow(
                        name: "Product Costs",
                        value: productsCost,
                        total: totalCost,
                        color: .blue
                    )
                }
                
                // Expenses
                if expensesCost > 0 {
                    costRow(
                        name: "Expenses",
                        value: expensesCost,
                        total: totalCost,
                        color: .orange
                    )
                }
                
                Divider()
                
                // Total cost
                HStack {
                    Text("Total Cost")
                        .font(.headline)
                    Spacer()
                    Text(Formatters.formatEuro(totalCost))
                        .font(.headline)
                }
                
                // Cost as percentage of revenue
                let costPercentage = proposal.totalAmount > 0 ?
                    (totalCost / proposal.totalAmount) * 100 : 0
                
                HStack {
                    Text("Cost as % of Revenue")
                        .font(.subheadline)
                    Spacer()
                    Text(Formatters.formatPercent(costPercentage))
                        .font(.subheadline)
                        .foregroundColor(costPercentage < 70 ? .green : .red)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(15)
    }
    
    private var financialRatiosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Ratios")
                .font(.title2)
                .fontWeight(.bold)
            
            // Profit margin
            ratioRow(
                title: "Profit Margin",
                value: proposal.profitMargin,
                target: 35.0,
                formatter: Formatters.formatPercent,
                description: "Revenue remaining as profit after expenses",
                icon: "chart.pie.fill",
                valueIncreasingIsGood: true
            )
            
            // ROI
            let totalCost = proposal.totalCost
            let grossProfit = proposal.grossProfit
            let roi = totalCost > 0 ? (grossProfit / totalCost) * 100 : 0
            
            ratioRow(
                title: "Return on Investment",
                value: roi,
                target: 40.0,
                formatter: Formatters.formatPercent,
                description: "Profit relative to costs",
                icon: "arrow.up.right",
                valueIncreasingIsGood: true
            )
            
            // Average discount
            let totalDiscount = proposal.itemsArray.reduce(0.0) { $0 + $1.discount }
            let avgDiscount = proposal.itemsArray.isEmpty ? 0 : totalDiscount / Double(proposal.itemsArray.count)
            
            ratioRow(
                title: "Average Discount",
                value: avgDiscount,
                target: 15.0,
                formatter: Formatters.formatPercent,
                description: "Average discount offered",
                icon: "tag.fill",
                valueIncreasingIsGood: false
            )
            
            // Engineering percentage
            let engineeringPercent = proposal.totalAmount > 0 ?
                                  (proposal.subtotalEngineering / proposal.totalAmount) * 100 : 0
            
            ratioRow(
                title: "Engineering %",
                value: engineeringPercent,
                target: 20.0,
                formatter: Formatters.formatPercent,
                description: "Engineering as % of revenue",
                icon: "wrench.and.screwdriver.fill",
                valueIncreasingIsGood: true
            )
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(15)
    }
    
    private var performanceComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Comparison")
                .font(.title2)
                .fontWeight(.bold)
            
            // Revenue comparison
            let targetRevenue = 25000.0 // Example target
            comparisonRow(
                title: "Total Revenue",
                actualValue: proposal.totalAmount,
                targetValue: targetRevenue,
                formatter: Formatters.formatEuro,
                description: "Total revenue from all sources"
            )
            
            // Profit comparison
            let targetProfit = 8750.0 // Example target (35% margin)
            comparisonRow(
                title: "Gross Profit",
                actualValue: proposal.grossProfit,
                targetValue: targetProfit,
                formatter: Formatters.formatEuro,
                description: "Gross profit after all costs"
            )
            
            // Margin comparison
            let targetMargin = 35.0 // Example target percentage
            comparisonRow(
                title: "Profit Margin",
                actualValue: proposal.profitMargin,
                targetValue: targetMargin,
                formatter: Formatters.formatPercent,
                description: "Percentage of revenue retained as profit"
            )
            
            // Overall performance indicator
            overallPerformanceIndicator(
                revenue: proposal.totalAmount,
                profit: proposal.grossProfit,
                margin: proposal.profitMargin,
                targetRevenue: targetRevenue,
                targetProfit: targetProfit,
                targetMargin: targetMargin
            )
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(15)
    }
    
    // MARK: - Helper Components
    
    private func metricCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        trendUp: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row with icon
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(trendUp ? .green : .red)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Main value with large, bold font
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(trendUp ? .green : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Subtitle
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ?
                      Color(.systemGray5).opacity(0.8) :
                      Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(colorScheme == .dark ?
                             Color(.systemGray4).opacity(0.5) :
                             Color(.systemGray3).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func pieChartView(
        products: Double,
        engineering: Double,
        expenses: Double,
        taxes: Double
    ) -> some View {
        // Simple placeholder for pie chart
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
            
            Text("Pie Chart\nPlaceholder")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
    }
    
    private func breakdownRow(
        name: String,
        value: Double,
        total: Double,
        color: Color
    ) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Text(Formatters.formatPercent((value / total) * 100))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(Formatters.formatEuro(value))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func costRow(
        name: String,
        value: Double,
        total: Double,
        color: Color
    ) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Text(Formatters.formatPercent((value / total) * 100))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(Formatters.formatEuro(value))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func ratioRow(
        title: String,
        value: Double,
        target: Double,
        formatter: (Double) -> String,
        description: String,
        icon: String,
        valueIncreasingIsGood: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(ratioColor(value: value, target: target, increasing: valueIncreasingIsGood))
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(formatter(value))
                    .font(.headline)
                    .foregroundColor(ratioColor(value: value, target: target, increasing: valueIncreasingIsGood))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    // Target marker
                    Rectangle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 10)
                        .position(x: min((target / 100) * geometry.size.width, geometry.size.width), y: 3)
                    
                    // Value bar
                    Rectangle()
                        .fill(ratioColor(value: value, target: target, increasing: valueIncreasingIsGood))
                        .frame(width: min((value / 100) * geometry.size.width, geometry.size.width), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            // Target info
            HStack {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Target: \(formatter(target))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .opacity(0.7)
        )
    }
    
    private func comparisonRow(
        title: String,
        actualValue: Double,
        targetValue: Double,
        formatter: (Double) -> String,
        description: String
    ) -> some View {
        let difference = actualValue - targetValue
        let percentageDifference = targetValue != 0 ? (difference / targetValue) * 100 : 0
        let isPositiveDifference = difference >= 0
        
        return VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatter(actualValue))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatter(targetValue))
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            
            // Difference
            HStack {
                Text("Difference:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Absolute difference
                Text(formatter(difference))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositiveDifference ? .green : .red)
                
                // Percentage difference
                Text("(\(isPositiveDifference ? "+" : "")\(String(format: "%.1f", percentageDifference))%)")
                    .font(.caption)
                    .foregroundColor(isPositiveDifference ? .green : .red)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill((isPositiveDifference ? Color.green : Color.red).opacity(0.15))
            )
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .opacity(0.7)
        )
    }
    
    private func overallPerformanceIndicator(
        revenue: Double,
        profit: Double,
        margin: Double,
        targetRevenue: Double,
        targetProfit: Double,
        targetMargin: Double
    ) -> some View {
        // Calculate overall performance
        var positiveCount = 0
        
        if revenue >= targetRevenue { positiveCount += 1 }
        if profit >= targetProfit { positiveCount += 1 }
        if margin >= targetMargin { positiveCount += 1 }
        
        let percentage = Double(positiveCount) / 3.0
        
        let (text, color) = {
            if percentage >= 0.8 {
                return ("Excellent", Color.green)
            } else if percentage >= 0.5 {
                return ("Good", Color.blue)
            } else if percentage >= 0.3 {
                return ("Needs Improvement", Color.orange)
            } else {
                return ("Below Expectations", Color.red)
            }
        }()
        
        return Text("Overall performance: \(text)")
            .font(.subheadline)
            .foregroundColor(color)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
            )
    }
    
    // MARK: - Helper Methods
    
    private func costByType(type: String) -> Double {
        if type == "product" {
            return proposal.itemsArray.reduce(0.0) { total, item in
                return total + ((item.product?.partnerPrice ?? 0) * item.quantity)
            }
        }
        return 0
    }
    
    private func ratioColor(value: Double, target: Double, increasing: Bool) -> Color {
        if increasing {
            if value >= target * 1.2 {
                return .green
            } else if value >= target * 0.8 {
                return .blue
            } else {
                return .red
            }
        } else {
            if value <= target * 0.8 {
                return .green
            } else if value <= target * 1.2 {
                return .blue
            } else {
                return .red
            }
        }
    }
}