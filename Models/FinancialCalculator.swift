//
//  FinancialCalculator.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// File: ProposalCRM/Models/FinancialCalculator.swift
// Handles complex pricing calculations for proposals

import Foundation
import CoreData

class FinancialCalculator {
    // Calculate pricing with various discount levels
    static func calculatePrice(listPrice: Double, discount: Double) -> Double {
        return listPrice * (1 - discount / 100)
    }

    // Calculate profit margin percentage
    static func calculateProfitMargin(revenue: Double, cost: Double) -> Double {
        if revenue == 0 {
            return 0
        }
        return ((revenue - cost) / revenue) * 100
    }

    // Calculate break-even discount
    static func calculateBreakEvenDiscount(listPrice: Double, partnerPrice: Double) -> Double {
        if listPrice == 0 {
            return 0
        }
        let breakEvenDiscount = ((listPrice - partnerPrice) / listPrice) * 100
        return breakEvenDiscount
    }

    // Calculate tax amount
    static func calculateTaxAmount(amount: Double, taxRate: Double) -> Double {
        return amount * (taxRate / 100)
    }

    // Calculate total proposal amount with all components
    static func calculateTotalProposalAmount(proposal: Proposal) -> Double {
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes

        return productsTotal + engineeringTotal + expensesTotal + taxesTotal
    }

    // Format currency based on locale - UPDATED to use central Euro formatter
    static func formatCurrency(_ amount: Double, currencyCode: String = "EUR") -> String {
        // Always use the central Euro formatter, ignore the currencyCode parameter for now
        // or adapt logic if multi-currency is needed later.
        return Formatters.formatEuro(amount)
    }
}