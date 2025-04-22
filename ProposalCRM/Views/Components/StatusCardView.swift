// StatusCardView.swift
// Card showing proposal status statistics

import SwiftUI

struct StatusCardView: View {
    let title: String
    let count: Int
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
            
            Text(String(format: "%.2f", value))
                .font(.subheadline)
        }
        .padding()
        .frame(width: 140, height: 120)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
