//
//  Formatters.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 24.04.2025.
//

import Foundation

class Formatters {
    
    // MARK: - Currency Formatting
    
    // Format as Euro currency
    static func formatEuro(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    // Format as percentage
    static func formatPercent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.multiplier = 1.0 // Value already in percentage form
        return formatter.string(from: NSNumber(value: value/100)) ?? "0.0%"
    }
    
    // MARK: - Date Formatting
    
    // Format date with medium style
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return "Unknown Date"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Methods for Proposal
    
    // Get formatted proposal number
    static func formatProposalNumber(_ proposal: Proposal) -> String {
        return proposal.number ?? "New Proposal"
    }
    
    // Get formatted proposal status
    static func formatProposalStatus(_ proposal: Proposal) -> String {
        return proposal.status ?? "Draft"
    }
    
    // Get formatted date for proposal
    static func formatProposalDate(_ proposal: Proposal) -> String {
        return formatDate(proposal.creationDate)
    }
    
    // Get formatted total amount
    static func formatProposalTotal(_ proposal: Proposal) -> String {
        return formatEuro(proposal.totalAmount)
    }
    
    // Get customer name from proposal
    static func formatCustomerName(_ proposal: Proposal) -> String {
        return proposal.customer?.name ?? "No Customer"
    }
    
    // Translate status from English to Turkish
    static func translateStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "draft": return "Taslak"
        case "pending": return "Beklemede"
        case "sent": return "Gönderildi"
        case "won": return "Kazanıldı"
        case "lost": return "Kaybedildi"
        case "expired": return "Süresi Doldu"
        default: return status
        }
    }
}
