//
//  ProductListView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// ProductListView.swift
// Optimized implementation to avoid compiler type-checking issues

import SwiftUI
import CoreData

struct ProductListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch products using FetchRequest
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    // State variables
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingAddProduct = false
    @State private var showingImportSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and category filter header
                searchAndFilterHeader
                
                // Main content
                if filteredProducts.isEmpty {
                    emptyStateView
                } else {
                    productListView
                }
            }
            .navigationTitle("Products")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView()
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportProductsView()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Categories extracted from products
    private var categories: [String] {
        let categorySet = Set(products.compactMap { $0.category })
        return Array(categorySet).sorted()
    }
    
    // Filtered products based on search and category
    private var filteredProducts: [Product] {
        // Start with all products
        var result = Array(products)
        
        // Apply category filter if selected
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Apply search text filter if not empty
        if !searchText.isEmpty {
            result = result.filter { product in
                // Check if product matches search text in name, code, or description
                let nameMatch = product.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let codeMatch = product.code?.localizedCaseInsensitiveContains(searchText) ?? false
                let descMatch = product.desc?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return nameMatch || codeMatch || descMatch
            }
        }
        
        return result
    }
    
    // MARK: - View Components
    
    // Search bar and category filter
    private var searchAndFilterHeader: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search Products", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Category filter scrolling buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // "All" category button
                    categoryButton(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    // Category buttons
                    ForEach(categories, id: \.self) { category in
                        categoryButton(title: category, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // Category filter button
    private func categoryButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }
    
    // Empty state view when no products match filters
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(products.isEmpty ? "No Products Yet" : "No Matching Products")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text(products.isEmpty ? 
                 "Add your first product to get started" : 
                 "Try changing your search or filter")
                .foregroundColor(.secondary)
            
            if products.isEmpty {
                Button(action: { showingAddProduct = true }) {
                    Label("Add Product", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    // Product list view
    private var productListView: some View {
        List {
            ForEach(filteredProducts, id: \.self) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    productRow(product)
                }
            }
            .onDelete(perform: deleteProducts)
        }
    }
    
    // Individual product row
    private func productRow(_ product: Product) -> some View {
        HStack {
            // Product info column
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name ?? "")
                    .font(.headline)
                
                if let code = product.code, !code.isEmpty {
                    Text(code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if let description = product.desc, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Price column
            VStack(alignment: .trailing) {
                Text(formatPrice(product.listPrice))
                    .font(.headline)
                
                Text(formatPrice(product.partnerPrice))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Calculate and display margin
                let margin = calculateMargin(product)
                Text(formatPercent(margin))
                    .font(.caption)
                    .foregroundColor(margin >= 30 ? .green : (margin >= 20 ? .orange : .red))
            }
        }
        .padding(.vertical, 4)
    }
    
    // Toolbar items
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddProduct = true }) {
                        Label("Add Product", systemImage: "plus")
                    }
                    
                    Button(action: { showingImportSheet = true }) {
                        Label("Import Products", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: exportProducts) {
                        Label("Export Products", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddProduct = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Format price for display
    private func formatPrice(_ price: Double) -> String {
        return String(format: "%.2f", price)
    }
    
    // Calculate margin percentage
    private func calculateMargin(_ product: Product) -> Double {
        if product.listPrice <= 0 {
            return 0
        }
        
        return ((product.listPrice - product.partnerPrice) / product.listPrice) * 100
    }
    
    // Format percentage
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
    
    // Delete products
    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            // Map from the filtered products to the actual indices
            offsets.map { filteredProducts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the error
                let nsError = error as NSError
                print("Error deleting products: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Export products function
    private func exportProducts() {
        // Implementation for exporting products would go here
        print("Export products functionality would be implemented here")
    }
}



// MARK: - Preview
struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
