import SwiftUI

struct DoughnutChart: View {
    let items: [DoughnutChartItem]
    var innerRadiusFraction: CGFloat = 0.6
    var showLabels: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Create pie slices
                ForEach(items) { item in
                    DoughnutSlice(
                        item: item,
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

struct DoughnutSlice: View {
    let item: DoughnutChartItem
    let items: [DoughnutChartItem]
    let radius: CGFloat
    let innerRadiusFraction: CGFloat
    
    private var startAngle: Angle {
        let precedingValues = items.prefix(while: { $0.id != item.id }).reduce(0.0) { $0 + $1.value }
        let totalValue = items.reduce(0.0) { $0 + $1.value }
        return Angle(degrees: 360 * (precedingValues / totalValue))
    }
    
    private var endAngle: Angle {
        let precedingAndCurrentValues = items
            .prefix(while: { $0.id != item.id })
            .reduce(item.value) { $0 + $1.value }
        let totalValue = items.reduce(0.0) { $0 + $1.value }
        return Angle(degrees: 360 * (precedingAndCurrentValues / totalValue))
    }
    
    private var midAngle: Angle {
        return Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
    }
    
    private var percentage: String {
        let totalValue = items.reduce(0.0) { $0 + $1.value }
        let percentage = (item.value / totalValue) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    var body: some View {
        let path = Path { path in
            path.move(to: CGPoint(
                x: radius + radius * innerRadiusFraction * cos(startAngle.radians),
                y: radius + radius * innerRadiusFraction * sin(startAngle.radians)
            ))
            path.addLine(to: CGPoint(
                x: radius + radius * cos(startAngle.radians),
                y: radius + radius * sin(startAngle.radians)
            ))
            path.addArc(
                center: CGPoint(x: radius, y: radius),
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addLine(to: CGPoint(
                x: radius + radius * innerRadiusFraction * cos(endAngle.radians),
                y: radius + radius * innerRadiusFraction * sin(endAngle.radians)
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
            .fill(item.color)
            .overlay(
                // Show percentage if segment is large enough
                GeometryReader { geometry in
                    if item.value / items.reduce(0.0, { $0 + $1.value }) > 0.05 {
                        // Calculate position along the median of the slice
                        let midRadius = radius * (1 + innerRadiusFraction) / 2
                        let x = radius + midRadius * cos(midAngle.radians)
                        let y = radius + midRadius * sin(midAngle.radians)
                        
                        Text(percentage)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .position(x: x, y: y)
                    }
                }
            )
    }
}