//
//  EnhancedProposalHeaderSection.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// EnhancedProposalHeaderSection.swift
// Header section displaying customer and proposal information

import SwiftUI

struct EnhancedProposalHeaderSection: View {
    let proposal: Proposal
    let onEditTapped: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Dynamic colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground).opacity(0.2) : Color(UIColor.secondarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Customer Information Section
            if let customer = proposal.customer {
                VStack(alignment: .leading, spacing: 16) {
                    // Customer header
                    HStack {
                        Text("Customer Information")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Customer details card
                    VStack(alignment: .leading, spacing: 12) {
                        // Company name
                        HStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text(customer.formattedName)
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                        }
                        
                        // Contact person
                        if let contactName = customer.contactName, !contactName.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "person")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                                    .frame(width: 30)
                                
                                Text(contactName)
                                    .font(.subheadline)
                                    .foregroundColor(primaryTextColor)
                            }
                        }
                        
                        // Email
                        if let email = customer.email, !email.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        
                        // Phone
                        if let phone = customer.phone, !phone.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .font(.system(size: 20))
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        
                        // Address
                        if let address = customer.address, !address.isEmpty {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "location")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            
            // Proposal Information Section
            VStack(alignment: .leading, spacing: 16) {
                // Proposal header with edit button
                HStack {
                    Text("Proposal Information")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Button(action: onEditTapped) {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Proposal number
                    HStack {
                        Text("Proposal #")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        Text(proposal.formattedNumber)
                            .font(.headline)
                            .foregroundColor(primaryTextColor)
                    }
                    
                    // Creation date
                    HStack {
                        Text("Date")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        Text(proposal.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                    }
                    
                    // Status
                    HStack {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        Text(proposal.formattedStatus)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor(for: proposal.formattedStatus))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    
                    // Total amount
                    HStack {
                        Text("Total Amount")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        Text(proposal.formattedTotal)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)
                    }
                }
                .padding()
                .background(backgroundColor)
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
    }
    
    // Status color remains unchanged
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft": return .gray
        case "Pending": return .orange
        case "Sent": return .blue
        case "Won": return .green
        case "Lost": return .red
        case "Expired": return .purple
        default: return .gray
        }
    }
}
