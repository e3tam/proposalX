//
//  CoreDataExtensions.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 21.04.2025.
//

//
//  CoreDataExtensions.swift
//  ProposalCRM
//

import CoreData

extension NSManagedObject {
    func refreshAllProperties() {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let propertyName = child.label {
                // Access the property to trigger faulting
                _ = value(forKey: propertyName)
            }
        }
    }
}
