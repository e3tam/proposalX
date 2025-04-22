//
//  MetricCard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
//  MetricCard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// MetricCard.swift
import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let trend: String
    let trendUp: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if !trend.isEmpty {
                HStack {
                    if trendUp {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(trendUp ? .green : .red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
}