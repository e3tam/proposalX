//
//  CoreDataRefreshExtension.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// CoreDataRefreshExtension.swift
// Helper extension to refresh Core Data objects

import CoreData
import SwiftUI

extension NSManagedObjectContext {
    func refreshAllObjects() {
        for object in registeredObjects where !object.isFault {
            refresh(object, mergeChanges: true)
        }
    }
}

// This extension adds a useful debugging utility for ProposalItem
extension ProposalItem {
    func debugPrint() {
        print("===== ProposalItem Debug Info =====")
        print("ID: \(id?.uuidString ?? "nil")")
        print("Quantity: \(quantity)")
        print("Unit Price: \(unitPrice)")
        print("Discount: \(discount)")
        print("Amount: \(amount)")
        
        if let product = self.product {
            print("--- Product Info ---")
            print("Name: \(product.name ?? "nil")")
            print("Code: \(product.code ?? "nil")")
            print("List Price: \(product.listPrice)")
            print("Partner Price: \(product.partnerPrice)")
        } else {
            print("Product: nil")
        }
        print("==============================")
    }
}
