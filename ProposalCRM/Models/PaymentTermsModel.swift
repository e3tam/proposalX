// PaymentTermsModel.swift
// Model definition for PaymentTerm entity in Core Data

import Foundation
import CoreData

// Core Data model extension for PaymentTerm entity
extension NSManagedObject {
    // Helper to safely check if the entity has a specific property
    func hasProperty(named propertyName: String) -> Bool {
        return entity.propertiesByName[propertyName] != nil
    }
}

// Extension for PaymentTerm entity
extension NSManagedObject {
    // Safely get and set ID as string (Core Data compatible)
    func setID(_ uuid: UUID?) {
        if hasProperty(named: "idString") {
            setValue(uuid?.uuidString, forKey: "idString")
        }
    }
    
    func getID() -> UUID? {
        if hasProperty(named: "idString"),
           let idString = value(forKey: "idString") as? String {
            return UUID(uuidString: idString)
        }
        return nil
    }
}

// Extension for Proposal to handle payment methods
extension Proposal {
    // Helper methods for payment methods - avoiding redeclaration
    func getPaymentMethods() -> [String] {
        if let methodsData = value(forKey: "paymentMethodsData") as? Data,
           let methods = try? JSONDecoder().decode([String].self, from: methodsData) {
            return methods
        }
        return []
    }
    
    func setPaymentMethods(_ methods: [String]) {
        if let data = try? JSONEncoder().encode(methods) {
            setValue(data, forKey: "paymentMethodsData")
        }
    }
    
    // Helper method to access payment terms array
    var paymentTermsArray: [NSManagedObject] {
        if let terms = value(forKey: "paymentTerms") as? NSSet {
            // Convert to array and sort by percentage
            let array = terms.allObjects as? [NSManagedObject] ?? []
            return array.sorted {
                let pct1 = ($0.value(forKey: "percentage") as? Double) ?? 0
                let pct2 = ($1.value(forKey: "percentage") as? Double) ?? 0
                return pct1 < pct2
            }
        }
        return []
    }
    
    // Helper method to recalculate all payment term amounts when proposal total changes
    func recalculatePaymentTerms() {
        // Skip if totalAmount isn't available
        guard responds(to: Selector(("totalAmount"))),
              let totalAmount = value(forKey: "totalAmount") as? Double else {
            return
        }
        
        for term in paymentTermsArray {
            if let percentage = term.value(forKey: "percentage") as? Double {
                term.setValue(totalAmount * (percentage / 100), forKey: "amount")
            }
        }
        
        // Save the changes
        do {
            try managedObjectContext?.save()
        } catch {
            print("Error recalculating payment terms: \(error)")
        }
    }
}

// Helper for accessing payment term properties safely
extension NSManagedObject {
    // Get term name
    var termName: String? {
        return value(forKey: "name") as? String
    }
    
    // Get term percentage
    var termPercentage: Double? {
        return value(forKey: "percentage") as? Double
    }
    
    // Get term amount
    var termAmount: Double {
        return (value(forKey: "amount") as? Double) ?? 0
    }
    
    // Get due date condition
    var termDueCondition: String? {
        return value(forKey: "dueCondition") as? String
    }
    
    // Get due days
    var termDueDays: Double? {
        return value(forKey: "dueDays") as? Double
    }
    
    // Get due date
    var termDueDate: Date? {
        return value(forKey: "dueDate") as? Date
    }
}
