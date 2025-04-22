import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let trend: String
    let trendUp: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row with icon
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Main value with large, bold font
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Subtitle with optional trend
            HStack(spacing: 4) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if !trend.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: trendUp ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10))
                            .foregroundColor(trendUp ? .green : .red)
                        
                        Text(trend)
                            .font(.caption)
                            .foregroundColor(trendUp ? .green : .red)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(trendUp ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    )
                }
            }
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
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
    
    // Dynamic colors based on context and light/dark mode
    private var iconColor: Color {
        if title.contains("Profit") || title.contains("Margin") {
            return trendUp ? .green : .red
        } else if title.contains("Revenue") || title.contains("Total") {
            return .blue
        } else if title.contains("Cost") || title.contains("Expense") {
            return .orange
        } else {
            return .purple
        }
    }
    
    private var valueColor: Color {
        if title.contains("Profit") || title.contains("Margin") {
            return trendUp ? .green : .red
        } else {
            return colorScheme == .dark ? .white : .primary
        }
    }
    
    private var borderColor: Color {
        return colorScheme == .dark ?
            Color(.systemGray4).opacity(0.5) :
            Color(.systemGray3).opacity(0.3)
    }
}

// Preview for the MetricCard component
struct MetricCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MetricCard(
                    title: "Total Revenue",
                    value: "€24,500.00",
                    subtitle: "All revenue sources",
                    icon: "dollarsign.circle.fill",
                    trend: "+8.5%",
                    trendUp: true
                )
                
                MetricCard(
                    title: "Gross Profit",
                    value: "€12,325.00",
                    subtitle: "50.3% margin",
                    icon: "chart.line.uptrend.xyaxis",
                    trend: "+5.2%",
                    trendUp: true
                )
            }
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Total Cost",
                    value: "€12,175.00",
                    subtitle: "Products & expenses",
                    icon: "cart.fill",
                    trend: "+3.7%",
                    trendUp: false
                )
                
                MetricCard(
                    title: "Profit Margin",
                    value: "50.3%",
                    subtitle: "Goal: 45%",
                    icon: "percent",
                    trend: "+2.1%",
                    trendUp: true
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
