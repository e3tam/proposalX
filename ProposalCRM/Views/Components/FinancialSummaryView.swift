// File: ProposalCRM/Views/Components/FinancialSummaryView.swift
// Detailed financial analysis of a proposal - UPDATED for Euro Formatting

import SwiftUI
import Charts // Ensure Charts framework is imported if used

struct FinancialSummaryDetailView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Computed properties for financial analysis (no changes needed here)
    var productsByCategory: [(category: String, total: Double)] {
        var categoryTotals: [String: Double] = [:]
        for item in proposal.itemsArray {
            categoryTotals[item.product?.category ?? "Uncategorized", default: 0] += item.amount
        }
        return categoryTotals.map { ($0.key, $0.value) }.sorted { $0.total > $1.total }
    }

    var totalCostBreakdown: [(name: String, value: Double, color: Color)] {
        var costs: [(String, Double, Color)] = []
        let productsCost = proposal.itemsArray.reduce(0.0) { total, item in
            total + ((item.product?.partnerPrice ?? 0) * item.quantity)
        }
        if productsCost > 0 { costs.append(("Products", productsCost, .blue)) }
        if proposal.subtotalExpenses > 0 { costs.append(("Expenses", proposal.subtotalExpenses, .orange)) }
        // Add Engineering cost if applicable? Assumed profit for now.
        return costs
    }

    var profitByProductCategory: [(category: String, profit: Double, margin: Double)] {
        var categoryData: [String: (revenue: Double, cost: Double)] = [:]
        for item in proposal.itemsArray {
            let category = item.product?.category ?? "Uncategorized"
            let partnerCost = (item.product?.partnerPrice ?? 0) * item.quantity
            categoryData[category, default: (0, 0)].revenue += item.amount
            categoryData[category, default: (0, 0)].cost += partnerCost
        }
        return categoryData.map { category, values in
            let profit = values.revenue - values.cost
            let margin = values.revenue > 0 ? (profit / values.revenue) * 100 : 0
            return (category, profit, margin)
        }.sorted { $0.profit > $1.profit }
    }

    var averageDiscountByCategory: [(category: String, avgDiscount: Double)] {
        var categoryDiscounts: [String: [Double]] = [:]
        for item in proposal.itemsArray {
            categoryDiscounts[item.product?.category ?? "Uncategorized", default: []].append(item.discount)
        }
        return categoryDiscounts.map { category, discounts in
            let totalDiscount = discounts.reduce(0, +)
            let avgDiscount = discounts.isEmpty ? 0 : totalDiscount / Double(discounts.count)
            return (category, avgDiscount)
        }.sorted { $0.avgDiscount > $1.avgDiscount }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    overallSummarySection
                    revenueBreakdownSection
                    productCategoryPerformanceSection
                    costStructureSection
                    profitAnalysisSection
                    discountAnalysisSection
                    taxBreakdownSection
                    engineeringAnalysisSection
                    keyFinancialIndicatorsSection
                }
                .padding()
            }
            .navigationTitle("Financial Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack) // Use stack style for better modal presentation
    }

    // MARK: - Component Sections (UPDATED formatting)

    private var overallSummarySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                SummaryMetricCard(
                    title: "Total Revenue",
                    value: Formatters.formatEuro(proposal.totalAmount), // UPDATED
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )
                SummaryMetricCard(
                    title: "Total Cost",
                    value: Formatters.formatEuro(proposal.totalCost), // UPDATED
                    icon: "arrow.down.circle.fill",
                    color: .red
                )
                SummaryMetricCard(
                    title: "Gross Profit",
                    value: Formatters.formatEuro(proposal.grossProfit), // UPDATED
                    icon: "chart.line.uptrend.xyaxis",
                    color: proposal.grossProfit >= 0 ? .green : .red
                )
                SummaryMetricCard(
                    title: "Profit Margin",
                    value: Formatters.formatPercent(proposal.profitMargin), // UPDATED
                    icon: "percent",
                    color: proposal.profitMargin > 30 ? .green : (proposal.profitMargin > 15 ? .orange : .red)
                )
            }
        }
    }

    private var revenueBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Revenue Breakdown").font(.title2).fontWeight(.bold)
            if #available(iOS 16.0, *) {
                Chart { // Chart data remains Double
                    // ... SectorMarks ...
                }
                .frame(height: 250)
            }
            VStack(spacing: 10) { // Use updated RevenueRow
                RevenueRow(title: "Products", value: proposal.subtotalProducts, total: proposal.totalAmount, color: .blue)
                RevenueRow(title: "Engineering", value: proposal.subtotalEngineering, total: proposal.totalAmount, color: .green)
                RevenueRow(title: "Expenses", value: proposal.subtotalExpenses, total: proposal.totalAmount, color: .orange)
                RevenueRow(title: "Taxes", value: proposal.subtotalTaxes, total: proposal.totalAmount, color: .red)
            }
        }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
    }

    private var productCategoryPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Product Category Performance").font(.title2).fontWeight(.bold)
            if #available(iOS 16.0, *) {
                Chart { // Chart data remains Double
                    // ... BarMarks ...
                }
                .frame(height: 250)
            }
            ForEach(productsByCategory, id: \.category) { item in // Use updated CategoryDetailRow
                CategoryDetailRow(category: item.category, revenue: item.total, percentage: proposal.subtotalProducts > 0 ? (item.total / proposal.subtotalProducts) * 100 : 0)
            }
        }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
    }

     private var costStructureSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Cost Structure").font(.title2).fontWeight(.bold)
             if #available(iOS 16.0, *) {
                Chart { // Chart data remains Double
                    // ... SectorMarks ...
                }
                .frame(height: 200)
             }
             ForEach(totalCostBreakdown, id: \.name) { item in // Use updated CostRow
                 CostRow(title: item.name, value: item.value, percentage: proposal.totalCost > 0 ? (item.value / proposal.totalCost) * 100 : 0, color: item.color)
             }
        }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
    }

     private var profitAnalysisSection: some View {
         VStack(alignment: .leading, spacing: 15) {
             Text("Profit Analysis by Category").font(.title2).fontWeight(.bold)
             if #available(iOS 16.0, *) {
                 Chart { // Chart data remains Double
                    // ... BarMarks ...
                 }
                 .frame(height: 250)
             }
             ForEach(profitByProductCategory, id: \.category) { item in // Use updated ProfitRow
                 ProfitRow(category: item.category, profit: item.profit, margin: item.margin)
             }
         }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
     }

     private var discountAnalysisSection: some View {
         VStack(alignment: .leading, spacing: 15) {
             Text("Discount Analysis").font(.title2).fontWeight(.bold)
              if #available(iOS 16.0, *) {
                 Chart { // Chart data remains Double
                    // ... BarMarks ...
                 }
                 .frame(height: 200)
              }
              ForEach(averageDiscountByCategory, id: \.category) { item in // Use updated DiscountRow
                  DiscountRow(category: item.category, avgDiscount: item.avgDiscount)
              }
         }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
     }

     private var taxBreakdownSection: some View {
         VStack(alignment: .leading, spacing: 15) {
             Text("Tax Breakdown").font(.title2).fontWeight(.bold)
             if proposal.taxesArray.isEmpty {
                 Text("No taxes applied").foregroundColor(.secondary)
             } else {
                 ForEach(proposal.taxesArray, id: \.id) { tax in // Use updated TaxDetailRow
                     TaxDetailRow(tax: tax, subtotal: proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses)
                 }
                 HStack {
                     Text("Total Taxes").font(.headline)
                     Spacer()
                     Text(Formatters.formatEuro(proposal.subtotalTaxes)) // UPDATED
                         .font(.headline)
                 }.padding(.top, 10)
             }
         }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
     }

     private var engineeringAnalysisSection: some View {
         VStack(alignment: .leading, spacing: 15) {
             Text("Engineering Services").font(.title2).fontWeight(.bold)
             if proposal.engineeringArray.isEmpty {
                 Text("No engineering services").foregroundColor(.secondary)
             } else {
                 let totalDays = proposal.engineeringArray.reduce(0.0) { $0 + $1.days }
                 let avgRate = totalDays > 0 ? proposal.subtotalEngineering / totalDays : 0
                 HStack { // Use updated SummaryMetricCard
                     SummaryMetricCard(title: "Total Days", value: String(format: "%.1f", totalDays), icon: "calendar", color: .green)
                     SummaryMetricCard(title: "Avg Daily Rate", value: Formatters.formatEuro(avgRate), icon: "dollarsign.circle", color: .blue) // UPDATED
                 }
                 ForEach(proposal.engineeringArray, id: \.id) { engineering in // Use updated EngineeringDetailRow
                     EngineeringDetailRow(engineering: engineering)
                 }
             }
         }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
     }

     private var keyFinancialIndicatorsSection: some View {
         VStack(alignment: .leading, spacing: 15) {
             Text("Key Financial Indicators").font(.title2).fontWeight(.bold)
             let avgMarginPerProduct = proposal.itemsArray.isEmpty ? 0 : proposal.grossProfit / Double(proposal.itemsArray.count)
             let totalDiscount = proposal.itemsArray.reduce(0.0) { $0 + $1.discount }
             let avgDiscount = proposal.itemsArray.isEmpty ? 0 : totalDiscount / Double(proposal.itemsArray.count)
             let productCategoriesCount = Set(proposal.itemsArray.compactMap { $0.product?.category }).count
             let revPerCategory = productCategoriesCount > 0 ? proposal.subtotalProducts / Double(productCategoriesCount) : 0
             let engPercent = proposal.totalAmount > 0 ? (proposal.subtotalEngineering / proposal.totalAmount) * 100 : 0
             let expPercent = proposal.totalAmount > 0 ? (proposal.subtotalExpenses / proposal.totalAmount) * 100 : 0
             let taxBase = proposal.totalAmount - proposal.subtotalTaxes
             let taxRate = taxBase > 0 ? (proposal.subtotalTaxes / taxBase) * 100 : 0

             VStack(spacing: 10) { // Use updated KPIRow
                 KPIRow(title: "Avg Margin per Product", value: Formatters.formatEuro(avgMarginPerProduct)) // UPDATED
                 KPIRow(title: "Avg Product Discount", value: Formatters.formatPercent(avgDiscount)) // UPDATED
                 KPIRow(title: "Revenue per Category", value: Formatters.formatEuro(revPerCategory)) // UPDATED
                 KPIRow(title: "Engineering % of Revenue", value: Formatters.formatPercent(engPercent)) // UPDATED
                 KPIRow(title: "Expenses % of Revenue", value: Formatters.formatPercent(expPercent)) // UPDATED
                 KPIRow(title: "Effective Tax Rate", value: Formatters.formatPercent(taxRate)) // UPDATED
             }
         }.padding().background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 2)
     }
}

