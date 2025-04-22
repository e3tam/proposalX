//
//  ProposalPaymentProperties.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//

// ProposalPaymentProperties.swift
// Extension of Proposal entity to provide payment-related properties that bridge to our manager

import Foundation
import CoreData
import SwiftUI

// Extension to provide payment properties as computed properties
// that use the ProposalPaymentManager internally
extension Proposal {
    // MARK: - Payment Terms Properties
    

    
    // Deposit required flag
    var depositRequired: Bool {
        get { return ProposalPaymentManager.shared.isDepositRequired(for: self) }
        set { ProposalPaymentManager.shared.setDepositRequired(newValue, for: self) }
    }
    
    // Deposit amount
    var depositAmount: Double {
        get { return ProposalPaymentManager.shared.getDepositAmount(for: self) }
        set { ProposalPaymentManager.shared.setDepositAmount(newValue, for: self) }
    }
    
    // Deposit percentage
    var depositPercentage: Double {
        get { return ProposalPaymentManager.shared.getDepositPercentage(for: self) }
        set { ProposalPaymentManager.shared.setDepositPercentage(newValue, for: self) }
    }
    
    // Payment methods
    var paymentMethods: [String] {
        get { return ProposalPaymentManager.shared.getPaymentMethods(for: self) }
        set { ProposalPaymentManager.shared.setPaymentMethods(newValue, for: self) }
    }
    
    // Late penalty
    var latePenalty: String {
        get { return ProposalPaymentManager.shared.getLatePenalty(for: self) }
        set { ProposalPaymentManager.shared.setLatePenalty(newValue, for: self) }
    }
    
    // Invoice schedule
    var invoiceSchedule: String {
        get { return ProposalPaymentManager.shared.getInvoiceSchedule(for: self) }
        set { ProposalPaymentManager.shared.setInvoiceSchedule(newValue, for: self) }
    }
    
    // Custom terms
    var customTerms: String {
        get { return ProposalPaymentManager.shared.getCustomTerms(for: self) }
        set { ProposalPaymentManager.shared.setCustomTerms(newValue, for: self) }
    }
    
    // Calculate deposit amount
    func calculateDepositAmount() -> Double {
        return ProposalPaymentManager.shared.calculateDepositAmount(for: self)
    }
}
