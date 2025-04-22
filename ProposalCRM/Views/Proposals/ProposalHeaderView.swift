//
//  ProposalHeaderView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// ProposalHeaderView.swift
// Fixed header view for the proposal detail screen with solid background

import SwiftUI

struct ProposalHeaderView: View {
    @ObservedObject var proposal: Proposal
    var onEditTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Solid background to prevent any drawing from showing through
            Rectangle()
                .fill(Color.black)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            // Content layer
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(proposal.formattedNumber)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(proposal.formattedStatus)
                        .font(.subheadline)
                        .padding(6)
                        .background(statusColor(for: proposal.formattedStatus))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Customer")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(proposal.customerName)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(proposal.formattedDate)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                HStack {
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(proposal.formattedTotal)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft":
            return .gray
        case "Pending":
            return .orange
        case "Sent":
            return .blue
        case "Won":
            return .green
        case "Lost":
            return .red
        case "Expired":
            return .purple
        default:
            return .gray
        }
    }
}

// Fixed proposal title section
struct ProposalTitleSection: View {
    let title: String
    let customer: String
    let date: String
    let amount: String
    let status: String
    let onEditTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Solid black background
            Rectangle()
                .fill(Color.black)
                .edgesIgnoringSafeArea(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                // Proposal number and status
                HStack {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusBackgroundColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Customer name
                Text(customer)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                
                // Date and amount on the same row
                HStack {
                    HStack {
                        Text("Date:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(date)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("Total Amount:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(amount)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
    
    private var statusBackgroundColor: Color {
        switch status.lowercased() {
        case "draft": return .gray
        case "pending": return .orange
        case "sent": return .blue
        case "won": return .green
        case "lost": return .red
        case "expired": return .purple
        default: return .gray
        }
    }
}

// Top section component with action callback
