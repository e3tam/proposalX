// ProposalItemEditorWrapper.swift
// A safer wrapper for editing proposal items without causing build hangs

import SwiftUI
import CoreData

struct ProposalItemEditorWrapper: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: ProposalItem
    @Binding var didSave: Bool
    var onSave: () -> Void
    @State private var isLoading: Bool = true
    @State private var refreshTrigger = UUID() // Force refreshes
    
    // Create a strongly-typed reference to the Product
    @State private var productRef: Product?
    @State private var productName: String = ""
    @State private var productListPrice: Double = 0
    @State private var productPartnerPrice: Double = 0
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading item data...")
                    .padding()
            } else {
                EditProposalItemView(
                    item: item,
                    didSave: $didSave,
                    onSave: {
                        // First update our internal state to keep values consistent
                        refreshItemData()
                        // Then call the original onSave callback
                        onSave()
                    }
                )
                .id(refreshTrigger) // Force view refresh when needed
            }
        }
        .onAppear {
            loadItemData()
        }
    }
    
    private func loadItemData() {
        let context = item.managedObjectContext
        if let context = context {
            // Fetch the complete item with product relationship using a fetch request
            // which ensures we get a fully-loaded version
            let fetchRequest: NSFetchRequest<ProposalItem> = ProposalItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", item.id! as CVarArg)
            fetchRequest.relationshipKeyPathsForPrefetching = ["product"]
            
            context.perform {
                do {
                    let results = try context.fetch(fetchRequest)
                    
                    if let fullItem = results.first {
                        // Store references to product properties to prevent them from being dropped
                        if let product = fullItem.product {
                            self.productRef = product
                            self.productName = product.name ?? "Unknown Product"
                            self.productListPrice = product.listPrice
                            self.productPartnerPrice = product.partnerPrice
                            
                            // Make sure all product properties are accessed
                            _ = product.code
                            _ = product.desc
                            _ = product.category
                        }
                        
                        // Ensure item properties are accessed
                        _ = fullItem.quantity
                        _ = fullItem.discount
                        _ = fullItem.unitPrice
                        _ = fullItem.amount
                        _ = fullItem.multiplier
                        
                        // Update the UI on the main thread
                        DispatchQueue.main.async {
                            self.refreshTrigger = UUID()
                            self.isLoading = false
                        }
                    } else {
                        print("Error: Could not find ProposalItem with ID: \(String(describing: item.id))")
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                    }
                } catch {
                    print("Error fetching ProposalItem: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
    
    // Function to refresh the item data after an edit
    private func refreshItemData() {
        if let product = item.product {
            // Update our cached product properties
            productName = product.name ?? "Unknown Product"
            productListPrice = product.listPrice
            productPartnerPrice = product.partnerPrice
            
            // Force a view refresh
            refreshTrigger = UUID()
        }
    }
}
