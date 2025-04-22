//
//  AddProductView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// AddProductView.swift
// Form for adding a new product

import SwiftUI

struct AddProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // Form fields
    @State private var code = ""
    @State private var name = ""
    @State private var productDescription = ""
    @State private var category = ""
    @State private var listPrice = ""
    @State private var partnerPrice = ""
    
    // For category selection
    @State private var showingCategoryPicker = false
    @State private var categoryOptions = ["Hardware", "Software", "Services", "Accessories", "Other"]
    
    // Validation
    private var isFormValid: Bool {
        !code.isEmpty && !name.isEmpty && validatePrices()
    }
    
    private func validatePrices() -> Bool {
        guard let listPriceValue = Double(listPrice), 
              let partnerPriceValue = Double(partnerPrice) else {
            return false
        }
        
        return listPriceValue > 0 && partnerPriceValue >= 0 && partnerPriceValue <= listPriceValue
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic product information
                Section(header: Text("PRODUCT INFORMATION")) {
                    TextField("Product Code", text: $code)
                        .autocapitalization(.none)
                    
                    TextField("Product Name", text: $name)
                        .autocapitalization(.words)
                    
                    // Description with proper height
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $productDescription)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 8)
                    
                    // Category selection
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(category.isEmpty ? "Select Category" : category)
                            .foregroundColor(category.isEmpty ? .secondary : .primary)
                            .onTapGesture {
                                showingCategoryPicker = true
                            }
                    }
                    .actionSheet(isPresented: $showingCategoryPicker) {
                        ActionSheet(
                            title: Text("Select Category"),
                            buttons: categoryButtons()
                        )
                    }
                }
                
                // Pricing information
                Section(header: Text("PRICING")) {
                    HStack {
                        Text("List Price")
                        Spacer()
                        TextField("0.00", text: $listPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Partner Price")
                        Spacer()
                        TextField("0.00", text: $partnerPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    // Show calculated margin
                    if let listPriceValue = Double(listPrice), 
                       let partnerPriceValue = Double(partnerPrice),
                       listPriceValue > 0 {
                        let margin = ((listPriceValue - partnerPriceValue) / listPriceValue) * 100
                        
                        HStack {
                            Text("Margin")
                            Spacer()
                            Text(String(format: "%.1f%%", margin))
                                .foregroundColor(margin >= 30 ? .green : (margin >= 20 ? .orange : .red))
                        }
                    }
                }
                
                // Add product button
                Section {
                    Button(action: saveProduct) {
                        Text("Add Product")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Product")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    // Generate category picker buttons
    private func categoryButtons() -> [ActionSheet.Button] {
        var buttons = categoryOptions.map { category in
            ActionSheet.Button.default(Text(category)) {
                self.category = category
            }
        }
        
        // Add "Other" option that enables custom entry
        buttons.append(.default(Text("Custom...")) {
            // Set empty category to allow user to type
            self.category = ""
            
            // Show alert for custom entry
            let alertController = UIAlertController(
                title: "Enter Category",
                message: "Please enter a custom category name",
                preferredStyle: .alert
            )
            
            alertController.addTextField { textField in
                textField.placeholder = "Category Name"
            }
            
            alertController.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel
            ))
            
            alertController.addAction(UIAlertAction(
                title: "OK",
                style: .default
            ) { _ in
                if let textField = alertController.textFields?.first,
                   let categoryText = textField.text,
                   !categoryText.isEmpty {
                    self.category = categoryText
                    
                    // Add to options if not already present
                    if !self.categoryOptions.contains(categoryText) {
                        self.categoryOptions.append(categoryText)
                    }
                }
            })
            
            // Present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alertController, animated: true)
            }
        })
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
    
    // Save the product to Core Data
    private func saveProduct() {
        guard let listPriceValue = Double(listPrice),
              let partnerPriceValue = Double(partnerPrice) else {
            return
        }
        
        withAnimation {
            let newProduct = Product(context: viewContext)
            newProduct.id = UUID()
            newProduct.code = code
            newProduct.name = name
            newProduct.desc = productDescription
            newProduct.category = category
            newProduct.listPrice = listPriceValue
            newProduct.partnerPrice = partnerPriceValue
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving product: \(nsError), \(nsError.userInfo)")
                
                // Show error alert (would implement in a full app)
            }
        }
    }
}

struct AddProductView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}