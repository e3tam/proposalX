import SwiftUI
import CoreData

struct ItemSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
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
                            }
                        }
                    }
                }
                
                // Selected count and add button
                VStack {
                    if !selectedProducts.isEmpty {
                        Text("\(selectedProducts.count) product\(selectedProducts.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: addSelectedProducts) {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func addSelectedProducts() {
        for product in selectedProducts {
            let proposalItem = ProposalItem(context: viewContext)
            proposalItem.id = UUID()
            proposalItem.product = product
            proposalItem.proposal = proposal
            proposalItem.quantity = 1
            proposalItem.unitPrice = product.listPrice
            proposalItem.discount = 0
            proposalItem.amount = product.listPrice
            
            // Log activity
            ActivityLogger.logItemAdded(
                proposal: proposal,
                context: viewContext,
                itemType: "Product",
                itemName: product.name ?? "Unknown"
            )
        }
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error adding products: \(error)")
        }
    }
    
    private func updateProposalTotal() {
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
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
