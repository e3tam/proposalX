//
//  FinancialRatioCard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


import SwiftUI

struct FinancialRatioCard: View {
    let title: String
    let value: Double
    let targetValue: Double?
    let valueFormatter: (Double) -> String
    let description: String
    let iconName: String
    let valueIncreasingIsGood: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and icon
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(statusColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(statusColor.opacity(0.2))
                    )
            }
            
            // Value display
            HStack(alignment: .firstTextBaseline) {
                Text(valueFormatter(value))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)
                
                if let targetValue = targetValue {
                    Spacer()
                    
                    // Show comparison to target
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: value >= targetValue ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(value >= targetValue ? .green : .orange)
                        
                        Text("Target: \(valueFormatter(targetValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // Progress visualization
            if let targetValue = targetValue {
                ProgressBarView(
                    value: value,
                    targetValue: targetValue,
                    maximumValue: max(value, targetValue) * 1.5,
                    valueIncreasingIsGood: valueIncreasingIsGood
                )
                .frame(height: 6)
                .padding(.vertical, 4)
            }
            
            // Description
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    // Determine color based on value and direction
    private var statusColor: Color {
        guard let targetValue = targetValue else {
            return .blue // Default if no target
        }
        
        if valueIncreasingIsGood {
            if value >= targetValue * 1.2 {
                return .green
            } else if value >= targetValue * 0.8 {
                return .blue
            } else {
                return .red
            }
        } else {
            if value <= targetValue * 0.8 {
                return .green
            } else if value <= targetValue * 1.2 {
                return .blue
            } else {
                return .red
            }
        }
    }
}

// Progress bar component for visualizing ratio compared to target
struct ProgressBarView: View {
    let value: Double
    let targetValue: Double
    let maximumValue: Double
    let valueIncreasingIsGood: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
                
                // Value bar
                let width = min((value / maximumValue) * geometry.size.width, geometry.size.width)
                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor)
                    .frame(width: max(width, 0), height: 6)
                
                // Target marker
                if targetValue > 0 && targetValue <= maximumValue {
                    let targetX = (targetValue / maximumValue) * geometry.size.width
                    Rectangle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 10)
                        .position(x: targetX, y: 3)
                }
            }
        }
    }
    
    // Color gradient based on progress
    private var progressColor: Color {
        if valueIncreasingIsGood {
            return value >= targetValue ? .green : (value >= targetValue * 0.7 ? .blue : .red)
        } else {
            return value <= targetValue ? .green : (value <= targetValue * 1.3 ? .blue : .red)
        }
    }
}

// Financial ratio grid for displaying multiple related ratios
struct FinancialRatioGrid: View {
    let ratios: [FinancialRatioViewModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Financial Ratios")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ratios) { ratio in
                    FinancialRatioCard(
                        title: ratio.title,
                        value: ratio.value,
                        targetValue: ratio.targetValue,
                        valueFormatter: ratio.formatter,
                        description: ratio.description,
                        iconName: ratio.iconName,
                        valueIncreasingIsGood: ratio.valueIncreasingIsGood
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// View model for financial ratios
struct FinancialRatioViewModel: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let targetValue: Double?
    let formatter: (Double) -> String
    let description: String
    let iconName: String
    let valueIncreasingIsGood: Bool
    
    init(
        title: String,
        value: Double,
        targetValue: Double? = nil,
        formatter: @escaping (Double) -> String = { String(format: "%.1f", $0) },
        description: String,
        iconName: String,
        valueIncreasingIsGood: Bool = true
    ) {
        self.title = title
        self.value = value
        self.targetValue = targetValue
        self.formatter = formatter
        self.description = description
        self.iconName = iconName
        self.valueIncreasingIsGood = valueIncreasingIsGood
    }
}

// Preview for the financial ratio components
struct FinancialRatioCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                FinancialRatioCard(
                    title: "Profit Margin",
                    value: 42.5,
                    targetValue: 35.0,
                    valueFormatter: Formatters.formatPercent,
                    description: "The percentage of revenue that remains as profit after expenses",
                    iconName: "chart.pie.fill",
                    valueIncreasingIsGood: true
                )
                
                FinancialRatioCard(
                    title: "Discount Rate",
                    value: 18.3,
                    targetValue: 15.0,
                    valueFormatter: Formatters.formatPercent,
                    description: "Average discount offered to customers",
                    iconName: "tag.fill",
                    valueIncreasingIsGood: false
                )
                
                FinancialRatioGrid(
                    ratios: [
                        FinancialRatioViewModel(
                            title: "Profit Margin",
                            value: 42.5,
                            targetValue: 35.0,
                            formatter: Formatters.formatPercent,
                            description: "Revenue remaining as profit after expenses",
                            iconName: "chart.pie.fill"
                        ),
                        FinancialRatioViewModel(
                            title: "Return on Investment",
                            value: 68.7,
                            targetValue: 50.0,
                            formatter: Formatters.formatPercent,
                            description: "Profit relative to costs",
                            iconName: "arrow.up.right"
                        ),
                        FinancialRatioViewModel(
                            title: "Discount Rate",
                            value: 18.3,
                            targetValue: 15.0,
                            formatter: Formatters.formatPercent,
                            description: "Average discount offered",
                            iconName: "tag.fill",
                            valueIncreasingIsGood: false
                        ),
                        FinancialRatioViewModel(
                            title: "Engineering %",
                            value: 22.5,
                            targetValue: 25.0,
                            formatter: Formatters.formatPercent,
                            description: "Engineering as % of revenue",
                            iconName: "wrench.and.screwdriver.fill"
                        )
                    ]
                )
            }
            .padding()
        }
    }
}