//
//  ProposalPaymentManager.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// ProposalPaymentManager.swift
// A standalone manager class to handle payment terms without using extensions

import Foundation
import CoreData
import SwiftUI
import Combine

// Manager class to handle payment terms
class ProposalPaymentManager: ObservableObject {
    // Published property to trigger view updates
    @Published private var updateTrigger = UUID()
    
    // Singleton instance
    static let shared = ProposalPaymentManager()
    
    // Private initializer for singleton
    private init() {}
    
    // UserDefaults key prefix
    private let keyPrefix = "proposalPayment_"
    
    // MARK: - Private Data Structure
    
    // Payment data structure (for internal use only)
    private struct PaymentData: Codable {
        var terms: String = "30 days net"
        var depositRequired: Bool = false
        var depositAmount: Double = 0.0
        var depositPercentage: Double = 0.0
        var paymentMethods: [String] = ["Bank Transfer"]
        var latePenalty: String = ""
        var invoiceSchedule: String = ""
        var customTerms: String = ""
    }
    
    // MARK: - Key Generation
    
    // Generate a unique key for each proposal
    private func storageKey(for proposal: Proposal) -> String {
        guard let uuid = proposal.id?.uuidString else {
            return "\(keyPrefix)unknown"
        }
        return "\(keyPrefix)\(uuid)"
    }
    
    // MARK: - Data Access Methods
    
    // Get payment data
    private func getData(for proposal: Proposal) -> PaymentData {
        let key = storageKey(for: proposal)
        if let data = UserDefaults.standard.data(forKey: key) {
            if let decodedData = try? JSONDecoder().decode(PaymentData.self, from: data) {
                return decodedData
            }
        }
        return PaymentData() // Return default if not found
    }
    
    // Save payment data
    private func saveData(_ data: PaymentData, for proposal: Proposal) {
        let key = storageKey(for: proposal)
        if let encodedData = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encodedData, forKey: key)
        }
    }
    
    // MARK: - Public API Methods
    
    // Basic payment terms
    func getTerms(for proposal: Proposal) -> String {
        return getData(for: proposal).terms
    }
    
    func setTerms(_ terms: String, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.terms = terms
        saveData(data, for: proposal)
    }
    
    // Deposit required
    func isDepositRequired(for proposal: Proposal) -> Bool {
        return getData(for: proposal).depositRequired
    }
    
    func setDepositRequired(_ required: Bool, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.depositRequired = required
        saveData(data, for: proposal)
    }
    
    // Deposit amount
    func getDepositAmount(for proposal: Proposal) -> Double {
        return getData(for: proposal).depositAmount
    }
    
    func setDepositAmount(_ amount: Double, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.depositAmount = amount
        saveData(data, for: proposal)
    }
    
    // Deposit percentage
    func getDepositPercentage(for proposal: Proposal) -> Double {
        return getData(for: proposal).depositPercentage
    }
    
    func setDepositPercentage(_ percentage: Double, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.depositPercentage = percentage
        saveData(data, for: proposal)
    }
    
    // Payment methods
    func getPaymentMethods(for proposal: Proposal) -> [String] {
        return getData(for: proposal).paymentMethods
    }
    
    func setPaymentMethods(_ methods: [String], for proposal: Proposal) {
        var data = getData(for: proposal)
        data.paymentMethods = methods
        saveData(data, for: proposal)
    }
    
    // Late penalty
    func getLatePenalty(for proposal: Proposal) -> String {
        return getData(for: proposal).latePenalty
    }
    
    func setLatePenalty(_ penalty: String, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.latePenalty = penalty
        saveData(data, for: proposal)
    }
    
    // Invoice schedule
    func getInvoiceSchedule(for proposal: Proposal) -> String {
        return getData(for: proposal).invoiceSchedule
    }
    
    func setInvoiceSchedule(_ schedule: String, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.invoiceSchedule = schedule
        saveData(data, for: proposal)
    }
    
    // Custom terms
    func getCustomTerms(for proposal: Proposal) -> String {
        return getData(for: proposal).customTerms
    }
    
    func setCustomTerms(_ terms: String, for proposal: Proposal) {
        var data = getData(for: proposal)
        data.customTerms = terms
        saveData(data, for: proposal)
    }
    
    // Calculate deposit amount based on percentage or fixed amount
    func calculateDepositAmount(for proposal: Proposal) -> Double {
        let data = getData(for: proposal)
        if data.depositPercentage > 0 {
            return (proposal.totalAmount * data.depositPercentage) / 100.0
        } else {
            return data.depositAmount
        }
    }
}
