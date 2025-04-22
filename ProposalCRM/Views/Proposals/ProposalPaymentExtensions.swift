// ProposalPaymentExtensions.swift
// Extensions to the Proposal entity for handling payment terms

import Foundation
import CoreData
import SwiftUI

// Payment terms-related extensions for Proposal
extension Proposal {
    // Flag to check if payment terms have been set up
    @objc dynamic var hasPaymentTerms: Bool {
        get {
            let value = primitiveValue(forKey: "hasPaymentTerms") as? Bool
            return value ?? false
        }
        set {
            setPrimitiveValue(newValue, forKey: "hasPaymentTerms")
        }
    }
    
    // Advance payment properties
    @objc dynamic var advancePaymentRequired: Bool {
        get {
            let value = primitiveValue(forKey: "advancePaymentRequired") as? Bool
            return value ?? false
        }
        set {
            setPrimitiveValue(newValue, forKey: "advancePaymentRequired")
        }
    }
    
    @objc dynamic var advancePaymentPercentage: Double {
        get {
            let value = primitiveValue(forKey: "advancePaymentPercentage") as? Double
            return value ?? 30.0
        }
        set {
            setPrimitiveValue(newValue, forKey: "advancePaymentPercentage")
        }
    }
    
    // Delivery payment properties
    @objc dynamic var deliveryPaymentRequired: Bool {
        get {
            let value = primitiveValue(forKey: "deliveryPaymentRequired") as? Bool
            return value ?? false
        }
        set {
            setPrimitiveValue(newValue, forKey: "deliveryPaymentRequired")
        }
    }
    
    @objc dynamic var deliveryPaymentPercentage: Double {
        get {
            let value = primitiveValue(forKey: "deliveryPaymentPercentage") as? Double
            return value ?? 30.0
        }
        set {
            setPrimitiveValue(newValue, forKey: "deliveryPaymentPercentage")
        }
    }
    
    // Final payment properties
    var finalPaymentPercentage: Double {
        return 100 -
            (advancePaymentRequired ? advancePaymentPercentage : 0) -
            (deliveryPaymentRequired ? deliveryPaymentPercentage : 0)
    }
    
    var finalPaymentAmount: Double {
        return totalAmount * (finalPaymentPercentage / 100)
    }
    
    // Payment due days (Net 30, etc.)
    @objc dynamic var paymentDueDays: Int {
        get {
            let value = primitiveValue(forKey: "paymentDueDays") as? Int
            return value ?? 30
        }
        set {
            setPrimitiveValue(newValue, forKey: "paymentDueDays")
        }
    }
    
    // Accepted payment methods (comma-separated string)
    @objc dynamic var acceptedPaymentMethods: String {
        get {
            let value = primitiveValue(forKey: "acceptedPaymentMethods") as? String
            return value ?? "Bank Transfer, Credit Card"
        }
        set {
            setPrimitiveValue(newValue, forKey: "acceptedPaymentMethods")
        }
    }
    
    // Payment notes
    @objc dynamic var paymentNotes: String {
        get {
            let value = primitiveValue(forKey: "paymentNotes") as? String
            return value ?? ""
        }
        set {
            setPrimitiveValue(newValue, forKey: "paymentNotes")
        }
    }
    
    // Format payment terms as a summary string
    var paymentTermsSummary: String {
        var terms: [String] = []
        
        if advancePaymentRequired {
            terms.append("\(Int(advancePaymentPercentage))% advance payment")
        }
        
        if deliveryPaymentRequired {
            terms.append("\(Int(deliveryPaymentPercentage))% on delivery")
        }
        
        terms.append("\(Int(finalPaymentPercentage))% final payment" + (paymentDueDays > 0 ? " (Net \(paymentDueDays))" : ""))
        
        return terms.joined(separator: ", ")
    }
    
    // Format payment methods as a readable string
    var formattedPaymentMethods: String {
        if acceptedPaymentMethods.isEmpty {
            return "Not specified"
        }
        return acceptedPaymentMethods
    }
    
    // Method to set default payment terms
    func setDefaultPaymentTerms() {
        advancePaymentRequired = true
        advancePaymentPercentage = 30
        deliveryPaymentRequired = false
        deliveryPaymentPercentage = 30
        paymentDueDays = 30
        acceptedPaymentMethods = "Bank Transfer, Credit Card"
        paymentNotes = "Payment terms are negotiable."
        hasPaymentTerms = true
    }
    
    // Method to calculate payment schedule
    func paymentSchedule() -> [(description: String, dueDate: String, amount: Double, percentage: Double)] {
        var schedule: [(description: String, dueDate: String, amount: Double, percentage: Double)] = []
        
        if advancePaymentRequired {
            schedule.append((
                description: "Advance Payment",
                dueDate: "Upon signing",
                amount: totalAmount * (advancePaymentPercentage / 100),
                percentage: advancePaymentPercentage
            ))
        }
        
        if deliveryPaymentRequired {
            schedule.append((
                description: "Delivery Payment",
                dueDate: "Upon delivery",
                amount: totalAmount * (deliveryPaymentPercentage / 100),
                percentage: deliveryPaymentPercentage
            ))
        }
        
        schedule.append((
            description: "Final Payment",
            dueDate: paymentDueDays > 0 ? "Net \(paymentDueDays) days" : "Upon completion",
            amount: finalPaymentAmount,
            percentage: finalPaymentPercentage
        ))
        
        return schedule
    }
}
