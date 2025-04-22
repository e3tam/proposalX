import SwiftUI
import CoreData

struct ItemSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    @State private var applyCustomTax = false
    
    // Add these dictionaries for product quantities and discounts
    @State private var quantityForProduct: [UUID: Double] = [:]
    @State private var discountForProduct: [UUID: Double] = [:]
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.category, ascending: true),
                         NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedProducts: Set<Product> = []
    
    var categories: [String] {
        let categorySet = Set(products.compactMap { $0.category })
        return Array(categorySet).sorted()
    }
    
    var filteredProducts: [Product] {
        var filtered = Array(products)
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { product in
                let nameMatch = product.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let codeMatch = product.code?.localizedCaseInsensitiveContains(searchText) ?? false
                let descMatch = product.desc?.localizedCaseInsensitiveContains(searchText) ?? false
                return nameMatch || codeMatch || descMatch
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: { selectedCategory = nil }) {
                            Text("All")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                
                // Product list
                List {
                    ForEach(filteredProducts, id: \.self) { product in
                        ProductSelectionRow(product: product, isSelected: selectedProducts.contains(product)) {
                            if selectedProducts.contains(product) {
                                selectedProducts.remove(product)
                            } else {
                                selectedProducts.insert(product)
                                
                                // Initialize quantity and discount for newly selected product
                                if let id = product.id {
                                    if quantityForProduct[id] == nil {
                                        quantityForProduct[id] = 1.0
                                    }
                                    if discountForProduct[id] == nil {
                                        discountForProduct[id] = 0.0
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Tax settings section
                VStack(alignment: .leading, spacing: 8) {
                    Text("TAX SETTINGS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Toggle("Apply Custom Tax", isOn: $applyCustomTax)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding(.horizontal)
                    
                    if applyCustomTax {
                        Text("Custom taxes will be calculated based on these items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                // Selected count and add button
                VStack {
                    if !selectedProducts.isEmpty {
                        Text("\(selectedProducts.count) product\(selectedProducts.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: addSelectedItems) {
                        Text("Add Selected Products")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedProducts.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedProducts.isEmpty)
                    .padding()
                }
            }
            .navigationTitle("Add Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        addSelectedItems()
                    }
                    .disabled(selectedProducts.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // Combined function that adds products to the proposal
    private func addSelectedItems() {
        for product in selectedProducts {
            // Create new proposal item
            let item = ProposalItem(context: viewContext)
            item.id = UUID()
            item.proposal = proposal
            item.product = product
            
            // Get quantity from our quantity dictionary
            if let id = product.id {
                item.quantity = quantityForProduct[id] ?? 1.0
                item.discount = discountForProduct[id] ?? 0.0
            } else {
                item.quantity = 1.0
                item.discount = 0.0
            }
            
            // Set pricing
            item.unitPrice = product.listPrice
            item.multiplier = 1.0 // Default multiplier
            
            // Calculate amount
            let discountFactor = 1.0 - (item.discount / 100.0)
            item.amount = item.quantity * item.unitPrice * discountFactor
            
            // Apply the custom tax flag
            item.applyCustomTax = applyCustomTax
            
            // Log the activity
            ActivityLogger.logItemAdded(
                proposal: proposal,
                context: viewContext,
                itemType: "Product",
                itemName: product.name ?? "Unknown Product"
            )
        }
        
        // Save context and update totals
        do {
            try viewContext.save()
            updateProposalTotal()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error adding products: \(error)")
        }
    }
    
    // Helper function to update proposal total
    private func updateProposalTotal() {
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        // Recalculate taxes based on the new taxable items
        proposal.recalculateCustomTaxes()
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating proposal total: \(error)")
        }
    }
}

struct ProductSelectionRow: View {
    let product: Product
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.name ?? "")
                    .font(.headline)
                
                Text(product.code ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let desc = product.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "€%.2f", product.listPrice))
                    .font(.subheadline)
                
                Text(String(format: "€%.2f", product.partnerPrice))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search products", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
}
