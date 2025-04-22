//
//  CoreDataModel.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// File: ProposalCRM/Models/CoreDataModel.swift
// This file provides programmatic definitions for the Core Data model entities

import Foundation
import CoreData
import SwiftUI // Added SwiftUI import for Color

// MARK: - CoreData entity extensions

// Customer extension - No currency changes needed here

// Product extension
extension Product {
    var formattedCode: String {
        return code ?? "Unknown Code"
    }

    var formattedName: String {
        return name ?? "Unknown Product"
    }

    var formattedPrice: String {
        // UPDATED: Use Euro formatter
        return Formatters.formatEuro(listPrice)
    }
}

// Proposal extension
extension Proposal {

    var formattedNumber: String {
        return number ?? "New Proposal"
    }

    var formattedDate: String {
        guard let date = creationDate else {
            return "Unknown Date"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedStatus: String {
        return status ?? "Draft"
    }

    var formattedTotal: String {
        // UPDATED: Use Euro formatter
        return Formatters.formatEuro(totalAmount)
    }

    var customerName: String {
        return customer?.name ?? "No Customer"
    }

    // --- Array accessors ---
    var itemsArray: [ProposalItem] {
        let set = items as? Set<ProposalItem> ?? []
        // Consider adding sorting if needed, e.g., by order added or product name
        return set.sorted {
            $0.product?.name ?? "" < $1.product?.name ?? ""
        }
    }

    var engineeringArray: [Engineering] {
        let set = engineering as? Set<Engineering> ?? []
        return set.sorted {
            $0.desc ?? "" < $1.desc ?? ""
        }
    }

    var expensesArray: [Expense] {
        let set = expenses as? Set<Expense> ?? []
        return set.sorted {
            $0.desc ?? "" < $1.desc ?? ""
        }
    }

    var taxesArray: [CustomTax] {
        let set = taxes as? Set<CustomTax> ?? []
        return set.sorted {
            $0.name ?? "" < $1.name ?? ""
        }
    }

    // --- Subtotal calculations (values remain Double) ---
    var subtotalProducts: Double {
        let items = itemsArray
        return items.reduce(0) { $0 + $1.amount }
    }

    var subtotalEngineering: Double {
        let engineering = engineeringArray
        return engineering.reduce(0) { $0 + $1.amount }
    }

    var subtotalExpenses: Double {
        let expenses = expensesArray
        return expenses.reduce(0) { $0 + $1.amount }
    }

    var subtotalTaxes: Double {
        let taxes = taxesArray
        return taxes.reduce(0) { $0 + $1.amount }
    }

    // --- Cost and Profit calculations (values remain Double) ---
    var totalCost: Double {
        var cost = 0.0
        for item in itemsArray {
            if let product = item.product {
                cost += product.partnerPrice * item.quantity
            }
        }
        // Note: Assumes Engineering is PROFIT, not cost. Adjust if needed.
        return cost + subtotalExpenses
    }

    var grossProfit: Double {
        return totalAmount - totalCost
    }

    var profitMargin: Double {
        if totalAmount == 0 {
            return 0
        }
        return (grossProfit / totalAmount) * 100
    }

    // --- Task and Activity related ---
    var tasksArray: [Task] {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            // Use proposal's objectID for predicate to ensure uniqueness
             guard let proposalID = self.objectID as? NSManagedObjectID else { return [] }
             fetchRequest.predicate = NSPredicate(format: "proposal == %@", proposalID)

            do {
                let context = PersistenceController.shared.container.viewContext
                let fetchedTasks = try context.fetch(fetchRequest)

                // Sort the tasks
                return fetchedTasks.sorted { task1, task2 in
                    if task1.status == "Completed" && task2.status != "Completed" {
                        return false
                    } else if task1.status != "Completed" && task2.status == "Completed" {
                        return true
                    } else if let date1 = task1.dueDate, let date2 = task2.dueDate {
                        return date1 < date2
                    } else if task1.dueDate != nil && task2.dueDate == nil {
                        return true
                    } else if task1.dueDate == nil && task2.dueDate != nil {
                        return false
                    } else {
                        return task1.creationDate ?? Date() < task2.creationDate ?? Date() // Sort older first
                    }
                }
            } catch {
                print("ERROR: Failed to fetch tasks for proposal: \(error)")
                return []
            }
        }

    var activitiesArray: [Activity] {
        let set = activities as? Set<Activity> ?? []
        return set.sorted {
            $0.timestamp ?? Date() > $1.timestamp ?? Date() // Most recent first
        }
    }

    var pendingTasksCount: Int {
        return tasksArray.filter { $0.status != "Completed" }.count
    }

    var hasOverdueTasks: Bool {
        return tasksArray.contains { $0.isOverdue }
    }

    var lastActivity: Activity? {
        return activitiesArray.first
    }
}

// ProposalItem extension
extension ProposalItem {
    var productName: String {
        return product?.name ?? "Unknown Product"
    }

    var productCode: String {
        return product?.code ?? "Unknown Code"
    }

    var formattedAmount: String {
        // UPDATED: Use Euro formatter
        return Formatters.formatEuro(amount)
    }
}

// Engineering extension
extension Engineering {
    var formattedAmount: String {
        // UPDATED: Use Euro formatter
        return Formatters.formatEuro(amount)
    }
}

// Expense extension
extension Expense {
    var formattedAmount: String {
        // UPDATED: Use Euro formatter
        return Formatters.formatEuro(amount)
    }
}

// CustomTax extension
extension CustomTax {
    var formattedRate: String {
        // Percentage formatting remains the same
        return Formatters.formatPercent(rate)
    }

    var formattedAmount: String {
        // UPDATED: Use Euro formatter
        return Formatters.formatEuro(amount)
    }
}

// Task extension - No currency changes needed here
extension Task {

    @objc dynamic var proposalObj: Proposal? {
        get { return proposal }
        set { proposal = newValue }
    }

    var formattedDueDate: String {
        guard let date = dueDate else {
            return "No due date"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var priorityColor: Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .blue
        default: return .gray
        }
    }

    var statusColor: Color {
        switch status {
        case "New": return .blue
        case "In Progress": return .orange
        case "Completed": return .green
        case "Deferred": return .gray
        default: return .gray
        }
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        // Check against end of day for due date to be more lenient
        let endOfDayDueDate = Calendar.current.startOfDay(for: dueDate).addingTimeInterval(24*60*60 - 1)
        return endOfDayDueDate < Date() && status != "Completed"
    }
}

// Activity extension - No currency changes needed here
extension Activity {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp ?? Date())
    }

