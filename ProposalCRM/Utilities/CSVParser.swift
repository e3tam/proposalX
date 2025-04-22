// CSVParser.swift
// Utilities for handling CSV file imports and exports

import Foundation
import CoreData

class CSVParser {
    
    enum CSVError: Error {
        case invalidFormat
        case invalidData
        case emptyFile
        case missingHeaders
        case fileSaveError
    }
    
    // Parse CSV string into array of dictionaries
    static func parseCSV(string: String) throws -> [[String: String]] {
        // Split into lines
        var lines = string.components(separatedBy: .newlines)
        
        // Remove empty lines
        lines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.emptyFile
        }
        
        // Extract headers from first line
        let headers = lines[0].components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !headers.isEmpty else {
            throw CSVError.missingHeaders
        }
        
        // Parse each remaining line into a dictionary
        var result: [[String: String]] = []
        
        for i in 1..<lines.count {
            let line = lines[i]
            let values = line.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Skip if line doesn't match header count
            if values.count != headers.count {
                continue
            }
            
            var entry: [String: String] = [:]
            
            for (index, header) in headers.enumerated() {
                entry[header] = values[index]
            }
            
            result.append(entry)
        }
        
        return result
    }
    
    // Specifically parse product CSV
    static func parseProductsCSV(string: String) throws -> [ProductData] {
        let rows = try parseCSV(string: string)
        var products: [ProductData] = []
        
        for row in rows {
            guard let code = row["code"],
                  let name = row["name"],
                  let description = row["description"],
                  let category = row["category"],
                  let listPriceStr = row["listPrice"],
                  let partnerPriceStr = row["partnerPrice"],
                  let listPrice = Double(listPriceStr),
                  let partnerPrice = Double(partnerPriceStr) else {
                continue
            }
            
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
    
    // Import products from CSV into Core Data
    static func importProductsFromCSV(csvString: String, context: NSManagedObjectContext) throws -> Int {
        let productDataArray = try parseProductsCSV(string: csvString)
        var importedCount = 0
        
        for productData in productDataArray {
            // Check if product with same code already exists
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "code == %@", productData.code)
            
            let existingProducts = try context.fetch(fetchRequest)
            
            if let existingProduct = existingProducts.first {
                // Update existing product
                existingProduct.name = productData.name
                
                // Fix: Use setValue(_:forKey:) instead of direct assignment for the description property
                existingProduct.setValue(productData.description, forKey: "desc")
                
                existingProduct.category = productData.category
                existingProduct.listPrice = productData.listPrice
                existingProduct.partnerPrice = productData.partnerPrice
            } else {
                // Create new product
                let product = Product(context: context)
                product.id = UUID()
                product.code = productData.code
                product.name = productData.name
                
                // Fix: Use setValue(_:forKey:) instead of direct assignment for the description property
                product.setValue(productData.description, forKey: "desc")
                
                product.category = productData.category
                product.listPrice = productData.listPrice
                product.partnerPrice = productData.partnerPrice
            }
            
            importedCount += 1
        }
        
        try context.save()
        return importedCount
    }
    
    // Export products to CSV
    static func exportProductsToCSV(products: [Product]) -> String {
        var csvString = "code,name,description,category,listPrice,partnerPrice\n"
        
        for product in products {
            let code = product.code ?? ""
            let name = product.name ?? ""
            
            // Fix: Use value(forKey:) to get the description property
            let description = product.value(forKey: "desc") as? String ?? ""
            
            let category = product.category ?? ""
            let listPrice = String(format: "%.2f", product.listPrice)
            let partnerPrice = String(format: "%.2f", product.partnerPrice)
            
            // Escape fields if they contain commas or quotes
            let escapedCode = escapeCSVField(code)
            let escapedName = escapeCSVField(name)
            let escapedDescription = escapeCSVField(description)
            let escapedCategory = escapeCSVField(category)
            
            let line = "\(escapedCode),\(escapedName),\(escapedDescription),\(escapedCategory),\(listPrice),\(partnerPrice)\n"
            csvString.append(line)
        }
        
        return csvString
    }
    
    // Helper function to escape CSV fields
    private static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        return field
    }
}
