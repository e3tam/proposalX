import SwiftUI


struct DoughnutChartItem: Identifiable {
    let id = UUID() // Make it Identifiable
    var name: String
    var value: Double
    var color: Color
}



struct DoughnutChart: View {
    let items: [DoughnutChartItem]
    var innerRadiusFraction: CGFloat = 0.6
    var showLabels: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Create pie slices
                ForEach(0..<items.count, id: \.self) { index in
                    DoughnutSlice(
                        item: items[index],
                        itemIndex: index,
                        items: items,
                        radius: min(geometry.size.width, geometry.size.height) / 2,
                        innerRadiusFraction: innerRadiusFraction
                    )
                }
                
                // Inner circle for the doughnut hole
                if innerRadiusFraction > 0 {
                    Circle()
                        .fill(Color(UIColor.systemBackground))
                        .frame(
                            width: min(geometry.size.width, geometry.size.height) * innerRadiusFraction,
                            height: min(geometry.size.width, geometry.size.height) * innerRadiusFraction
                        )
                }
                
                // Total value in the center
                if showLabels {
                    let total = items.reduce(0.0) { $0 + $1.value }
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(Formatters.formatEuro(total))
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(width: min(geometry.size.width, geometry.size.height) * innerRadiusFraction * 0.8)
                    .multilineTextAlignment(.center)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct DoughnutSlice: View
{
    let item: DoughnutChartItem
    let itemIndex: Int
    let items: [DoughnutChartItem]
    let radius: CGFloat
    let innerRadiusFraction: CGFloat
    
    private var startAngle: Angle {
        // Corrected reduce syntax
        let precedingValues = items.prefix(itemIndex).reduce(0.0) { partialResult, item in
            partialResult + item.value // Ensure item.value is accessed (relies on Fix #1)
        }
        let totalValue = items.reduce(0.0) { partialResult, item in
            partialResult + item.value // Ensure item.value is accessed (relies on Fix #1)
        }
        // Handle potential division by zero if totalValue is 0
        return Angle(degrees: totalValue == 0 ? 0 : 360 * (precedingValues / totalValue))
    }
    
    private var endAngle: Angle {
        // Corrected reduce syntax
        let precedingAndCurrentValues = items.prefix(itemIndex + 1).reduce(0.0) { partialResult, item in
            partialResult + item.value // Ensure item.value is accessed (relies on Fix #1)
        }
        let totalValue = items.reduce(0.0) { partialResult, item in
            partialResult + item.value // Ensure item.value is accessed (relies on Fix #1)
        }
        // Handle potential division by zero if totalValue is 0
        return Angle(degrees: totalValue == 0 ? 0 : 360 * (precedingAndCurrentValues / totalValue))
    }
    
    private var midAngle: Angle {
        return Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
    }
    
    private var percentage: String {
        // Corrected reduce syntax
        let totalValue = items.reduce(0.0) { partialResult, item in
            partialResult + item.value // Ensure item.value is accessed (relies on Fix #1)
        }
        // Handle potential division by zero
        let percentage = totalValue == 0 ? 0 : (item.value / totalValue) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    
    var body: some View {
        // ... Path setup ...
        // Explicitly cast to Double for cos/sin
        let path = Path { path in
            path.move(to: CGPoint(
                x: radius + radius * innerRadiusFraction * cos(Double(startAngle.radians)), // Cast here
                y: radius + radius * innerRadiusFraction * sin(Double(startAngle.radians))  // Cast here
            ))
            path.addLine(to: CGPoint(
                x: radius + radius * cos(Double(startAngle.radians)), // Cast here
                y: radius + radius * sin(Double(startAngle.radians))  // Cast here
            ))
            path.addArc(
                center: CGPoint(x: radius, y: radius),
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addLine(to: CGPoint(
                x: radius + radius * innerRadiusFraction * cos(Double(endAngle.radians)), // Cast here
                y: radius + radius * innerRadiusFraction * sin(Double(endAngle.radians))  // Cast here
            ))
            path.addArc(
                center: CGPoint(x: radius, y: radius),
                radius: radius * innerRadiusFraction,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
        }
        
        return path
            .fill(item.color) // Ensure item.color is accessed (relies on Fix #1)
            .overlay(
                GeometryReader { geometry in
                    // Corrected reduce syntax
                    let totalValue = items.reduce(0.0) { partialResult, item in
                        partialResult + item.value // Ensure item.value is accessed (relies on Fix #1)
                    }
                    // Handle potential division by zero
                    if totalValue > 0 && item.value / totalValue > 0.05 {
                        let midRadius = radius * (1 + innerRadiusFraction) / 2
                        // Explicitly cast to Double for cos/sin
                        let x = radius + midRadius * cos(Double(midAngle.radians)) // Cast here
                        let y = radius + midRadius * sin(Double(midAngle.radians)) // Cast here
                        
                        Text(percentage)
                        // ... styling ...
                            .position(x: x, y: y)
                    }
                }
            )
    }
}

