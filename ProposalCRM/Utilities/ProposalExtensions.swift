//
//  ProposalExtensions.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// ProposalExtensions.swift
// Extensions for Proposal entity specific to tax calculation

import Foundation
import CoreData

extension Proposal {
    // Calculate taxable products amount (for tax base)
    func calculateTaxableProductsAmount() -> Double {
        return itemsArray.filter { $0.applyCustomTax }.reduce(0.0) { total, item in
            if let product = item.product {
                return total + (product.partnerPrice * item.quantity)
            }
            return total
        }
    }
    
    // Method to recalculate all custom taxes in the proposal
    func recalculateCustomTaxes() {
        // Calculate the tax base
        let taxBase = calculateTaxableProductsAmount()
        
        // Go through all taxes and update their amounts
        for tax in taxesArray {
            let amount = taxBase * (tax.rate / 100)
            tax.amount = amount
        }
        
        // Save the changes
        do {
            try managedObjectContext?.save()
        } catch {
            print("Error recalculating taxes: \(error)")
        }
    }
}
