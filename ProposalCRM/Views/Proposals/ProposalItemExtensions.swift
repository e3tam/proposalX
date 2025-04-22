//
//  ProposalItemExtensions.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//

// ProposalItemExtensions.swift
// Extensions for ProposalItem that avoid KVC errors

import Foundation
import CoreData

// Create a new extension with minimal features to avoid conflicts
extension ProposalItem {
    // Helper method to calculate multiplier safely
    func calculateMultiplier() -> Double {
        if let product = self.product, product.listPrice > 0 {
            let discountFactor = 1.0 - (self.discount / 100.0)
            if discountFactor > 0 {
                return self.unitPrice / (product.listPrice * discountFactor)
            }
        }
        return 1.0 // Default value
    }
    
    // Calculate profit based on available data
    func calculateProfit() -> Double {
        if let product = self.product {
            let partnerCost = product.partnerPrice * self.quantity
            return self.amount - partnerCost
        }
        return 0
    }
    
    // Calculate profit margin as a percentage
    func calculateProfitMargin() -> Double {
        if self.amount <= 0 {
            return 0
        }
        return (calculateProfit() / self.amount) * 100
    }
}