// MARK: - Supporting Views (UPDATED formatting)

struct SummaryMetricCard: View { // Now takes String value
    let title: String
    let value: String // Changed from Double
    let icon: String
    let color: Color
    // Removed subtitle as it wasn't used consistently

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Text(value) // Display pre-formatted string
                .font(.title3).fontWeight(.bold).lineLimit(1)
        }
        .padding().frame(width: 150).background(Color(UIColor.secondarySystemBackground)).cornerRadius(10)
    }
}

struct RevenueRow: View {
    let title: String
    let value: Double
    let total: Double
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(title).font(.subheadline)
            Spacer()
            Text(Formatters.formatPercent((value / max(total, 1)) * 100)) // Use percent formatter, prevent div by zero
                .font(.caption).foregroundColor(.secondary)
            Text(Formatters.formatEuro(value)) // Use Euro formatter
                .font(.subheadline).fontWeight(.semibold).frame(width: 100, alignment: .trailing) // Increased width
        }
    }
}

struct CategoryDetailRow: View {
    let category: String
    let revenue: Double
    let percentage: Double

    var body: some View {
        HStack {
            Text(category).font(.subheadline)
            Spacer()
            Text(Formatters.formatPercent(percentage)) // Use percent formatter
                .font(.caption).foregroundColor(.secondary)
            Text(Formatters.formatEuro(revenue)) // Use Euro formatter
                .font(.subheadline).fontWeight(.semibold).frame(width: 100, alignment: .trailing) // Increased width
        }
    }
}

