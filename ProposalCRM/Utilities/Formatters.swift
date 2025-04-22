//
//  Formatters.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// Formatters.swift
// Utility class for consistent formatting of numbers and currencies

import Foundation

struct Formatters {
    // MARK: - Currency Formatters
    
    // Euro currency formatter - this method already exists in the project
    // but we're providing it here to avoid reference errors
    static func formatEuro(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    // MARK: - Percentage Formatters
    
    // Standard percentage formatter
    static func formatPercent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        // Percentage value should be between 0 and 1 for NumberFormatter
        return formatter.string(from: NSNumber(value: value/100)) ?? "0.0%"
    }
}
