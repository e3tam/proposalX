// ProposalItemEditorWrapper.swift
// A safer wrapper for editing proposal items without causing build hangs

import SwiftUI
import CoreData

struct ProposalItemEditorWrapper: View {
    @Environment(\.managedObjectContext) private var viewContext
    let item: ProposalItem
    @Binding var didSave: Bool
    var onSave: () -> Void
    @State private var isLoading: Bool = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading item data...")
                    .padding()
            } else {
                EditProposalItemView(
                    item: item,
                    didSave: $didSave,
                    onSave: onSave
                )
            }
        }
        .onAppear {
            loadItemData()
        }
    }
    
    private func loadItemData() {
        let context = item.managedObjectContext
        if let context = context {
            // Use perform (async) instead of performAndWait
            context.perform {
                // Same operations but async
                if self.item.isFault {
                    context.refresh(self.item, mergeChanges: true)
                }
                
                if let product = self.item.product, product.isFault {
                    context.refresh(product, mergeChanges: true)
                }
                
                // Force load properties (if needed)
                _ = self.item.quantity
                _ = self.item.discount
                _ = self.item.unitPrice
                _ = self.item.product?.name
                _ = self.item.product?.listPrice
                _ = self.item.product?.partnerPrice
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        } else {
            isLoading = false
        }
    }
}