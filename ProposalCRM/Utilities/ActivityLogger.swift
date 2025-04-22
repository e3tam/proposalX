//
//  ActivityLogger.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// ActivityLogger.swift
// Utility for logging activities in the CRM

import Foundation
import CoreData
import SwiftUI

class ActivityLogger {
    static func logActivity(
        type: String,
        description: String,
        proposal: Proposal,
        context: NSManagedObjectContext,
        userPerformed: String? = nil,
        details: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        context.perform {
            let activity = Activity(context: context)
            activity.id = UUID()
            activity.timestamp = Date()
            activity.type = type
            activity.desc = description
           
            activity.details = details
            activity.proposal = proposal
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                let nsError = error as NSError
                print("Error logging activity: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Convenience methods for common activities
    
    static func logProposalCreated(proposal: Proposal, context: NSManagedObjectContext) {
        logActivity(
            type: "Created",
            description: "Proposal created",
            proposal: proposal,
            context: context
        )
    }
    
    static func logProposalUpdated(proposal: Proposal, context: NSManagedObjectContext, fieldChanged: String) {
        logActivity(
            type: "Updated",
            description: "Updated \(fieldChanged)",
            proposal: proposal,
            context: context
        )
    }
    
    static func logStatusChanged(proposal: Proposal, context: NSManagedObjectContext, oldStatus: String, newStatus: String) {
        logActivity(
            type: "StatusChanged",
            description: "Status changed from \(oldStatus) to \(newStatus)",
            proposal: proposal,
            context: context
        )
    }
    
    static func logItemAdded(proposal: Proposal, context: NSManagedObjectContext, itemType: String, itemName: String) {
        logActivity(
            type: "ItemAdded",
            description: "Added \(itemType): \(itemName)",
            proposal: proposal,
            context: context
        )
    }
    
    static func logItemRemoved(proposal: Proposal, context: NSManagedObjectContext, itemType: String, itemName: String) {
        logActivity(
            type: "ItemRemoved",
            description: "Removed \(itemType): \(itemName)",
            proposal: proposal,
            context: context
        )
    }
    
    static func logTaskAdded(proposal: Proposal, context: NSManagedObjectContext, taskTitle: String) {
        logActivity(
            type: "TaskAdded",
            description: "Added task: \(taskTitle)",
            proposal: proposal,
            context: context
        )
    }
    
    static func logTaskCompleted(proposal: Proposal, context: NSManagedObjectContext, taskTitle: String) {
        logActivity(
            type: "TaskCompleted",
            description: "Completed task: \(taskTitle)",
            proposal: proposal,
            context: context
        )
    }
    
    static func logCommentAdded(proposal: Proposal, context: NSManagedObjectContext, comment: String) {
        logActivity(
            type: "CommentAdded",
            description: "Added comment",
            proposal: proposal,
            context: context,
            details: comment
        )
    }
}
