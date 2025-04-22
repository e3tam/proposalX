//
//  ProductDetailView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// ProductDetailView.swift
// Detailed view for a specific product

import SwiftUI

struct ProductDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var product: Product
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    // Editable properties
    @State private var editName: String
    @State private var editCode: String
    @State private var editDescription: String
    @State private var editCategory: String
    @State private var editListPrice: String
    @State private var editPartnerPrice: String
    
    // Initialize state with current product values
    init(product: Product) {
        self.product = product
        
        _editName = State(initialValue: product.name ?? "")
        _editCode = State(initialValue: product.code ?? "")
        _editDescription = State(initialValue: product.desc ?? "")
        _editCategory = State(initialValue: product.category ?? "")
        _editListPrice = State(initialValue: String(format: "%.2f", product.listPrice))
        _editPartnerPrice = State(initialValue: String(format: "%.2f", product.partnerPrice))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product header card
                productHeaderCard
                
                // Product details
                if isEditing {
                    editFormView
                } else {
                    detailsView
                }
                
                // Usage in proposals section
                if !isEditing {
                    usageInProposalsSection
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Edit Product" : "Product Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                } else {
                    Menu {
                        Button(action: { isEditing = true }) {
                            Label("Edit Product", systemImage: "pencil")
                        }
                        
                        Button(action: { showingDeleteAlert = true }) {
                            Label("Delete Product", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Product"),
                message: Text("Are you sure you want to delete this product? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteProduct()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - View Components
    
    // Product header card with main info
    private var productHeaderCard: some View {
        VStack(spacing: 12) {
            // Product code and category
            HStack {
                Text(product.code ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                if let category = product.category, !category.isEmpty {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
            }
            
            // Product name
            Text(product.name ?? "")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Product description
            if let description = product.desc, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Price information
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("List Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f", product.listPrice))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Partner Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f", product.partnerPrice))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Margin information
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Margin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", calculateMargin()))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(marginColor)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Product details view (non-editing mode)
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Details")
            
            // Details grid
            VStack(spacing: 12) {
                detailRow(label: "Product Code", value: product.code ?? "")
                detailRow(label: "Name", value: product.name ?? "")
                
                if let description = product.desc, !description.isEmpty {
                    detailRow(label: "Description", value: description, multiline: true)
                }
                
                detailRow(label: "Category", value: product.category ?? "Uncategorized")
                detailRow(label: "List Price", value: String(format: "%.2f", product.listPrice))
                detailRow(label: "Partner Price", value: String(format: "%.2f", product.partnerPrice))
                detailRow(label: "Margin", value: String(format: "%.1f%%", calculateMargin()))
                
                // Calculated fields
                let profitPerUnit = product.listPrice - product.partnerPrice
                detailRow(label: "Profit per Unit", value: String(format: "%.2f", profitPerUnit))
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
            
            // Edit button for quick access
            Button(action: { isEditing = true }) {
                Label("Edit Product", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
    }
    
    // Edit form view (editing mode)
    private var editFormView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Edit Product")
            
            VStack(spacing: 16) {
                // Code field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $editCode)
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $editName)
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $editDescription)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Category field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $editCategory)
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Price fields
                HStack(spacing: 20) {
                    // List Price
                    VStack(alignment: .leading, spacing: 8) {
                        Text("List Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $editListPrice)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Partner Price
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Partner Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $editPartnerPrice)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Display calculated margin
                if let listPrice = Double(editListPrice), 
                   let partnerPrice = Double(editPartnerPrice),
                   listPrice > 0 {
                    let margin = ((listPrice - partnerPrice) / listPrice) * 100
                    
                    HStack {
                        Text("Calculated Margin:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", margin))
                            .font(.headline)
                            .foregroundColor(margin >= 30 ? .green : (margin >= 20 ? .orange : .red))
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            
            // Action buttons
            HStack {
                Button(action: { isEditing = false }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
            }
        }
    }
    
    // Usage in proposals section
    private var usageInProposalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Used In Proposals")
            
            // If we had the relationship data, we would show actual proposals here
            // This is a placeholder
            Text("This product is not used in any proposals yet.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(10)
        }
    }
    
    // MARK: - Helper Views
    
    // Section header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    // Detail row with label and value
    private func detailRow(label: String, value: String, multiline: Bool = false) -> some View {
        HStack(alignment: multiline ? .top : .center, spacing: 10) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            if multiline {
                Text(value)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Calculate profit margin
    private func calculateMargin() -> Double {
        if product.listPrice <= 0 {
            return 0
        }
        
        return ((product.listPrice - product.partnerPrice) / product.listPrice) * 100
    }
    
    // Color based on margin
    private var marginColor: Color {
        let margin = calculateMargin()
        if margin >= 30 {
            return .green
        } else if margin >= 20 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Validate form fields
    private var isFormValid: Bool {
        guard !editName.isEmpty,
              !editCode.isEmpty,
              let listPrice = Double(editListPrice),
              let partnerPrice = Double(editPartnerPrice) else {
            return false
        }
        
        return listPrice > 0 && partnerPrice >= 0 && partnerPrice <= listPrice
    }
    
    // Save changes to Core Data
    private func saveChanges() {
        guard let listPrice = Double(editListPrice),
              let partnerPrice = Double(editPartnerPrice) else {
            return
        }
        
        product.code = editCode
        product.name = editName
        product.desc = editDescription
        product.category = editCategory
        product.listPrice = listPrice
        product.partnerPrice = partnerPrice
        
        do {
            try viewContext.save()
            isEditing = false
        } catch {
            // In a real app, show an error alert
            print("Error saving product: \(error)")
        }
    }
    
    // Delete the product
    private func deleteProduct() {
        viewContext.delete(product)
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            // In a real app, show an error alert
            print("Error deleting product: \(error)")
        }
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let product = Product(context: context)
        product.code = "CAM-001"
        product.name = "HD Camera"
        product.desc = "High definition surveillance camera with night vision"
        product.category = "Hardware"
        product.listPrice = 299.99
        product.partnerPrice = 199.99
        
        return NavigationView {
            ProductDetailView(product: product)
                .environment(\.managedObjectContext, context)
        }
    }
}