    var typeIcon: String {
        switch type {
        case "Created": return "plus.circle"
        case "Updated": return "pencil.circle"
        case "StatusChanged": return "arrow.triangle.swap"
        case "CommentAdded": return "text.bubble"
        case "TaskAdded": return "checkmark.circle"
        case "TaskCompleted": return "checkmark.circle.fill"
        case "DocumentAdded": return "doc.fill"
        case "ItemAdded": return "plus.app" // Example for item added
        case "ItemRemoved": return "minus.square" // Example for item removed
        default: return "info.circle"
        }
    }

    var typeColor: Color {
        switch type {
        case "Created": return .green
        case "Updated": return .blue
        case "StatusChanged": return .orange
        case "CommentAdded": return .purple
        case "TaskAdded": return .blue
        case "TaskCompleted": return .green
        case "DocumentAdded": return .gray
        case "ItemAdded": return .cyan
        case "ItemRemoved": return .pink
        default: return .gray
        }
    }
}

// Customer extension
extension Customer {
    var formattedName: String {
        return name ?? "Unknown Customer"
    }

    var proposalsArray: [Proposal] {
        let set = proposals as? Set<Proposal> ?? []
        return set.sorted {
            $0.creationDate ?? Date() > $1.creationDate ?? Date() // Most recent first
        }
    }
}
