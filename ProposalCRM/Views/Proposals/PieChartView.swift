// PieChartView.swift
// Simple pie chart for financial visualization

import SwiftUI

struct PieSlice {
    let value: Double
    let color: Color
    let title: String
}

struct PieChartView: View {
    let slices: [PieSlice]
    let total: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Placeholder for pie chart implementation
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                Text("Pie Chart")
                    .font(.headline)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

struct PieSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}
