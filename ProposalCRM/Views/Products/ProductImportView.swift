// ProductImportView.swift
// Enhanced version for reliable CSV import with support for large files

import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ProductImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isImporting = false
    @State private var importedCSVString: String? = nil
    @State private var isImportingData = false
    @State private var progress: Float = 0.0
    @State private var status = "Ready to import"
    @State private var debugText = ""
    @State private var showDebug = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var showDeleteConfirmation = false
    @State private var parsedProducts: [ImportProduct] = []
    @State private var showParsedProducts = false
    @State private var totalRowsInFile: Int = 0
    @State private var currentBatchNumber: Int = 0
    @State private var totalBatches: Int = 0
    
    // Model for imported products
    struct ImportProduct: Identifiable {
        let id = UUID()
        let code: String
        let name: String
        let description: String
        let category: String
        let listPrice: Double
        let partnerPrice: Double
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    if importedCSVString == nil && !isImportingData {
                        initialView
                    } else if isImportingData {
                        importProgressView
                    } else if showParsedProducts {
                        productPreviewView
                    }
                }
                .padding()
            }
            .navigationTitle("Import Products")
            .sheet(isPresented: $isImporting) {
                DocumentPicker(csvString: $importedCSVString, errorMessage: $errorMessage, totalRowsInFile: $totalRowsInFile)
                    .onDisappear {
                        if let csvString = importedCSVString {
                            parseCSV(csvString)
                        }
                    }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .alert("Delete All Products", isPresented: $showDeleteConfirmation) {
                Button("Delete All", role: .destructive) {
                    deleteAllProducts()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete all products from the database? This action cannot be undone.")
            }
        }
    }
    
    // Initial view with import and delete buttons
    private var initialView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Import Products from CSV")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Use a CSV file with columns for Code, Name, Description, Category, List Price, and Partner Price")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                isImporting = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Select CSV File")
                }
                .frame(minWidth: 200)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Delete All Products Button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete All Products")
                }
                .frame(minWidth: 200)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 20)
        }
    }
    
    // Import progress view
    private var importProgressView: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
            
            if totalBatches > 0 {
                Text("\(status) - Batch \(currentBatchNumber) of \(totalBatches)")
                    .font(.headline)
            } else {
                Text(status)
                    .font(.headline)
            }
            
            // Debug toggle button
            Button(action: { showDebug.toggle() }) {
                Text(showDebug ? "Hide Debug Info" : "Show Debug Info")
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
            }
            
            // Debug info box
            if showDebug {
                ScrollView {
                    Text(debugText)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 200)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: {
                // Cancel import
                importedCSVString = nil
                isImportingData = false
                progress = 0.0
                status = "Ready to import"
                debugText = ""
                parsedProducts = []
                totalRowsInFile = 0
                currentBatchNumber = 0
                totalBatches = 0
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    // Product preview view
    private var productPreviewView: some View {
        VStack {
            // Preview header
            HStack {
                Text("Products to Import: \(parsedProducts.count) of \(totalRowsInFile)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showDebug.toggle() }) {
                    Text(showDebug ? "Hide Debug" : "Show Debug")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    importedCSVString = nil
                    isImportingData = false
                    progress = 0.0
                    status = "Ready to import"
                    debugText = ""
                    parsedProducts = []
                    showParsedProducts = false
                    totalRowsInFile = 0
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            if showDebug {
                ScrollView {
                    Text(debugText)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 200)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Summary stats
            VStack(spacing: 5) {
                HStack {
                    Text("List: \(formatCurrency(parsedProducts.reduce(0.0) { $0 + $1.listPrice }))")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Partner: \(formatCurrency(parsedProducts.reduce(0.0) { $0 + $1.partnerPrice }))")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    let avgDiscount = calculateAvgDiscount()
                    Text("Avg Discount: \(String(format: "%.1f%%", avgDiscount))")
                        .foregroundColor(.green)
                    Spacer()
                    
                    let categories = Set(parsedProducts.map { $0.category }).filter { !$0.isEmpty }
                    Text("\(categories.count) Categories")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Product table preview
            productTableView
            
            // Import button
            Button(action: {
                isImportingData = true
                saveProducts()
            }) {
                if isImportingData {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Import \(parsedProducts.count) Products")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(parsedProducts.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(parsedProducts.isEmpty || isImportingData)
            .padding()
        }
    }
    
    private var productTableView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table header
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    Text("Code")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 100, alignment: .leading)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 30)
                    
                    Text("Name")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 150, alignment: .leading)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 30)
                    
                    Text("Category")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 100, alignment: .leading)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 30)
                    
                    Text("List Price")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 90, alignment: .trailing)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 30)
                    
                    Text("Partner")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 90, alignment: .trailing)
                        .padding(.horizontal, 5)
                    
                    Divider().frame(height: 30)
                    
                    Text("Discount")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .trailing)
                        .padding(.horizontal, 5)
                }
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray5))
            }
            
            Divider()
            
            // Product rows
            ScrollView {
                if parsedProducts.isEmpty {
                    Text("No products found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(parsedProducts.prefix(50)) { product in
                            HStack(spacing: 0) {
                                Text(product.code)
                                    .font(.system(size: 14))
                                    .frame(width: 100, alignment: .leading)
                                    .padding(.horizontal, 5)
                                    .lineLimit(1)
                                
                                Divider().frame(height: 40)
                                
                                Text(product.name)
                                    .font(.system(size: 14))
                                    .frame(width: 150, alignment: .leading)
                                    .padding(.horizontal, 5)
                                    .lineLimit(1)
                                
                                Divider().frame(height: 40)
                                
                                Text(product.category)
                                    .font(.system(size: 14))
                                    .frame(width: 100, alignment: .leading)
                                    .padding(.horizontal, 5)
                                    .lineLimit(1)
                                
                                Divider().frame(height: 40)
                                
                                Text(formatCurrency(product.listPrice))
                                    .font(.system(size: 14))
                                    .frame(width: 90, alignment: .trailing)
                                    .padding(.horizontal, 5)
                                
                                Divider().frame(height: 40)
                                
                                Text(formatCurrency(product.partnerPrice))
                                    .font(.system(size: 14))
                                    .frame(width: 90, alignment: .trailing)
                                    .padding(.horizontal, 5)
                                
                                Divider().frame(height: 40)
                                
                                let discount = calculateDiscount(list: product.listPrice, partner: product.partnerPrice)
                                Text(String(format: "%.1f%%", discount))
                                    .font(.system(size: 14))
                                    .frame(width: 80, alignment: .trailing)
                                    .padding(.horizontal, 5)
                                    .foregroundColor(discount >= 20 ? .green : (discount >= 10 ? .orange : .red))
                            }
                            .padding(.vertical, 8)
                            .background(Color(UIColor.systemBackground))
                            
                            Divider()
                        }
                        
                        if parsedProducts.count > 50 {
                            Text("... and \(parsedProducts.count - 50) more items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func log(_ message: String) {
        debugText += message + "\n"
        print(message)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
    }
    
    private func calculateDiscount(list: Double, partner: Double) -> Double {
        if list <= 0 {
            return 0
        }
        return ((list - partner) / list) * 100
    }
    
    private func calculateAvgDiscount() -> Double {
        if parsedProducts.isEmpty {
            return 0
        }
        
        let totalDiscount = parsedProducts.reduce(0.0) { sum, product in
            return sum + calculateDiscount(list: product.listPrice, partner: product.partnerPrice)
        }
        
        return totalDiscount / Double(parsedProducts.count)
    }
    
    // MARK: - CSV Parsing
    
    private func parseCSV(_ csvString: String) {
        isImportingData = true
        progress = 0.1
        status = "Analyzing CSV file..."
        debugText = ""
        parsedProducts = []
        
        log("Starting CSV parsing of \(csvString.count) characters")
        
        // Process in background
        DispatchQueue.global(qos: .userInitiated).async {
            // Detect line endings
            var lineEnding = "\n"
            if csvString.contains("\r\n") {
                lineEnding = "\r\n"
                log("Using Windows line endings (CRLF)")
            } else if csvString.contains("\r") {
                lineEnding = "\r"
                log("Using Mac line endings (CR)")
            } else {
                log("Using Unix line endings (LF)")
            }
            
            // Split into lines
            let lines = csvString.components(separatedBy: lineEnding)
                               .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            log("Found \(lines.count) non-empty lines")
            
            if lines.isEmpty {
                DispatchQueue.main.async {
                    errorMessage = "CSV file is empty or contains no valid data"
                    showError = true
                    isImportingData = false
                }
                return
            }
            
            // Determine separator and analyze header
            let firstLine = lines[0]
            var separator = ","
            
            // Try to detect separator
            if firstLine.contains("\t") {
                separator = "\t"
                log("Detected tab separator")
            } else if firstLine.contains(";") {
                separator = ";"
                log("Detected semicolon separator")
            } else {
                log("Using comma separator")
            }
            
            // Process in chunks to handle large files
            DispatchQueue.main.async {
                status = "Processing CSV data..."
                progress = 0.2
            }
            
            // Increased chunk size for better performance with large files
            let chunkSize = 5000
            let chunks = stride(from: 0, to: lines.count, by: chunkSize).map {
                Array(lines[$0..<min($0 + chunkSize, lines.count)])
            }
            
            log("Split into \(chunks.count) chunks of up to \(chunkSize) lines each")
            
            var allProducts: [ImportProduct] = []
            if lines.isEmpty {
                DispatchQueue.main.async {
                    errorMessage = "No data found in CSV file"
                    showError = true
                    isImportingData = false
                }
                return
            }
            
            let headerFields = parseLine(lines[0], separator: separator)
            
            // Map column indices with more comprehensive guesses
            let codeIdx = findColumnIndex(headerFields, possibleNames: ["code", "id", "sku", "product id", "product code", "product_id", "item code", "item id", "item_id", "product_code"])
            let nameIdx = findColumnIndex(headerFields, possibleNames: ["name", "product name", "title", "product_name", "item name", "item_name", "description", "product", "item"])
            let descIdx = findColumnIndex(headerFields, possibleNames: ["desc", "description", "details", "specs", "specification", "product description", "product_description", "desc.", "long description", "long_description"])
            let catIdx = findColumnIndex(headerFields, possibleNames: ["category", "type", "group", "cat", "product category", "product_category", "product type", "product_type", "department"])
            let listPriceIdx = findColumnIndex(headerFields, possibleNames: ["list price", "price", "msrp", "retail", "list_price", "retail price", "selling price", "sell price", "public price", "sales price", "customer price", "price usd"])
            let partnerPriceIdx = findColumnIndex(headerFields, possibleNames: ["partner price", "cost", "wholesale", "partner", "partner_price", "dealer price", "dealer_price", "wholesale price", "wholesale_price", "buy price", "buying price", "cost price", "supplier price"])
            
            log("Column mapping: code=\(codeIdx), name=\(nameIdx), desc=\(descIdx), cat=\(catIdx), list=\(listPriceIdx), partner=\(partnerPriceIdx)")
            
            if codeIdx < 0 || nameIdx < 0 || listPriceIdx < 0 {
                DispatchQueue.main.async {
                    errorMessage = "Could not identify required columns. Make sure your CSV has Code, Name, and List Price columns."
                    showError = true
                    isImportingData = false
                }
                return
            }
            
            // Process each chunk
            for (i, chunk) in chunks.enumerated() {
                if i == 0 && isLikelyHeader(chunk[0]) {
                    // Skip header row
                    if chunk.count > 1 {
                        processChunk(Array(chunk.dropFirst()), separator: separator, codeIdx: codeIdx, nameIdx: nameIdx,
                                    descIdx: descIdx, catIdx: catIdx, listPriceIdx: listPriceIdx,
                                    partnerPriceIdx: partnerPriceIdx, products: &allProducts)
                    }
                } else {
                    processChunk(Array(chunk), separator: separator, codeIdx: codeIdx, nameIdx: nameIdx,
                                descIdx: descIdx, catIdx: catIdx, listPriceIdx: listPriceIdx,
                                partnerPriceIdx: partnerPriceIdx, products: &allProducts)
                }
                
                DispatchQueue.main.async {
                    progress = 0.2 + (0.7 * Float(i + 1) / Float(chunks.count))
                    status = "Processed \(min((i + 1) * chunkSize, lines.count)) of \(lines.count) lines..."
                }
            }
            
            DispatchQueue.main.async {
                parsedProducts = allProducts
                log("Successfully parsed \(allProducts.count) products")
                status = "Ready to import \(allProducts.count) products"
                progress = 1.0
                isImportingData = false
                showParsedProducts = true
                
                // Update total rows for reference
                totalRowsInFile = lines.count - (isLikelyHeader(lines[0]) ? 1 : 0)
            }
        }
    }
    
    private func processChunk(_ lines: [String], separator: String, codeIdx: Int, nameIdx: Int,
                             descIdx: Int, catIdx: Int, listPriceIdx: Int, partnerPriceIdx: Int,
                             products: inout [ImportProduct]) {
        for line in lines {
            let fields = parseLine(line, separator: separator)
            
            // Skip rows without enough fields for required columns
            let requiredIdx = max(codeIdx, nameIdx, listPriceIdx)
            if fields.count <= requiredIdx {
                continue
            }
            
            // Extract fields with safe access
            let code = (codeIdx >= 0 && codeIdx < fields.count) ? fields[codeIdx].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let name = (nameIdx >= 0 && nameIdx < fields.count) ? fields[nameIdx].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let description = (descIdx >= 0 && descIdx < fields.count) ? fields[descIdx].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let category = (catIdx >= 0 && catIdx < fields.count) ? fields[catIdx].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            
            let listPriceStr = (listPriceIdx >= 0 && listPriceIdx < fields.count) ? fields[listPriceIdx].trimmingCharacters(in: .whitespacesAndNewlines) : "0"
            let partnerPriceStr = (partnerPriceIdx >= 0 && partnerPriceIdx < fields.count) ? fields[partnerPriceIdx].trimmingCharacters(in: .whitespacesAndNewlines) : "0"
            
            // Parse prices safely
            let listPrice = parsePrice(listPriceStr)
            let partnerPrice = parsePrice(partnerPriceStr)
            
            // Only add valid products
            if !code.isEmpty && !name.isEmpty && listPrice > 0 {
                let product = ImportProduct(
                    code: code,
                    name: name,
                    description: description,
                    category: category,
                    listPrice: listPrice,
                    partnerPrice: partnerPrice > 0 ? partnerPrice : (listPrice * 0.75)
                )
                products.append(product)
            }
        }
    }
    
    private func parseLine(_ line: String, separator: String) -> [String] {
        // More robust CSV parsing that handles quotes correctly
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var previousChar: Character? = nil
        
        for char in line {
            if char == "\"" {
                if inQuotes && previousChar == "\"" {
                    // Double quote inside quotes - add a single quote
                    currentField += String(char)
                    previousChar = nil // Reset so we don't handle this twice
                } else {
                    // Toggle quote state
                    inQuotes = !inQuotes
                }
            } else if String(char) == separator && !inQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            previousChar = char
        }
        
        // Add the last field
        fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return fields
    }
    
    private func findColumnIndex(_ headers: [String], possibleNames: [String]) -> Int {
        // Convert headers to lowercase for case-insensitive matching
        let lowercaseHeaders = headers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // First try exact matches
        for name in possibleNames {
            if let index = lowercaseHeaders.firstIndex(of: name.lowercased()) {
                return index
            }
        }
        
        // Then try partial matches
        for name in possibleNames {
            for (index, header) in lowercaseHeaders.enumerated() {
                if header.contains(name.lowercased()) {
                    return index
                }
            }
        }
        
        return -1
    }
    
    private func isLikelyHeader(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        let headerTerms = ["product", "code", "name", "description", "price", "category", "id", "sku", "cost", "partner"]
        
        var termCount = 0
        for term in headerTerms {
            if lowercased.contains(term) {
                termCount += 1
            }
        }
        
        return termCount >= 2
    }
    
    private func parsePrice(_ str: String) -> Double {
        // Remove currency symbols
        var cleaned = str
        for symbol in ["$", "€", "£", "¥", "₹", "₽", "¢", "₩", "₴", "₦"] {
            cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
        }
        
        // Remove spaces and non-breaking spaces
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\u{00A0}", with: "")
        
        // Replace comma with period for decimal
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        
        // Remove thousands separators (periods in numbers like 1.000.000)
        let components = cleaned.components(separatedBy: ".")
        if components.count > 2 {
            // Has multiple periods - could be thousands separators
            var result = components[0]
            for i in 1..<components.count {
                if i == components.count - 1 {
                    // Last component is decimal part
                    result += "." + components[i]
                } else {
                    // Intermediate components are thousands separators
                    result += components[i]
                }
            }
            cleaned = result
        }
        
        // Remove any remaining non-numeric characters except decimal point
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.decimalDigits.inverted.subtracting(CharacterSet(charactersIn: ".")))
        
        return Double(cleaned) ?? 0.0
    }
    
    // MARK: - Database Operations
    
    private func saveProducts() {
        status = "Saving products to database..."
        progress = 0.0
        log("Starting to save \(parsedProducts.count) products")
        
        // Use a background context
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Process in batches - increased batch size for better performance
        let batchSize = 1000
        let batches = stride(from: 0, to: parsedProducts.count, by: batchSize).map {
            Array(parsedProducts[$0..<min($0 + batchSize, parsedProducts.count)])
        }
        
        log("Split into \(batches.count) batches for saving")
        
        DispatchQueue.main.async {
            totalBatches = batches.count
        }
        
        var savedCount = 0
        
        // Save first batch and continue with others
        saveBatch(0, batches, backgroundContext, savedCount)
    }
    
    private func saveBatch(_ index: Int, _ batches: [[ImportProduct]], _ context: NSManagedObjectContext, _ savedSoFar: Int) {
        // Check if we're done
        if index >= batches.count {
            DispatchQueue.main.async {
                log("All products saved successfully!")
                errorMessage = "Successfully imported \(savedSoFar) products!"
                showError = true
                isImportingData = false
                
                // Return to initial state
                importedCSVString = nil
                parsedProducts = []
                progress = 0.0
                status = "Ready to import"
                showParsedProducts = false
                totalBatches = 0
                currentBatchNumber = 0
                
                // Dismiss the sheet
                presentationMode.wrappedValue.dismiss()
            }
            return
        }
        
        let batch = batches[index]
        let batchSize = 1000 // Define the same batchSize here
        let startIndex = index * batchSize
        
        DispatchQueue.main.async {
            status = "Saving batch \(index+1) of \(batches.count) (\(startIndex+1) to \(startIndex+batch.count))"
            progress = Float(index) / Float(batches.count)
            currentBatchNumber = index + 1
        }
        
        // Save this batch
        context.perform {
            autoreleasepool {
                // Prepare a dictionary for quick lookup of existing products
                var existingProductsByCode: [String: Product] = [:]
                
                // Collect all product codes in this batch
                let productCodes = batch.map { $0.code }
                
                // Fetch all products with these codes
                let fetchRequest = NSFetchRequest<Product>(entityName: "Product")
                fetchRequest.predicate = NSPredicate(format: "code IN %@", productCodes)
                
                do {
                    let existingProducts = try context.fetch(fetchRequest)
                    for product in existingProducts {
                        if let code = product.code {
                            existingProductsByCode[code] = product
                        }
                    }
                    
                    log("Found \(existingProducts.count) existing products to update")
                } catch {
                    log("Error fetching existing products: \(error.localizedDescription)")
                }
                
                // Process batch
                var updatedCount = 0
                var createdCount = 0
                
                for productData in batch {
                    if let existingProduct = existingProductsByCode[productData.code] {
                        // Update existing product
                        existingProduct.name = productData.name
                        existingProduct.setValue(productData.description, forKey: "desc")
                        existingProduct.category = productData.category
                        existingProduct.listPrice = productData.listPrice
                        existingProduct.partnerPrice = productData.partnerPrice
                        updatedCount += 1
                    } else {
                        // Create new product
                        let newProduct = NSEntityDescription.insertNewObject(forEntityName: "Product", into: context) as! Product
                        newProduct.id = UUID()
                        newProduct.code = productData.code
                        newProduct.name = productData.name
                        newProduct.setValue(productData.description, forKey: "desc")
                        newProduct.category = productData.category
                        newProduct.listPrice = productData.listPrice
                        newProduct.partnerPrice = productData.partnerPrice
                        createdCount += 1
                    }
                }
                
                // Save the context
                do {
                    try context.save()
                    
                    // Update count and continue with next batch
                    let newSavedCount = savedSoFar + batch.count
                    log("Saved batch \(index+1): Updated \(updatedCount), Created \(createdCount). Total saved so far: \(newSavedCount)")
                    
                    // Process next batch with a short delay to allow UI updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        saveBatch(index + 1, batches, context, newSavedCount)
                    }
                } catch {
                    DispatchQueue.main.async {
                        errorMessage = "Failed to save products: \(error.localizedDescription)"
                        log("Error saving batch \(index+1): \(error.localizedDescription)")
                        showError = true
                        isImportingData = false
                    }
                }
            }
        }
    }
    
    private func deleteAllProducts() {
        log("Starting to delete all products...")
        isImportingData = true
        status = "Deleting all products..."
        progress = 0.0
        
        // Use a background context
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        
        backgroundContext.perform {
            do {
                // Count products
                let countRequest = NSFetchRequest<Product>(entityName: "Product")
                let count = try backgroundContext.count(for: countRequest)
                
                log("Found \(count) products to delete")
                
                // Delete in batches of 1000
                let batchSize = 1000
                var deleted = 0
                var totalBatches = Int(ceil(Double(count) / Double(batchSize)))
                
                DispatchQueue.main.async {
                    self.totalBatches = totalBatches
                }
                
                while deleted < count {
                    autoreleasepool {
                        do {  // Add a new do-catch block here
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Product")
                            fetchRequest.fetchLimit = batchSize
                            
                            // Use batch delete request for better performance
                            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                            batchDeleteRequest.resultType = .resultTypeObjectIDs
                            
                            // HERE'S THE FIX: Add 'try' keyword
                            let result = try backgroundContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
                            let objectIDs = result.result as! [NSManagedObjectID]
                            
                            // Update the view context with changes
                            let changes = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
                            
                            deleted += objectIDs.count
                            
                            DispatchQueue.main.async {
                                self.progress = Float(deleted) / Float(count)
                                self.status = "Deleted \(deleted) of \(count) products"
                                self.currentBatchNumber = Int(ceil(Double(deleted) / Double(batchSize)))
                                log("Deleted batch - total deleted: \(deleted) of \(count)")
                            }
                        } catch {
                            // Handle any errors during batch deletion
                            DispatchQueue.main.async {
                                log("Error during batch deletion: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    log("Successfully deleted \(count) products")
                    errorMessage = "Successfully deleted \(count) products"
                    showError = true
                    isImportingData = false
                    totalBatches = 0
                    currentBatchNumber = 0
                }
            } catch {
                DispatchQueue.main.async {
                    log("Error deleting products: \(error.localizedDescription)")
                    errorMessage = "Error deleting products: \(error.localizedDescription)"
                    showError = true
                    isImportingData = false
                }
            }
        }
    
    }
}

// Document picker for CSV files with optimizations for large files
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var csvString: String?
    @Binding var errorMessage: String?
    @Binding var totalRowsInFile: Int
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [UTType.commaSeparatedText, UTType.text, UTType.plainText, UTType.data]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.errorMessage = "No file selected"
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                parent.errorMessage = "Cannot access the file"
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Get file size
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                // For large files, use a different approach
                if fileSize > 10_000_000 { // 10MB
                    // Count lines in the file
                    if let lineCount = countLinesInFile(at: url) {
                        parent.totalRowsInFile = lineCount
                    }
                    
                    // Process file in chunks
                    if let string = readLargeFile(at: url) {
                        parent.csvString = string
                    } else {
                        parent.errorMessage = "Failed to read large file - insufficient memory"
                    }
                    return
                }
                
                // For smaller files, read the entire file at once
                do {
                    let data = try Data(contentsOf: url)
                    
                    // Count lines
                    if let string = String(data: data, encoding: .utf8) {
                        parent.totalRowsInFile = string.components(separatedBy: .newlines).count
                    }
                    
                    // Try UTF-8 first
                    if let string = String(data: data, encoding: .utf8) {
                        parent.csvString = string
                        return
                    }
                    
                    // Try ISO Latin 1
                    if let string = String(data: data, encoding: .isoLatin1) {
                        parent.csvString = string
                        return
                    }
                    
                    // Try Windows CP1252
                    if let string = String(data: data, encoding: .windowsCP1252) {
                        parent.csvString = string
                        return
                    }
                    
                    // Fallback
                    let fallbackString = String(decoding: data, as: UTF8.self)
                    if !fallbackString.isEmpty {
                        parent.csvString = fallbackString
                    } else {
                        parent.errorMessage = "Failed to convert file to text - unsupported encoding"
                    }
                } catch {
                    parent.errorMessage = "Failed to read file: \(error.localizedDescription)"
                }
            } catch {
                parent.errorMessage = "Failed to get file attributes: \(error.localizedDescription)"
            }
        }
        
        // Count lines in a large file
        private func countLinesInFile(at url: URL) -> Int? {
            do {
                let fileHandle = try FileHandle(forReadingFrom: url)
                defer { fileHandle.closeFile() }
                
                var lineCount = 0
                let chunkSize = 8192 // Read in chunks of 8KB
                var buffer = Data(capacity: chunkSize)
                
                while let chunk = try fileHandle.read(upToCount: chunkSize) {
                    if chunk.isEmpty { break }
                    
                    buffer.append(chunk)
                    
                    // Count newlines in buffer
                    if let string = String(data: buffer, encoding: .utf8) {
                        lineCount += string.components(separatedBy: .newlines).count - 1
                        
                        // Keep only the last line to handle potential partial lines
                        if let lastNewlineRange = string.range(of: "\n", options: .backwards) {
                            let lastLine = string[lastNewlineRange.upperBound...]
                            buffer = Data(lastLine.utf8)
                        } else {
                            buffer = Data()
                        }
                    }
                }
                
                // Count final line if buffer isn't empty
                if !buffer.isEmpty {
                    lineCount += 1
                }
                
                return lineCount
            } catch {
                print("Error counting lines: \(error)")
                return nil
            }
        }
        
        private func readLargeFile(at url: URL) -> String? {
            do {
                // Create a temporary file to store the processed output
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString)
                
                // Create file handle for reading
                let fileHandle = try FileHandle(forReadingFrom: url)
                defer { fileHandle.closeFile() }
                
                // Create file handle for writing
                FileManager.default.createFile(atPath: tempFileURL.path, contents: nil)
                let outputFileHandle = try FileHandle(forWritingTo: tempFileURL)
                defer {
                    outputFileHandle.closeFile()
                    try? FileManager.default.removeItem(at: tempFileURL)
                }
                
                // Process file in chunks
                let chunkSize = 1_000_000 // 1MB chunks
                while let chunk = try fileHandle.read(upToCount: chunkSize) {
                    if chunk.isEmpty { break }
                    
                    // Process chunk
                    outputFileHandle.write(chunk)
                }
                
                // Read the processed file - THIS IS THE FIX: adding "try" here
                return try String(contentsOf: tempFileURL)
                
            } catch {
                print("Error reading large file: \(error)")
                return nil
            }
        
        }
    }
}
