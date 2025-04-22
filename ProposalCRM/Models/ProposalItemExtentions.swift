// File: ProposalCRM/Models/ProposalItemExtentions.swift
// Extensions for ProposalItem with corrected accessors and Euro formatting.
// UPDATED: Removed redundant 'multiplier' computed property.

import Foundation
import CoreData

// MARK: - ProposalItem Extension
extension ProposalItem {

    // MARK: - Access to Model Attributes / Corrected Properties

    // --- REMOVED applyCustomTax computed property ---
    // Access 'applyCustomTax' directly via the Core Data generated property (item.applyCustomTax)

    // --- REMOVED multiplier computed property ---
    // Access 'multiplier' directly via the Core Data generated property (item.multiplier)
    // Ensure it was added to the .xcdatamodeld (Double, default: 1.0)

    /// The partner price for this item, obtained from the associated Product.
    var partnerPrice: Double {
        get {
            // Directly access the partnerPrice from the related product.
            return self.product?.partnerPrice ?? 0.0
        }
        // Setter removed.
    }

    /// Custom description for this specific proposal item.
    /// Note: Ensure 'customDescription' (String, optional) exists in your model.
    /// Using KVC as fallback if subclass not generated/used. Prefer direct access.
    var customDescription: String {
        get {
            return value(forKey: "customDescription") as? String ?? "" // Original KVC
        }
        set {
            setValue(newValue, forKey: "customDescription") // Original KVC
        }
    }

    // MARK: - Calculated Properties (Values derived from other attributes)

    /// The list price obtained directly from the associated Product entity.
    var unitListPrice: Double {
        return product?.listPrice ?? 0
    }

    /// The total partner price for the quantity of this item (Quantity * Partner Price).
    var extendedPartnerPrice: Double {
        return partnerPrice * quantity // Uses the corrected partnerPrice computed property
    }

    /// The total list price for the quantity of this item (Quantity * Unit List Price).
    var extendedListPrice: Double {
        return unitListPrice * quantity
    }

    /// The final calculated price for the customer for the extended quantity.
    /// This should match the stored `amount` attribute.
    var extendedCustomerPrice: Double {
        // Now relies on the 'multiplier' attribute existing directly on the item
        return unitListPrice * self.multiplier * (1 - discount / 100) * quantity
        // Or return self.amount if that's reliably calculated elsewhere
        // return self.amount
    }

    /// The calculated profit for this item line (Extended Customer Price - Extended Partner Price).
    var calculatedProfit: Double {
        // Use self.amount as the final customer price
        return self.amount - extendedPartnerPrice // extendedPartnerPrice uses the corrected partnerPrice
    }

    /// The calculated profit margin percentage for this item line.
    var profitMargin: Double {
        if self.amount <= 0 { // Use self.amount (final price) as the denominator
            return 0
        }
        return (calculatedProfit / self.amount) * 100 // calculatedProfit uses the corrected partnerPrice
    }

    // MARK: - Formatted Strings for Display (Using Euro Formatter)

    /// Formatted Unit List Price (Euro).
    var formattedUnitListPrice: String {
        return Formatters.formatEuro(unitListPrice)
    }

    /// Formatted Unit Partner Price (Euro).
    var formattedUnitPartnerPrice: String {
        return Formatters.formatEuro(partnerPrice) // Uses the corrected partnerPrice computed property
    }

    /// Formatted Extended List Price (Euro).
    var formattedExtendedListPrice: String {
        return Formatters.formatEuro(extendedListPrice)
    }

    /// Formatted Extended Partner Price (Euro).
    var formattedExtendedPartnerPrice: String {
        return Formatters.formatEuro(extendedPartnerPrice) // Uses the corrected partnerPrice computed property
    }

    /// Formatted Extended Customer Price (Euro). Represents the final line item total.
    var formattedExtendedCustomerPrice: String {
        return Formatters.formatEuro(self.amount) // Format the stored amount
    }

    /// Formatted Total Profit for this line item (Euro).
    var formattedProfit: String {
        return Formatters.formatEuro(calculatedProfit) // Uses the corrected partnerPrice computed property
    }

    /// Formatted Profit Margin (Percentage).
    var formattedProfitMargin: String {
        return Formatters.formatPercent(profitMargin)
    }

    /// Formatted Multiplier (e.g., "1.10x").
    var formattedMultiplier: String {
         // Access the multiplier directly from the item
        return String(format: "%.2fx", self.multiplier)
    }
}

// MARK: - Core Data Model Reminder
/*
 REMINDER: Ensure your Core Data model (`ProposalCRM.xcdatamodeld`) for the
 `ProposalItem` entity includes the necessary attributes like:

    - quantity: Double
    - unitPrice: Double
    - discount: Double
    - amount: Double
    - multiplier: Double, default: 1.0      <- Make sure this is added!
    - applyCustomTax: Boolean, default: false
    - customDescription: String, optional
    // - partnerPrice: Double <-- Should NOT be here, belongs on Product

 AND ensure the `Product` entity has:
    - code: String?
    - name: String?
    - desc: String?
    - category: String?
    - listPrice: Double
    - partnerPrice: Double

 If you made changes to the model, clean your build folder (Product > Clean Build Folder)
 and rebuild the project. Consider generating NSManagedObject subclasses for type safety.
 */
