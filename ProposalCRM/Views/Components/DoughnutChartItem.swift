//
//  DoughnutChartItem.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// DoughnutChartItem.swift
// Component for rendering doughnut chart slices in ProposalCRM

import SwiftUI

struct DoughnutChartItem: View {
    let slices: [PieSlice]
    let total: Double
    let diameter: CGFloat
    let innerRadiusFraction: CGFloat
    let shadowRadius: CGFloat
    
    init(
        slices: [PieSlice],
        total: Double,
        diameter: CGFloat = 200,
        innerRadiusFraction: CGFloat = 0.6,
        shadowRadius: CGFloat = 2
    ) {
        self.slices = slices
        self.total = total
        self.diameter = diameter
        self.innerRadiusFraction = innerRadiusFraction
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        ZStack {
            // Instead of using a control flow in the closure, we'll create all slices
            // and only apply shadow to each slice that requires it
            ForEach(0..<slices.count, id: \.self) { index in
                sliceView(index: index)
            }
            
            // Inner circle for the doughnut hole
            Circle()
                .fill(Color.black)
                .frame(width: diameter * innerRadiusFraction, height: diameter * innerRadiusFraction)
        }
        .frame(width: diameter, height: diameter)
    }
    
    // Extract the slice view creation to a separate function
    private func sliceView(index: Int) -> some View {
        let slice = slices[index]
        let startAngle = self.startAngle(for: index)
        let endAngle = self.endAngle(for: index)
        
        return PieSliceShape(startAngle: startAngle, endAngle: endAngle)
            .fill(slice.color)
            .shadow(radius: shadowRadius)
            .overlay(
                // Optional: Add overlay for slice label if needed
                Text(slice.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(shouldShowLabel(for: slice) ? 1 : 0)
            )
    }
    
    // Helper method to decide if a label should be shown
    private func shouldShowLabel(for slice: PieSlice) -> Bool {
        return (slice.value / total) > 0.1 // Only show labels for slices > 10%
    }
    
    // Calculate the start angle for a slice
    private func startAngle(for index: Int) -> Angle {
        if index == 0 {
            return .degrees(0)
        }
        
        // Sum up the values of all previous slices
        let previousTotal = slices[0..<index].reduce(0) { $0 + $1.value }
        return .degrees(previousTotal / total * 360)
    }
    
    // Calculate the end angle for a slice
    private func endAngle(for index: Int) -> Angle {
        // Sum up the values of all slices up to and including this one
        let runningTotal = slices[0...index].reduce(0) { $0 + $1.value }
        return .degrees(runningTotal / total * 360)
    }
}

struct DoughnutChartItem_Previews: PreviewProvider {
    static var previews: some View {
        DoughnutChartItem(
            slices: [
                PieSlice(value: 25, color: .blue, title: "Products"),
                PieSlice(value: 15, color: .green, title: "Engineering"),
                PieSlice(value: 10, color: .orange, title: "Expenses"),
                PieSlice(value: 5, color: .red, title: "Taxes")
            ],
            total: 55
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}