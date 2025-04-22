//
//  EngineeringTemplate.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


import Foundation
import SwiftUI

// MARK: - Template Data Models

/// Template for engineering services
struct EngineeringTemplate: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var days: Double
    var rate: Double
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, description: String, days: Double, rate: Double, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.days = days
        self.rate = rate
        self.isDefault = isDefault
    }
    
    static func == (lhs: EngineeringTemplate, rhs: EngineeringTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Template for expenses
struct ExpenseTemplate: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var category: String
    var amount: Double
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, description: String, category: String, amount: Double, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.amount = amount
        self.isDefault = isDefault
    }
    
    static func == (lhs: ExpenseTemplate, rhs: ExpenseTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Template for custom taxes
struct TaxTemplate: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var taxName: String
    var rate: Double
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, taxName: String, rate: Double, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.taxName = taxName
        self.rate = rate
        self.isDefault = isDefault
    }
    
    static func == (lhs: TaxTemplate, rhs: TaxTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Template for daily rates (used in engineering)
struct RateTemplate: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var rate: Double
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, rate: Double, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.rate = rate
        self.isDefault = isDefault
    }
    
    static func == (lhs: RateTemplate, rhs: RateTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Template Manager Service

/// Central service for managing all templates in the app
class TemplateManager: ObservableObject {
    // Singleton instance
    static let shared = TemplateManager()
    
    // Published properties for the templates
    @Published private(set) var engineeringTemplates: [EngineeringTemplate] = []
    @Published private(set) var expenseTemplates: [ExpenseTemplate] = []
    @Published private(set) var taxTemplates: [TaxTemplate] = []
    @Published private(set) var rateTemplates: [RateTemplate] = []
    
    // UserDefaults keys
    private let engineeringTemplatesKey = "engineeringTemplates"
    private let expenseTemplatesKey = "expenseTemplates"
    private let taxTemplatesKey = "taxTemplates"
    private let rateTemplatesKey = "rateTemplates"
    
    private init() {
        loadAllTemplates()
    }
    
    // MARK: - Loading Templates
    
    /// Load all template data from UserDefaults
    func loadAllTemplates() {
        loadEngineeringTemplates()
        loadExpenseTemplates()
        loadTaxTemplates()
        loadRateTemplates()
        
        // If no templates exist, initialize with defaults
        if engineeringTemplates.isEmpty {
            createDefaultEngineeringTemplates()
        }
        
        if expenseTemplates.isEmpty {
            createDefaultExpenseTemplates()
        }
        
        if taxTemplates.isEmpty {
            createDefaultTaxTemplates()
        }
        
        if rateTemplates.isEmpty {
            createDefaultRateTemplates()
        }
    }
    
    // MARK: - Engineering Templates
    
    private func loadEngineeringTemplates() {
        if let data = UserDefaults.standard.data(forKey: engineeringTemplatesKey),
           let templates = try? JSONDecoder().decode([EngineeringTemplate].self, from: data) {
            self.engineeringTemplates = templates
        }
    }
    
    private func saveEngineeringTemplates() {
        if let data = try? JSONEncoder().encode(engineeringTemplates) {
            UserDefaults.standard.set(data, forKey: engineeringTemplatesKey)
        }
    }
    
    func addEngineeringTemplate(_ template: EngineeringTemplate) {
        // Check if it's a duplicate name
        if engineeringTemplates.contains(where: { $0.name == template.name && $0.id != template.id }) {
            // Handle duplicate (e.g., append a number)
            var newName = template.name
            var counter = 1
            while engineeringTemplates.contains(where: { $0.name == newName && $0.id != template.id }) {
                counter += 1
                newName = "\(template.name) (\(counter))"
            }
            var updatedTemplate = template
            updatedTemplate.name = newName
            engineeringTemplates.append(updatedTemplate)
        } else {
            engineeringTemplates.append(template)
        }
        saveEngineeringTemplates()
    }
    
    func updateEngineeringTemplate(_ template: EngineeringTemplate) {
        if let index = engineeringTemplates.firstIndex(where: { $0.id == template.id }) {
            engineeringTemplates[index] = template
            saveEngineeringTemplates()
        }
    }
    
    func deleteEngineeringTemplate(id: UUID) {
        engineeringTemplates.removeAll { $0.id == id }
        saveEngineeringTemplates()
    }
    
    private func createDefaultEngineeringTemplates() {
        let defaults: [EngineeringTemplate] = [
            EngineeringTemplate(name: "Initial Setup", description: "System configuration and initial setup", days: 1.0, rate: 1200.0, isDefault: true),
            EngineeringTemplate(name: "Basic Installation", description: "Standard installation services", days: 0.5, rate: 1000.0, isDefault: true),
            EngineeringTemplate(name: "Advanced Installation", description: "Complex installation with custom configuration", days: 1.5, rate: 1200.0, isDefault: true),
            EngineeringTemplate(name: "Training Session", description: "User or administrator training", days: 1.0, rate: 800.0, isDefault: true)
        ]
        
        engineeringTemplates = defaults
        saveEngineeringTemplates()
    }
    
    // MARK: - Expense Templates
    
    private func loadExpenseTemplates() {
        if let data = UserDefaults.standard.data(forKey: expenseTemplatesKey),
           let templates = try? JSONDecoder().decode([ExpenseTemplate].self, from: data) {
            self.expenseTemplates = templates
        }
    }
    
    private func saveExpenseTemplates() {
        if let data = try? JSONEncoder().encode(expenseTemplates) {
            UserDefaults.standard.set(data, forKey: expenseTemplatesKey)
        }
    }
    
    func addExpenseTemplate(_ template: ExpenseTemplate) {
        // Check for duplicates
        if expenseTemplates.contains(where: { $0.name == template.name && $0.id != template.id }) {
            var newName = template.name
            var counter = 1
            while expenseTemplates.contains(where: { $0.name == newName && $0.id != template.id }) {
                counter += 1
                newName = "\(template.name) (\(counter))"
            }
            var updatedTemplate = template
            updatedTemplate.name = newName
            expenseTemplates.append(updatedTemplate)
        } else {
            expenseTemplates.append(template)
        }
        saveExpenseTemplates()
    }
    
    func updateExpenseTemplate(_ template: ExpenseTemplate) {
        if let index = expenseTemplates.firstIndex(where: { $0.id == template.id }) {
            expenseTemplates[index] = template
            saveExpenseTemplates()
        }
    }
    
    func deleteExpenseTemplate(id: UUID) {
        expenseTemplates.removeAll { $0.id == id }
        saveExpenseTemplates()
    }
    
    private func createDefaultExpenseTemplates() {
        let defaults: [ExpenseTemplate] = [
            ExpenseTemplate(name: "Flight Tickets", description: "Round-trip flight tickets", category: "Travel", amount: 500.0, isDefault: true),
            ExpenseTemplate(name: "Hotel Accommodation", description: "Hotel stay for 3 nights", category: "Travel", amount: 450.0, isDefault: true),
            ExpenseTemplate(name: "Standard Shipping", description: "Standard shipping service", category: "Shipping", amount: 75.0, isDefault: true),
            ExpenseTemplate(name: "Express Shipping", description: "Express shipping service", category: "Shipping", amount: 150.0, isDefault: true)
        ]
        
        expenseTemplates = defaults
        saveExpenseTemplates()
    }
    
    // MARK: - Tax Templates
    
    private func loadTaxTemplates() {
        if let data = UserDefaults.standard.data(forKey: taxTemplatesKey),
           let templates = try? JSONDecoder().decode([TaxTemplate].self, from: data) {
            self.taxTemplates = templates
        }
    }
    
    private func saveTaxTemplates() {
        if let data = try? JSONEncoder().encode(taxTemplates) {
            UserDefaults.standard.set(data, forKey: taxTemplatesKey)
        }
    }
    
    func addTaxTemplate(_ template: TaxTemplate) {
        if taxTemplates.contains(where: { $0.name == template.name && $0.id != template.id }) {
            var newName = template.name
            var counter = 1
            while taxTemplates.contains(where: { $0.name == newName && $0.id != template.id }) {
                counter += 1
                newName = "\(template.name) (\(counter))"
            }
            var updatedTemplate = template
            updatedTemplate.name = newName
            taxTemplates.append(updatedTemplate)
        } else {
            taxTemplates.append(template)
        }
        saveTaxTemplates()
    }
    
    func updateTaxTemplate(_ template: TaxTemplate) {
        if let index = taxTemplates.firstIndex(where: { $0.id == template.id }) {
            taxTemplates[index] = template
            saveTaxTemplates()
        }
    }
    
    func deleteTaxTemplate(id: UUID) {
        taxTemplates.removeAll { $0.id == id }
        saveTaxTemplates()
    }
    
    private func createDefaultTaxTemplates() {
        let defaults: [TaxTemplate] = [
            TaxTemplate(name: "Standard VAT", taxName: "VAT", rate: 19.0, isDefault: true),
            TaxTemplate(name: "Reduced VAT", taxName: "VAT", rate: 7.0, isDefault: true),
            TaxTemplate(name: "Sales Tax", taxName: "Sales Tax", rate: 5.0, isDefault: true),
            TaxTemplate(name: "Service Tax", taxName: "Service Tax", rate: 10.0, isDefault: true)
        ]
        
        taxTemplates = defaults
        saveTaxTemplates()
    }
    
    // MARK: - Rate Templates
    
    private func loadRateTemplates() {
        if let data = UserDefaults.standard.data(forKey: rateTemplatesKey),
           let templates = try? JSONDecoder().decode([RateTemplate].self, from: data) {
            self.rateTemplates = templates
        }
    }
    
    private func saveRateTemplates() {
        if let data = try? JSONEncoder().encode(rateTemplates) {
            UserDefaults.standard.set(data, forKey: rateTemplatesKey)
        }
    }
    
    func addRateTemplate(_ template: RateTemplate) {
        if rateTemplates.contains(where: { $0.name == template.name && $0.id != template.id }) {
            var newName = template.name
            var counter = 1
            while rateTemplates.contains(where: { $0.name == newName && $0.id != template.id }) {
                counter += 1
                newName = "\(template.name) (\(counter))"
            }
            var updatedTemplate = template
            updatedTemplate.name = newName
            rateTemplates.append(updatedTemplate)
        } else {
            rateTemplates.append(template)
        }
        saveRateTemplates()
    }
    
    func updateRateTemplate(_ template: RateTemplate) {
        if let index = rateTemplates.firstIndex(where: { $0.id == template.id }) {
            rateTemplates[index] = template
            saveRateTemplates()
        }
    }
    
    func deleteRateTemplate(id: UUID) {
        rateTemplates.removeAll { $0.id == id }
        saveRateTemplates()
    }
    
    private func createDefaultRateTemplates() {
        let defaults: [RateTemplate] = [
            RateTemplate(name: "Junior Engineer", rate: 800.0, isDefault: true),
            RateTemplate(name: "Senior Engineer", rate: 1200.0, isDefault: true),
            RateTemplate(name: "Lead Engineer", rate: 1500.0, isDefault: true),
            RateTemplate(name: "Expert Consultant", rate: 2000.0, isDefault: true)
        ]
        
        rateTemplates = defaults
        saveRateTemplates()
    }
    
    // MARK: - Reset All Templates
    
    func resetToDefaults() {
        createDefaultEngineeringTemplates()
        createDefaultExpenseTemplates() 
        createDefaultTaxTemplates()
        createDefaultRateTemplates()
    }
    
    // Get sorted lists
    func getSortedEngineeringTemplates() -> [EngineeringTemplate] {
        return engineeringTemplates.sorted { lhs, rhs in
            if lhs.isDefault && !rhs.isDefault { return true }
            if !lhs.isDefault && rhs.isDefault { return false }
            return lhs.name < rhs.name
        }
    }
    
    func getSortedExpenseTemplates() -> [ExpenseTemplate] {
        return expenseTemplates.sorted { lhs, rhs in
            if lhs.isDefault && !rhs.isDefault { return true }
            if !lhs.isDefault && rhs.isDefault { return false }
            return lhs.name < rhs.name
        }
    }
    
    func getSortedTaxTemplates() -> [TaxTemplate] {
        return taxTemplates.sorted { lhs, rhs in
            if lhs.isDefault && !rhs.isDefault { return true }
            if !lhs.isDefault && rhs.isDefault { return false }
            return lhs.name < rhs.name
        }
    }
    
    func getSortedRateTemplates() -> [RateTemplate] {
        return rateTemplates.sorted { lhs, rhs in
            if lhs.isDefault && !rhs.isDefault { return true }
            if !lhs.isDefault && rhs.isDefault { return false }
            return lhs.name < rhs.name
        }
    }
}