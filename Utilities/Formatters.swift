//
//  Formatters.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// File: ProposalCRM/Utilities/Formatters.swift

import Foundation

struct Formatters {
    /// A reusable NumberFormatter configured for Euro currency display.
    /// Uses German locale for formatting conventions (e.g., comma decimal separator).
    static let euroCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency // Use currency style for locale-aware formatting
        formatter.currencyCode = "EUR"    // Set currency to Euro
        // Using "de_DE" (Germany) as an example Euro locale. Adjust if needed for different separators/symbol placement.
        formatter.locale = Locale(identifier: "de_DE")
        formatter.minimumFractionDigits = 2 // Ensure two decimal places
        formatter.maximumFractionDigits = 2 // Ensure two decimal places
        return formatter
    }()

    /// Convenience function to format a Double value as a Euro currency string.
    /// - Parameter value: The numeric value to format.
    /// - Returns: A Euro-formatted string (e.g., "€1.234,56") or a fallback format.
    static func formatEuro(_ value: Double) -> String {
        return euroCurrencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "€%.2f", value) // Fallback
    }

    /// Convenience function to format a Double value as a percentage string.
    /// - Parameter value: The numeric value (e.g., 25.5 for 25.5%).
    /// - Returns: A percentage-formatted string (e.g., "25.5%").
    static func formatPercent(_ value: Double) -> String {
         return String(format: "%.1f%%", value)
     }
}