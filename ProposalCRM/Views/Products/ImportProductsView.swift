//
//  ImportProductsView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// ImportProductsView.swift
// View for importing products via CSV

import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ImportProductsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // State for file picker
    @State private var isShowingFilePicker = false
    @State private var selectedFile: URL?
    @State private var fileContent: String?
    
    // State for import results
    @State private var parseResults: [ProductData] = []
    @State private var isParsingError = false
    @State private var errorMessage = ""
    @State private var isImporting = false
    @State private var importComplete = false
    @State private var importedCount = 0
    
    // CSV template example
    private let csvExample = """
    code,name,description,category,listPrice,partnerPrice
    CAM-001,HD Camera,High definition surveillance camera,Hardware,299.99,199.99
    SOFT-123,Analysis Software,Video analysis software,Software,499.99,399.99
    """
    
    var body: some View {
        NavigationView {
            Form {
                // Instructions section
                Section(header: Text("INSTRUCTIONS")) {
                    Text("Import products using a CSV file with the following format:")
                    
                    ScrollView {
                        Text(csvExample)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                    }
                    .frame(height: 80)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
                
                // File selection section
                Section(header: Text("FILE SELECTION")) {
                    Button(action: {
                        isShowingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc")
                                .foregroundColor(.blue)
                            Text(selectedFile != nil ? selectedFile!.lastPathComponent : "Select CSV File")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if selectedFile != nil {
                        Button(action: previewCSV) {
                            Label("Preview File Contents", systemImage: "eye")
                        }
                    }
                }
                
                // Parse results section
                if !parseResults.isEmpty {
                    Section(header: Text("PREVIEW (\(parseResults.count) PRODUCTS)")) {
                        // Show first 5 products
                        ForEach(parseResults.prefix(5), id: \.code) { product in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.name)
                                        .font(.headline)
                                    Text(product.code)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", product.listPrice))
                                    .font(.subheadline)
                            }
                        }
                        
                        if parseResults.count > 5 {
                            Text("...and \(parseResults.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                
                // Error section
                if isParsingError {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Error Parsing CSV")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Import button
                if selectedFile != nil && !parseResults.isEmpty {
                    Section {
                        Button(action: importProducts) {
                            if isImporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Import \(parseResults.count) Products")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .disabled(isImporting)
                    }
                }
                
                // Success message
                if importComplete {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Successfully imported \(importedCount) products")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Support information
                Section(header: Text("SUPPORT")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you have trouble with your CSV file:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Ensure your CSV includes a header row")
                        Text("• Each product must have a code and name")
                        Text("• Prices must be numeric values")
                        
                        Button(action: {
                            downloadTemplate()
                        }) {
                            Label("Download Template", systemImage: "arrow.down.doc")
                        }
                        .padding(.top, 8)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Import Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    if let file = files.first {
                        selectedFile = file
                        loadFileContent(from: file)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isParsingError = true
                }
            }
        }
    }
    
    // Load CSV file content
    private func loadFileContent(from url: URL) {
        // Reset states
        fileContent = nil
        parseResults = []
        isParsingError = false
        importComplete = false
        
        do {
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                isParsingError = true
                errorMessage = "Permission denied to access the file."
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Read file content
            fileContent = try String(contentsOf: url)
            
            // Parse CSV
            if let content = fileContent {
                parseResults = try parseCSV(content)
            }
        } catch {
            isParsingError = true
            errorMessage = "Error reading file: \(error.localizedDescription)"
        }
    }
    
    // Parse CSV content into ProductData array
    private func parseCSV(_ content: String) throws -> [ProductData] {
        // Split into lines and remove empty lines
        var lines = content.components(separatedBy: .newlines)
        lines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard lines.count > 1 else {
            throw ImportError.emptyFile
        }
        
        // Parse header
        let headerLine = lines[0]
        let headers = headerLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Validate required headers
        let requiredHeaders = ["code", "name", "listPrice", "partnerPrice"]
        for header in requiredHeaders {
            if !headers.contains(where: { $0.lowercased() == header.lowercased() }) {
                throw ImportError.missingHeader(header)
            }
        }
        
        // Function to get index of a header
        func getHeaderIndex(_ name: String) -> Int? {
            return headers.firstIndex(where: { $0.lowercased() == name.lowercased() })
        }
        
        // Get indices for each column
        guard let codeIndex = getHeaderIndex("code"),
              let nameIndex = getHeaderIndex("name"),
              let descIndex = getHeaderIndex("description"),
              let categoryIndex = getHeaderIndex("category"),
              let listPriceIndex = getHeaderIndex("listPrice"),
              let partnerPriceIndex = getHeaderIndex("partnerPrice") else {
            throw ImportError.invalidFormat
        }
        
        // Parse data rows
        var products: [ProductData] = []
        for i in 1..<lines.count {
            let line = lines[i]
            let values = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Skip if line doesn't have enough columns
            if values.count < headers.count {
                continue
            }
            
            // Get values for each column
            let code = values[codeIndex]
            let name = values[nameIndex]
            let description = descIndex < values.count ? values[descIndex] : ""
            let category = categoryIndex < values.count ? values[categoryIndex] : ""
            
            // Parse prices
            guard let listPrice = Double(values[listPriceIndex]) else {
                throw ImportError.invalidPrice(row: i + 1, column: "listPrice")
            }
            
            guard let partnerPrice = Double(values[partnerPriceIndex]) else {
                throw ImportError.invalidPrice(row: i + 1, column: "partnerPrice")
            }
            
            // Validate required fields
            if code.isEmpty || name.isEmpty {
                throw ImportError.missingRequiredField(row: i + 1)
            }
            
            // Create product data
            let product = ProductData(
                code: code,
                name: name,
                description: description,
                category: category,
                listPrice: listPrice,
                partnerPrice: partnerPrice
            )
            
            products.append(product)
        }
        
        return products
    }
    
    // Preview CSV content
    private func previewCSV() {
        // This function would display a preview of the CSV
        // In a real app, you might show a modal with the raw content
        print("Preview CSV: \(fileContent ?? "No content")")
    }
    
    // Import products to Core Data
    private func importProducts() {
        isImporting = true
        
        // Perform import in background
        DispatchQueue.global(qos: .userInitiated).async {
            var importCount = 0
            
            for productData in parseResults {
                // Check if product already exists
                let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "code == %@", productData.code)
                
                do {
                    // Perform fetch on main context
                    var existingProducts: [Product] = []
                    
                    DispatchQueue.main.sync {
                        do {
                            existingProducts = try viewContext.fetch(fetchRequest)
                        } catch {
                            print("Error fetching: \(error)")
                        }
                    }
                    
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        if let existingProduct = existingProducts.first {
                            // Update existing product
                            existingProduct.name = productData.name
                            existingProduct.desc = productData.description
                            existingProduct.category = productData.category
                            existingProduct.listPrice = productData.listPrice
                            existingProduct.partnerPrice = productData.partnerPrice
                        } else {
                            // Create new product
                            let product = Product(context: viewContext)
                            product.id = UUID()
                            product.code = productData.code
                            product.name = productData.name
                            product.desc = productData.description
                            product.category = productData.category
                            product.listPrice = productData.listPrice
                            product.partnerPrice = productData.partnerPrice
                        }
                        
                        importCount += 1
                    }
                } catch {
                    print("Error during product import: \(error)")
                }
            }
            
            // Save context and update UI on main thread
            DispatchQueue.main.async {
                do {
                    try viewContext.save()
                    
                    self.importedCount = importCount
                    self.importComplete = true
                    self.isImporting = false
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } catch {
                    self.errorMessage = "Error saving to database: \(error.localizedDescription)"
                    self.isParsingError = true
                    self.isImporting = false
                }
            }
        }
    }
    
    // Download template function
    private func downloadTemplate() {
        // In a real app, this would save a template to the documents directory
        print("Download template functionality would go here")
        
        // Example implementation: save template to documents directory
        let fileName = "products_template.csv"
        let fileContent = csvExample
        
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Write to file
        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Show success message
            let message = "Template saved to Documents folder: \(fileName)"
            print(message)
            
            // In a real app, you would show a proper alert
        } catch {
            print("Error saving template: \(error)")
        }
    }
}

// Product data structure for import
struct ProductData: Identifiable {
    var id: String { code }
    let code: String
    let name: String
    let description: String
    let category: String
    let listPrice: Double
    let partnerPrice: Double
}

// Import errors
enum ImportError: Error, LocalizedError {
    case emptyFile
    case missingHeader(String)
    case invalidFormat
    case invalidPrice(row: Int, column: String)
    case missingRequiredField(row: Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty."
        case .missingHeader(let header):
            return "Missing required header: \(header)"
        case .invalidFormat:
            return "CSV format is invalid."
        case .invalidPrice(let row, let column):
            return "Invalid price in row \(row), column \(column)."
        case .missingRequiredField(let row):
            return "Missing required field in row \(row)."
        }
    }
}

struct ImportProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ImportProductsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
