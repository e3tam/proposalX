import Foundation
 import Combine
 import SwiftUI

 // MARK: - Template Data Models

 /// Template for engineering services
 public struct EngineeringTemplate: Identifiable, Equatable, Codable {
     public var id: UUID
     public var name: String
     public var description: String
     public var days: Double
     public var rate: Double
     public var isDefault: Bool
     
     public init(id: UUID = UUID(), name: String, description: String, days: Double, rate: Double, isDefault: Bool = false) {
         self.id = id
         self.name = name
         self.description = description
         self.days = days
         self.rate = rate
         self.isDefault = isDefault
     }
     
     public static func == (lhs: EngineeringTemplate, rhs: EngineeringTemplate) -> Bool {
         return lhs.id == rhs.id
     }
 }

 /// Template for expenses
 public struct ExpenseTemplate: Identifiable, Equatable, Codable {
     public var id: UUID
     public var name: String
     public var description: String
     public var category: String
     public var amount: Double
     public var isDefault: Bool
     
     public init(id: UUID = UUID(), name: String, description: String, category: String, amount: Double, isDefault: Bool = false) {
         self.id = id
         self.name = name
         self.description = description
         self.category = category
         self.amount = amount
         self.isDefault = isDefault
     }
     
     public static func == (lhs: ExpenseTemplate, rhs: ExpenseTemplate) -> Bool {
         return lhs.id == rhs.id
     }
 }

 /// Template for custom taxes
 public struct TaxTemplate: Identifiable, Equatable, Codable {
     public var id: UUID
     public var name: String
     public var taxName: String
     public var rate: Double
     public var isDefault: Bool
     
     public init(id: UUID = UUID(), name: String, taxName: String, rate: Double, isDefault: Bool = false) {
         self.id = id
         self.name = name
         self.taxName = taxName
         self.rate = rate
         self.isDefault = isDefault
     }
     
     public static func == (lhs: TaxTemplate, rhs: TaxTemplate) -> Bool {
         return lhs.id == rhs.id
     }
 }

 // MARK: - Template Manager

 /// Manager for storing and retrieving templates
 public class TemplateManager: ObservableObject {
     public static let shared = TemplateManager()
     
     @Published private(set) var engineeringTemplates: [EngineeringTemplate] = []
     @Published private(set) var expenseTemplates: [ExpenseTemplate] = []
     @Published private(set) var taxTemplates: [TaxTemplate] = []
     
     private let engineeringTemplatesKey = "engineeringTemplates"
     private let expenseTemplatesKey = "expenseTemplates"
     private let taxTemplatesKey = "taxTemplatesKey"
     
     private init() {
         loadTemplates()
         addDefaultTemplatesIfNeeded()
     }
     
     // MARK: Engineering Templates
     
     public func getSortedEngineeringTemplates() -> [EngineeringTemplate] {
         return engineeringTemplates.sorted { $0.name < $1.name }
     }
     
     public func addEngineeringTemplate(_ template: EngineeringTemplate) {
         engineeringTemplates.append(template)
         saveTemplates()
     }
     
     public func updateEngineeringTemplate(_ template: EngineeringTemplate) {
         if let index = engineeringTemplates.firstIndex(where: { $0.id == template.id }) {
             engineeringTemplates[index] = template
             saveTemplates()
         }
     }
     
     public func deleteEngineeringTemplate(id: UUID) {
         engineeringTemplates.removeAll { $0.id == id }
         saveTemplates()
     }
     
     // MARK: Expense Templates
     
     public func getSortedExpenseTemplates() -> [ExpenseTemplate] {
         return expenseTemplates.sorted { $0.name < $1.name }
     }
     
     public func addExpenseTemplate(_ template: ExpenseTemplate) {
         expenseTemplates.append(template)
         saveTemplates()
     }
     
     public func updateExpenseTemplate(_ template: ExpenseTemplate) {
         if let index = expenseTemplates.firstIndex(where: { $0.id == template.id }) {
             expenseTemplates[index] = template
             saveTemplates()
         }
     }
     
     public func deleteExpenseTemplate(id: UUID) {
         expenseTemplates.removeAll { $0.id == id }
         saveTemplates()
     }
     
     // MARK: Tax Templates
     
     public func getSortedTaxTemplates() -> [TaxTemplate] {
         return taxTemplates.sorted { $0.name < $1.name }
     }
     
     public func addTaxTemplate(_ template: TaxTemplate) {
         taxTemplates.append(template)
         saveTemplates()
     }
     
     public func updateTaxTemplate(_ template: TaxTemplate) {
         if let index = taxTemplates.firstIndex(where: { $0.id == template.id }) {
             taxTemplates[index] = template
             saveTemplates()
         }
     }
     
     public func deleteTaxTemplate(id: UUID) {
         taxTemplates.removeAll { $0.id == id }
         saveTemplates()
     }
     
     // MARK: Private Methods
     
     private func saveTemplates() {
         if let encodedEngineering = try? JSONEncoder().encode(engineeringTemplates) {
             UserDefaults.standard.set(encodedEngineering, forKey: engineeringTemplatesKey)
         }
         
         if let encodedExpense = try? JSONEncoder().encode(expenseTemplates) {
             UserDefaults.standard.set(encodedExpense, forKey: expenseTemplatesKey)
         }
         
         if let encodedTax = try? JSONEncoder().encode(taxTemplates) {
             UserDefaults.standard.set(encodedTax, forKey: taxTemplatesKey)
         }
     }
     
     private func loadTemplates() {
         if let engineeringData = UserDefaults.standard.data(forKey: engineeringTemplatesKey),
            let decodedEngineering = try? JSONDecoder().decode([EngineeringTemplate].self, from: engineeringData) {
             engineeringTemplates = decodedEngineering
         }
         
         if let expenseData = UserDefaults.standard.data(forKey: expenseTemplatesKey),
            let decodedExpense = try? JSONDecoder().decode([ExpenseTemplate].self, from: expenseData) {
             expenseTemplates = decodedExpense
         }
         
         if let taxData = UserDefaults.standard.data(forKey: taxTemplatesKey),
            let decodedTax = try? JSONDecoder().decode([TaxTemplate].self, from: taxData) {
             taxTemplates = decodedTax
         }
     }
     
     private func addDefaultTemplatesIfNeeded() {
         // Add default engineering templates if none exist
         if engineeringTemplates.isEmpty {
             let defaultEngineering: [EngineeringTemplate] = [
                 EngineeringTemplate(
                     name: "Basic Installation",
                     description: "Standard system installation",
                     days: 1.0,
                     rate: 800.0,
                     isDefault: true
                 ),
                 EngineeringTemplate(
                     name: "Advanced Configuration",
                     description: "Complex system setup and customization",
                     days: 2.5,
                     rate: 950.0,
                     isDefault: true
                 ),
                 EngineeringTemplate(
                     name: "Training Session",
                     description: "On-site user training",
                     days: 1.0,
                     rate: 750.0,
                     isDefault: true
                 )
             ]
             
             engineeringTemplates.append(contentsOf: defaultEngineering)
         }
         
         // Add default expense templates if none exist
         if expenseTemplates.isEmpty {
             let defaultExpenses: [ExpenseTemplate] = [
                 ExpenseTemplate(
                     name: "Flight Ticket",
                     description: "Round-trip flight ticket",
                     category: "Travel",
                     amount: 450.0,
                     isDefault: true
                 ),
                 ExpenseTemplate(
                     name: "Hotel Accommodation",
                     description: "Standard 3-night hotel stay",
                     category: "Travel",
                     amount: 375.0,
                     isDefault: true
                 ),
                 ExpenseTemplate(
                     name: "Express Shipping",
                     description: "Expedited delivery of components",
                     category: "Shipping",
                     amount: 120.0,
                     isDefault: true
                 )
             ]
             
             expenseTemplates.append(contentsOf: defaultExpenses)
         }
         
         // Add default tax templates if none exist
         if taxTemplates.isEmpty {
             let defaultTaxes: [TaxTemplate] = [
                 TaxTemplate(
                     name: "Standard VAT",
                     taxName: "VAT",
                     rate: 19.0,
                     isDefault: true
                 ),
                 TaxTemplate(
                     name: "Reduced Rate",
                     taxName: "VAT",
                     rate: 7.0,
                     isDefault: true
                 ),
                 TaxTemplate(
                     name: "Sales Tax",
                     taxName: "Sales Tax",
                     rate: 5.0,
                     isDefault: true
                 )
             ]
             
             taxTemplates.append(contentsOf: defaultTaxes)
         }
         
         // Save all default templates
         saveTemplates()
     }
 }
