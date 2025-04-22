//
//  CoreDataHelpers.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 21.04.2025.
//

//
//  CoreDataHelpers.swift
//  ProposalCRM
//

import CoreData

extension NSManagedObjectContext {
    func refreshObjects(_ objects: [NSManagedObject]) {
        objects.forEach { object in
            if object.isFault {
                refresh(object, mergeChanges: true)
            }
        }
    }
}

extension NSManagedObject {
    func fullyLoad() {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let propertyName = child.label {
                _ = value(forKey: propertyName)
            }
        }
    }
}
