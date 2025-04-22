//
//  CustomProductTableView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 17.04.2025.
//


//
//  CustomProductTableView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 17.04.2025.
//

// CustomProductTableView.swift
// Enhanced version with proper horizontal scrolling and improved layout

import SwiftUI
import CoreData

struct CustomProductTableView: View {
    let products: [Product]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header - scrollable
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    Text("Code")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 90, alignment: .leading)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 36)
                    
                    Text("Name")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 180, alignment: .leading)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 36)
                    
                    Text("Category")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 120, alignment: .leading)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 36)
                    
                    Text("List Price")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .trailing)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 36)
                    
                    Text("Partner")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .trailing)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 36)
                    
                    Text("Margin")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 70, alignment: .trailing)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 36)
                    
                    Text("Status")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .center)
                        .padding(.horizontal, 5)
                }
                .padding(.vertical, 10)
                .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray5))
            }
            
            Divider()
            
            // Table rows in scrolling list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if products.isEmpty {
                        Text("No products available")
                            .foregroundColor(.secondary)
                            .padding(20)
                    } else {
                        ForEach(products, id: \.self) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 0) {
                                        Text(product.code ?? "")
                                            .font(.system(size: 14))
                                            .frame(width: 90, alignment: .leading)
                                            .padding(.horizontal, 5)
                                            .lineLimit(1)
                                        
                                        Divider().frame(height: 40)
                                        
                                        Text(product.name ?? "")
                                            .font(.system(size: 14))
                                            .frame(width: 180, alignment: .leading)
                                            .padding(.horizontal, 5)
                                            .lineLimit(1)
                                        
                                        Divider().frame(height: 40)
                                        
                                        Text(product.category ?? "")
                                            .font(.system(size: 14))
                                            .frame(width: 120, alignment: .leading)
                                            .padding(.horizontal, 5)
                                            .lineLimit(1)
                                        
                                        Divider().frame(height: 40)
                                        
                                        Text(formatPrice(product.listPrice))
                                            .font(.system(size: 14))
                                            .frame(width: 80, alignment: .trailing)
                                            .padding(.horizontal, 5)
                                        
                                        Divider().frame(height: 40)
                                        
                                        Text(formatPrice(product.partnerPrice))
                                            .font(.system(size: 14))
                                            .frame(width: 80, alignment: .trailing)
                                            .padding(.horizontal, 5)
                                        
                                        Divider().frame(height: 40)
                                        
                                        let margin = calculateMargin(product.listPrice, product.partnerPrice)
                                        Text(String(format: "%.1f%%", margin))
                                            .font(.system(size: 14))
                                            .frame(width: 70, alignment: .trailing)
                                            .padding(.horizontal, 5)
                                            .foregroundColor(margin >= 20 ? .green : (margin >= 10 ? .orange : .red))
                                        
                                        Divider().frame(height: 40)
                                        
                                        // Status indicator (active/inactive)
                                        Circle()
                                            .fill(product.partnerPrice > 0 ? Color.green : Color.gray)
                                            .frame(width: 12, height: 12)
                                            .frame(width: 80, alignment: .center)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .frame(height: 44)
                                .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
            }
            .frame(minHeight: 300, maxHeight: .infinity)
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatPrice(_ value: Double) -> String {
        return String(format: "$%.2f", value)
    }
    
    private func calculateMargin(_ list: Double, _ partner: Double) -> Double {
        return list > 0 ? ((list - partner) / list) * 100 : 0
    }
}

struct CustomProductListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var searchText = ""
    @State private var showingAddProduct = false
    @State private var showingImportCSV = false
    @State private var selectedCategory: String? = nil
    @State private var isTableView = true // Toggle between list and table view
    @State private var sortOrder: SortOrder = .nameAsc
    
    enum SortOrder: String, CaseIterable {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case priceAsc = "Price (Low-High)"
        case priceDesc = "Price (High-Low)"
        case codeAsc = "Code (A-Z)"
        case marginAsc = "Margin (Low-High)"
        case marginDesc = "Margin (High-Low)"
    }
    
    var categories: [String] {
        let categorySet = Set(products.compactMap { $0.category })
        return Array(categorySet).sorted()
    }
    
    var body: some View {
        VStack {
            // Top controls row
            HStack {
                // View type toggle
                Picker("View Type", selection: $isTableView) {
                    Text("List View").tag(false)
                    Text("Table View").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
                
                Spacer()
                
                // Sort order picker
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 180)
            }
            .padding(.horizontal)
            
            if products.isEmpty {
                VStack(spacing: 20) {
                    Text("No Products Available")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Import products from CSV or add them manually")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        Button(action: { showingImportCSV = true }) {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { showingAddProduct = true }) {
                            Label("Add Product", systemImage: "plus")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            } else {
                VStack {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button(action: { selectedCategory = nil }) {
                                Text("All")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .cornerRadius(20)
                            }
                            
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    if isTableView {
                        // TABLE VIEW (enhanced detailed view)
                        CustomProductTableView(products: sortedFilteredProducts)
                            .padding(.horizontal)
                    } else {
                        // STANDARD LIST VIEW
                        List {
                            ForEach(sortedFilteredProducts, id: \.self) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(product.formattedCode)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text(product.category ?? "Uncategorized")
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                        
                                        Text(product.formattedName)
                                            .font(.headline)
                                        
                                        Text(product.desc ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            Text("List: \(product.formattedPrice)")
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Text("Partner: \(String(format: "%.2f", product.partnerPrice))")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete(perform: deleteProducts)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Products")
        .navigationTitle("Products (\(products.count))")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddProduct = true }) {
                        Label("Add Product", systemImage: "plus")
                    }
                    
                    Button(action: { showingImportCSV = true }) {
                        Label("Import CSV", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddProduct) {
            AddProductView()
        }
        .sheet(isPresented: $showingImportCSV) {
            ProductImportView()
        }
    }
    
    private var filteredProducts: [Product] {
        var filtered = Array(products)
        
        // Apply category filter if selected
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { product in
                (product.code?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (product.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (product.desc?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (product.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    private var sortedFilteredProducts: [Product] {
        let filtered = filteredProducts
        
        // Apply sorting
        switch sortOrder {
        case .nameAsc:
            return filtered.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .nameDesc:
            return filtered.sorted { ($0.name ?? "") > ($1.name ?? "") }
        case .priceAsc:
            return filtered.sorted { $0.listPrice < $1.listPrice }
        case .priceDesc:
            return filtered.sorted { $0.listPrice > $1.listPrice }
        case .codeAsc:
            return filtered.sorted { ($0.code ?? "") < ($1.code ?? "") }
        case .marginAsc:
            return filtered.sorted { calculateMargin($0) < calculateMargin($1) }
        case .marginDesc:
            return filtered.sorted { calculateMargin($0) > calculateMargin($1) }
        }
    }
    
    private func calculateMargin(_ product: Product) -> Double {
        if product.listPrice <= 0 {
            return 0
        }
        return ((product.listPrice - product.partnerPrice) / product.listPrice) * 100
    }
    
    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredProducts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting product: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}