struct CostRow: View {
    let title: String
    let value: Double
    let percentage: Double
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(title).font(.subheadline)
            Spacer()
            Text(Formatters.formatPercent(percentage)) // Use percent formatter
                .font(.caption).foregroundColor(.secondary)
            Text(Formatters.formatEuro(value)) // Use Euro formatter
                .font(.subheadline).fontWeight(.semibold).frame(width: 100, alignment: .trailing) // Increased width
        }
    }
}

struct ProfitRow: View {
    let category: String
    let profit: Double
    let margin: Double

    var body: some View {
        HStack {
            Text(category).font(.subheadline)
            Spacer()
            Text(Formatters.formatPercent(margin)) // Use percent formatter
                .font(.caption).foregroundColor(margin > 20 ? .green : (margin > 10 ? .orange : .red))
            Text(Formatters.formatEuro(profit)) // Use Euro formatter
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(profit >= 0 ? .green : .red) // Use >= 0
                .frame(width: 100, alignment: .trailing) // Increased width
        }
    }
}

struct DiscountRow: View {
    let category: String
    let avgDiscount: Double

    var body: some View {
        HStack {
            Text(category).font(.subheadline)
            Spacer()
            Text(Formatters.formatPercent(avgDiscount)) // Use percent formatter
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(.orange)
                .frame(width: 80, alignment: .trailing)
        }
    }
}

struct TaxDetailRow: View {
    let tax: CustomTax
    let subtotal: Double // Needed if you want to show effective rate based on subtotal

    var body: some View {
        HStack {
            Text(tax.name ?? "Custom Tax").font(.subheadline)
            Spacer()
            Text(Formatters.formatPercent(tax.rate)) // Use percent formatter
                .font(.caption).foregroundColor(.secondary)
            Text(Formatters.formatEuro(tax.amount)) // Use Euro formatter
                .font(.subheadline).fontWeight(.semibold).frame(width: 100, alignment: .trailing) // Increased width
        }
    }
}

struct EngineeringDetailRow: View {
    let engineering: Engineering

    var body: some View {
        HStack {
            Text(engineering.desc ?? "Engineering Service").font(.subheadline).lineLimit(1) // Added lineLimit
            Spacer()
            Text(String(format: "%.1f days @ %@", engineering.days, Formatters.formatEuro(engineering.rate))) // Use Euro formatter
                .font(.caption).foregroundColor(.secondary)
            Text(Formatters.formatEuro(engineering.amount)) // Use Euro formatter
                .font(.subheadline).fontWeight(.semibold).frame(width: 100, alignment: .trailing) // Increased width
        }
    }
}

struct KPIRow: View { // Keep as is, values are pre-formatted Strings now
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
    }
}
