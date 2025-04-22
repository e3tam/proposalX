//
//  FinancialComparisonCard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


import SwiftUI

struct FinancialComparisonCard: View {
    let title: String
    let actualValue: Double
    let targetValue: Double
    let valueFormatter: (Double) -> String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    
    private var difference: Double {
        actualValue - targetValue
    }
    
    private var percentageDifference: Double {
        targetValue != 0 ? (difference / targetValue) * 100 : 0
    }
    
    private var isPositiveDifference: Bool {
        difference >= 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Actual vs Target display
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(valueFormatter(actualValue))
                        .font(.system(size: 20, weight: .bold))
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
                    
                    Text(valueFormatter(targetValue))
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            
            // Difference
            HStack {
                // Label
                Text("Difference:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Absolute difference
                Text(valueFormatter(difference))
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
                    .fill(differenceColor.opacity(0.15))
            )
            
            // Progress visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Target line
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Actual progress
                    let maxValue = max(actualValue, targetValue) * 1.2
                    let width = min((actualValue / maxValue) * geometry.size.width, geometry.size.width)
                    
                    Rectangle()
                        .fill(differenceColor)
                        .frame(width: max(width, 1), height: 8)
                        .cornerRadius(4)
                    
                    // Target marker
                    let targetX = (targetValue / maxValue) * geometry.size.width
                    Rectangle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 16)
                        .cornerRadius(1)
                        .position(x: targetX, y: 4)
                }
            }
            .frame(height: 8)
            .padding(.top, 4)
            
            // Description
            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    private var differenceColor: Color {
        if percentageDifference >= 5 {
            return .green
        } else if percentageDifference <= -5 {
            return .red
        } else {
            return .orange
        }
    }
}

struct FinancialComparisonSection: View {
    let actualValues: [String: Double]
    let targetValues: [String: Double]
    let descriptions: [String: String]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Financial Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            // Each comparison category in a grid
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                // Revenue
                if let actualRevenue = actualValues["Revenue"],
                   let targetRevenue = targetValues["Revenue"] {
                    FinancialComparisonCard(
                        title: "Total Revenue",
                        actualValue: actualRevenue,
                        targetValue: targetRevenue,
                        valueFormatter: Formatters.formatEuro,
                        description: descriptions["Revenue"] ?? ""
                    )
                }
                
                // Profit
                if let actualProfit = actualValues["Profit"],
                   let targetProfit = targetValues["Profit"] {
                    FinancialComparisonCard(
                        title: "Gross Profit",
                        actualValue: actualProfit,
                        targetValue: targetProfit,
                        valueFormatter: Formatters.formatEuro,
                        description: descriptions["Profit"] ?? ""
                    )
                }
                
                // Margin
                if let actualMargin = actualValues["Margin"],
                   let targetMargin = targetValues["Margin"] {
                    FinancialComparisonCard(
                        title: "Profit Margin",
                        actualValue: actualMargin,
                        targetValue: targetMargin,
                        valueFormatter: Formatters.formatPercent,
                        description: descriptions["Margin"] ?? ""
                    )
                }
            }
            
            // Summary text
            let overallPerformance = calculateOverallPerformance()
            Text("Overall performance: \(overallPerformance.text)")
                .font(.subheadline)
                .foregroundColor(overallPerformance.color)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(overallPerformance.color.opacity(0.1))
                )
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Calculate overall performance based on all metrics
    private func calculateOverallPerformance() -> (text: String, color: Color) {
        var positiveCount = 0
        var totalCount = 0
        
        // Check each metric
        if let actualRevenue = actualValues["Revenue"],
           let targetRevenue = targetValues["Revenue"] {
            totalCount += 1
            if actualRevenue >= targetRevenue {
                positiveCount += 1
            }
        }
        
        if let actualProfit = actualValues["Profit"],
           let targetProfit = targetValues["Profit"] {
            totalCount += 1
            if actualProfit >= targetProfit {
                positiveCount += 1
            }
        }
        
        if let actualMargin = actualValues["Margin"],
           let targetMargin = targetValues["Margin"] {
            totalCount += 1
            if actualMargin >= targetMargin {
                positiveCount += 1
            }
        }
        
        // Determine overall performance
        let percentage = totalCount > 0 ? Double(positiveCount) / Double(totalCount) : 0
        
        if percentage >= 0.8 {
            return ("Excellent", .green)
        } else if percentage >= 0.5 {
            return ("Good", .blue)
        } else if percentage >= 0.3 {
            return ("Needs Improvement", .orange)
        } else {
            return ("Below Expectations", .red)
        }
    }
}

// Preview for the financial comparison components
struct FinancialComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                FinancialComparisonCard(
                    title: "Total Revenue",
                    actualValue: 132750,
                    targetValue: 120000,
                    valueFormatter: Formatters.formatEuro,
                    description: "Comparing actual revenue to quarterly target"
                )
                
                FinancialComparisonCard(
                    title: "Profit Margin",
                    actualValue: 32.5,
                    targetValue: 35.0,
                    valueFormatter: Formatters.formatPercent,
                    description: "Margin is slightly below target due to increased costs"
                )
                
                FinancialComparisonSection(
                    actualValues: [
                        "Revenue": 132750,
                        "Profit": 43143.75,
                        "Margin": 32.5
                    ],
                    targetValues: [
                        "Revenue": 120000,
                        "Profit": 42000,
                        "Margin": 35.0
                    ],
                    descriptions: [
                        "Revenue": "Total revenue from all sources",
                        "Profit": "Gross profit after all costs",
                        "Margin": "Percentage of revenue retained as profit"
                    ]
                )
            }
            .padding()
        }
    }
}