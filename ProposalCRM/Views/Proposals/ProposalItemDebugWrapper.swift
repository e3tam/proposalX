//
//  ProposalItemDebugWrapper.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 21.04.2025.
//

import SwiftUI
import CoreData

// This wrapper ensures the item is fully loaded before presenting the edit view
struct ProposalItemDebugWrapper: View {
    @Environment(\.managedObjectContext) private var viewContext
    let item: ProposalItem
    @Binding var didSave: Bool
    var onSave: () -> Void
    
    init(item: ProposalItem, didSave: Binding<Bool>, onSave: @escaping () -> Void) {
        self.item = item
        self._didSave = didSave
        self.onSave = onSave
        
        // Pre-load the data in the initializer
        let context = item.managedObjectContext
        if let context = context {
            context.performAndWait {
                if item.isFault {
                    context.refresh(item, mergeChanges: true)
                }
                
                if let product = item.product, product.isFault {
                    context.refresh(product, mergeChanges: true)
                }
                
                // Force load properties
                _ = item.quantity
                _ = item.discount
                _ = item.unitPrice
                _ = item.product?.name
                _ = item.product?.listPrice
                _ = item.product?.partnerPrice
            }
        }
    }
    
    var body: some View {
        EditProposalItemView(
            item: item,
            didSave: $didSave,
            onSave: onSave
        )
    }
}
