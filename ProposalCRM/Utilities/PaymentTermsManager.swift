//
//  PaymentTermsManager.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// PaymentTermsManager.swift
// A separate manager class to handle payment terms without extending the Proposal entity

import Foundation
import CoreData
import SwiftUI

// Payment terms data model
struct PaymentTermsData: Codable {
    var terms: String = "30 days net"
    var depositRequired: Bool = false
    var depositAmount: Double = 0.0
    var depositPercentage: Double = 0.0
    var paymentMethods: [String] = ["Bank Transfer"]
    var latePenalty: String = ""
    var invoiceSchedule: String = ""
    var customTerms: String = ""
}

// Manager class to handle payment terms
class PaymentTermsManager {
    // Singleton instance
    static let shared = PaymentTermsManager()
    
    // Private initializer for singleton
    private init() {}
    
    // UserDefaults key prefix for storing payment terms
    private let keyPrefix = "paymentTerms_"
    
    // Get key for a specific proposal
    private func key(for proposal: Proposal) -> String {
        guard let uuid = proposal.id?.uuidString else {
            return "\(keyPrefix)unknown"
        }
        return "\(keyPrefix)\(uuid)"
    }
    
    // MARK: - Data Access Methods
    
    // Get payment terms data for a proposal
    private func getTermsData(for proposal: Proposal) -> PaymentTermsData {
        let key = self.key(for: proposal)
        if let data = UserDefaults.standard.data(forKey: key) {
            if let terms = try? JSONDecoder().decode(PaymentTermsData.self, from: data) {
                return terms
            }
        }
        return PaymentTermsData() // Return default if not found
    }
    
    // Save payment terms data for a proposal
    private func saveTermsData(_ terms: PaymentTermsData, for proposal: Proposal) {
        let key = self.key(for: proposal)
        if let data = try? JSONEncoder().encode(terms) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Convenience Methods
    
    // Payment Terms
    func getPaymentTerms(for proposal: Proposal) -> String {
        return getTermsData(for: proposal).terms
    }
    
    func setPaymentTerms(_ terms: String, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.terms = terms
        saveTermsData(data, for: proposal)
    }
    
    // Deposit Required
    func isDepositRequired(for proposal: Proposal) -> Bool {
        return getTermsData(for: proposal).depositRequired
    }
    
    func setDepositRequired(_ required: Bool, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.depositRequired = required
        saveTermsData(data, for: proposal)
    }
    
    // Deposit Amount
    func getDepositAmount(for proposal: Proposal) -> Double {
        return getTermsData(for: proposal).depositAmount
    }
    
    func setDepositAmount(_ amount: Double, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.depositAmount = amount
        saveTermsData(data, for: proposal)
    }
    
    // Deposit Percentage
    func getDepositPercentage(for proposal: Proposal) -> Double {
        return getTermsData(for: proposal).depositPercentage
    }
    
    func setDepositPercentage(_ percentage: Double, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.depositPercentage = percentage
        saveTermsData(data, for: proposal)
    }
    
    // Payment Methods
    func getPaymentMethods(for proposal: Proposal) -> [String] {
        return getTermsData(for: proposal).paymentMethods
    }
    
    func setPaymentMethods(_ methods: [String], for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.paymentMethods = methods
        saveTermsData(data, for: proposal)
    }
    
    // Late Penalty
    func getLatePenalty(for proposal: Proposal) -> String {
        return getTermsData(for: proposal).latePenalty
    }
    
    func setLatePenalty(_ penalty: String, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.latePenalty = penalty
        saveTermsData(data, for: proposal)
    }
    
    // Invoice Schedule
    func getInvoiceSchedule(for proposal: Proposal) -> String {
        return getTermsData(for: proposal).invoiceSchedule
    }
    
    func setInvoiceSchedule(_ schedule: String, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.invoiceSchedule = schedule
        saveTermsData(data, for: proposal)
    }
    
    // Custom Terms
    func getCustomTerms(for proposal: Proposal) -> String {
        return getTermsData(for: proposal).customTerms
    }
    
    func setCustomTerms(_ terms: String, for proposal: Proposal) {
        var data = getTermsData(for: proposal)
        data.customTerms = terms
        saveTermsData(data, for: proposal)
    }
    
    // Calculate deposit amount
    func calculateDepositAmount(for proposal: Proposal) -> Double {
        let data = getTermsData(for: proposal)
        if data.depositPercentage > 0 {
            return (proposal.totalAmount * data.depositPercentage) / 100.0
        } else {
            return data.depositAmount
        }
    }
}
