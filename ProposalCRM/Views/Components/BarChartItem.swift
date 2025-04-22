import SwiftUI

struct BarChartItem: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color
    
    init(name: String, value: Double, color: Color = .blue) {
        self.name = name
        self.value = value
        self.color = value >= 0 ? color : .red
    }
}

struct HorizontalBarChart: View {
    let items: [BarChartItem]
    let valueFormatter: (Double) -> String
    var showLabels: Bool = true
    var animateOnAppear: Bool = true
    
    @State private var animationProgress: CGFloat = 0
    
    private var maxAbsValue: Double {
        items.map { abs($0.value) }.max() ?? 1.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    // Category label
                    Text(item.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)
                    
                    // Bar chart
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                            
                            // Value bar
                            let normalizedValue = abs(item.value) / maxAbsValue
                            let width = geometry.size.width * CGFloat(normalizedValue) * animationProgress
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: max(width, 1), height: 20)
                            
                            // Value label
                            if showLabels {
                                HStack {
                                    Spacer()
                                    Text(valueFormatter(item.value))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 8)
                                }
                                .frame(width: geometry.size.width)
                            }
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
}

struct PositiveNegativeBarChart: View {
    let items: [BarChartItem]
    let valueFormatter: (Double) -> String
    var showDividerLine: Bool = true
    var animateOnAppear: Bool = true
    
    @State private var animationProgress: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    private var maxAbsValue: Double {
        items.map { abs($0.value) }.max() ?? 1.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                HStack(spacing: 0) {
                    // Category label
                    Text(item.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)
                    
                    // Bar chart with positive and negative sides
                    GeometryReader { geometry in
                        ZStack(alignment: .center) {
                            // Center divider
                            if showDividerLine {
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                    .frame(width: 1, height: 26)
                            }
                            
                            // Bar position based on positive or negative value
                            let normalizedValue = abs(item.value) / maxAbsValue
                            let barWidth = geometry.size.width * 0.5 * CGFloat(normalizedValue) * animationProgress
                            
                            if item.value >= 0 {
                                // Positive bar on right side
                                HStack {
                                    Spacer(minLength: geometry.size.width/2)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.color)
                                        .frame(width: max(barWidth, 0), height: 20)
                                    Spacer()
                                }
                                
                                // Value label on right side
                                HStack {
                                    Spacer()
                                    Text(valueFormatter(item.value))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 4)
                                }
                            } else {
                                // Negative bar on left side
                                HStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.color)
                                        .frame(width: max(barWidth, 0), height: 20)
                                    Spacer(minLength: geometry.size.width/2)
                                }
                                
                                // Value label on left side
                                HStack {
                                    Text(valueFormatter(item.value))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
}

// Bar chart with labels on top
struct LabeledBarChart: View {
    let items: [BarChartItem]
    let valueFormatter: (Double) -> String
    var showAxis: Bool = true
    var animateOnAppear: Bool = true
    
    @State private var animationProgress: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    private var maxValue: Double {
        items.map { $0.value }.max() ?? 1.0
    }
    
    private var sortedItems: [BarChartItem] {
        items.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // X axis labels
            if showAxis {
                HStack(alignment: .center) {
                    Spacer(minLength: 90) // Width of category label
                    
                    Text("0")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(valueFormatter(maxValue/2))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(valueFormatter(maxValue))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
            
            // Bars
            VStack(spacing: 12) {
                ForEach(sortedItems) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        // Category and value labels
                        HStack {
                            Text(item.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(valueFormatter(item.value))
                                .font(.caption)
                                .foregroundColor(item.color)
                                .fontWeight(.semibold)
                        }
                        
                        // Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                // Value bar
                                let normalizedValue = item.value / maxValue
                                let width = geometry.size.width * CGFloat(normalizedValue) * animationProgress
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.color.opacity(0.8))
                                    .frame(width: max(width, 1), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
}

// Preview of the custom bar charts
struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Horizontal Bar Chart")
                        .font(.headline)
                    
                    HorizontalBarChart(
                        items: [
                            BarChartItem(name: "Product A", value: 12500),
                            BarChartItem(name: "Product B", value: 8750),
                            BarChartItem(name: "Product C", value: 6200),
                            BarChartItem(name: "Product D", value: 3800)
                        ],
                        valueFormatter: { Formatters.formatEuro($0) }
                    )
                    .frame(height: 120)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Positive/Negative Bar Chart")
                        .font(.headline)
                    
                    PositiveNegativeBarChart(
                        items: [
                            BarChartItem(name: "Product A", value: 2850, color: .green),
                            BarChartItem(name: "Product B", value: 1750, color: .green),
                            BarChartItem(name: "Product C", value: -850, color: .green),
                            BarChartItem(name: "Product D", value: -1250, color: .green)
                        ],
                        valueFormatter: { Formatters.formatEuro($0) }
                    )
                    .frame(height: 120)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Labeled Bar Chart")
                        .font(.headline)
                    
                    LabeledBarChart(
                        items: [
                            BarChartItem(name: "Category A", value: 45.8, color: .green),
                            BarChartItem(name: "Category B", value: 32.5, color: .green),
                            BarChartItem(name: "Category C", value: 18.3, color: .orange),
                            BarChartItem(name: "Category D", value: 8.7, color: .red)
                        ],
                        valueFormatter: { Formatters.formatPercent($0) }
                    )
                    .frame(height: 140)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .padding()
        }
    }
}