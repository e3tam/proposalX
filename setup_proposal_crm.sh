#!/bin/bash
# ProposalCRM Project Setup Script
# This script automatically creates the folder structure and files for the ProposalCRM app

# Color codes for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ProposalCRM Project Setup ===${NC}"

# Project root directory - change this if needed
PROJECT_ROOT="./ProposalCRM"

# Create project root directory
mkdir -p "$PROJECT_ROOT"
cd "$PROJECT_ROOT"

echo -e "${GREEN}Creating folder structure...${NC}"

# Create main directory structure
mkdir -p App
mkdir -p Models
mkdir -p Views/Customers
mkdir -p Views/Products
mkdir -p Views/Proposals
mkdir -p Views/Components
mkdir -p Utilities
mkdir -p Resources/Assets.xcassets

# Create Core Data model directory for placeholder
mkdir -p Models/ProposalCRM.xcdatamodeld

echo -e "${GREEN}Creating App files...${NC}"

# Create app files
cat > App/ProposalCRMApp.swift << 'EOF'
// ProposalCRMApp.swift
// Main entry point for the application

import SwiftUI

@main
struct ProposalCRMApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
EOF

cat > App/ContentView.swift << 'EOF'
// ContentView.swift
// Main container view with tab navigation

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            NavigationView {
                CustomerListView()
            }
            .tabItem {
                Label("Customers", systemImage: "person.3")
            }
            
            NavigationView {
                ProductListView()
            }
            .tabItem {
                Label("Products", systemImage: "cube.box")
            }
            
            NavigationView {
                ProposalListView()
            }
            .tabItem {
                Label("Proposals", systemImage: "doc.text")
            }
            
            NavigationView {
                FinancialSummaryView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar")
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
EOF

echo -e "${GREEN}Creating Core Data model files...${NC}"

# Create placeholder for Core Data model
cat > Models/ProposalCRM.xcdatamodeld/README.txt << 'EOF'
This is a placeholder for the Core Data model.

In Xcode, you'll need to:
1. Create a Data Model file named ProposalCRM.xcdatamodeld
2. Add the following entities with their attributes and relationships:

- Customer (id:UUID, name:String, email:String, phone:String, address:String)
- Product (id:UUID, code:String, name:String, description:String, category:String, listPrice:Double, partnerPrice:Double)
- Proposal (id:UUID, number:String, creationDate:Date, status:String, totalAmount:Double, notes:String)
- ProposalItem (id:UUID, quantity:Double, unitPrice:Double, discount:Double, amount:Double)
- Engineering (id:UUID, description:String, days:Double, rate:Double, amount:Double)
- Expense (id:UUID, description:String, amount:Double)
- CustomTax (id:UUID, name:String, rate:Double, amount:Double)

Relationships:
- Customer to Proposals (one-to-many)
- Proposal to Customer (many-to-one)
- Proposal to ProposalItems (one-to-many)
- Proposal to Engineering (one-to-many)
- Proposal to Expenses (one-to-many)
- Proposal to CustomTaxes (one-to-many)
- ProposalItem to Product (many-to-one)
- ProposalItem to Proposal (many-to-one)
EOF

# Create Core Data Model Helper
cat > Models/CoreDataModel.swift << 'EOF'
// CoreDataModel.swift
// This file provides programmatic definitions for the Core Data model entities

import Foundation
import CoreData

// Core Data Model Manager
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ProposalCRM")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// Extension for creating sample data for preview
extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample customers
        let customer1 = Customer(context: viewContext)
        customer1.id = UUID()
        customer1.name = "Acme Corporation"
        customer1.email = "contact@acme.com"
        customer1.phone = "555-123-4567"
        customer1.address = "123 Main St, Anytown, USA"
        
        let customer2 = Customer(context: viewContext)
        customer2.id = UUID()
        customer2.name = "Tech Industries"
        customer2.email = "info@techindustries.com"
        customer2.phone = "555-987-6543"
        customer2.address = "456 Innovation Way, Silicon Valley, USA"
        
        // Create sample products
        let product1 = Product(context: viewContext)
        product1.id = UUID()
        product1.code = "CAM-001"
        product1.name = "High-Resolution Camera"
        product1.description = "Industrial 4K camera for machine vision applications"
        product1.category = "Cameras"
        product1.listPrice = 1299.99
        product1.partnerPrice = 999.99
        
        let product2 = Product(context: viewContext)
        product2.id = UUID()
        product2.code = "LENS-001"
        product2.name = "Wide-Angle Lens"
        product2.description = "120° wide-angle lens for industrial cameras"
        product2.category = "Lenses"
        product2.listPrice = 499.99
        product2.partnerPrice = 399.99
        
        // Create sample proposal
        let proposal = Proposal(context: viewContext)
        proposal.id = UUID()
        proposal.number = "PROP-2023-001"
        proposal.customer = customer1
        proposal.creationDate = Date()
        proposal.status = "Draft"
        proposal.totalAmount = 1799.98
        
        // Create sample proposal items
        let proposalItem1 = ProposalItem(context: viewContext)
        proposalItem1.id = UUID()
        proposalItem1.product = product1
        proposalItem1.proposal = proposal
        proposalItem1.quantity = 1
        proposalItem1.unitPrice = 1299.99
        proposalItem1.discount = 0
        proposalItem1.amount = 1299.99
        
        let proposalItem2 = ProposalItem(context: viewContext)
        proposalItem2.id = UUID()
        proposalItem2.product = product2
        proposalItem2.proposal = proposal
        proposalItem2.quantity = 1
        proposalItem2.unitPrice = 499.99
        proposalItem2.discount = 0
        proposalItem2.amount = 499.99
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
}

// MARK: - CoreData entity extensions

// Customer extension
extension Customer {
    var formattedName: String {
        return name ?? "Unknown Customer"
    }
    
    var proposalsArray: [Proposal] {
        let set = proposals as? Set<Proposal> ?? []
        return set.sorted {
            $0.creationDate ?? Date() > $1.creationDate ?? Date()
        }
    }
}

// Product extension
extension Product {
    var formattedCode: String {
        return code ?? "Unknown Code"
    }
    
    var formattedName: String {
        return name ?? "Unknown Product"
    }
    
    var formattedPrice: String {
        return String(format: "%.2f", listPrice)
    }
}

// Proposal extension
extension Proposal {
    var formattedNumber: String {
        return number ?? "New Proposal"
    }
    
    var formattedDate: String {
        guard let date = creationDate else {
            return "Unknown Date"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedStatus: String {
        return status ?? "Draft"
    }
    
    var formattedTotal: String {
        return String(format: "%.2f", totalAmount)
    }
    
    var customerName: String {
        return customer?.name ?? "No Customer"
    }
    
    var itemsArray: [ProposalItem] {
        let set = items as? Set<ProposalItem> ?? []
        return set.sorted {
            $0.product?.name ?? "" < $1.product?.name ?? ""
        }
    }
    
    var engineeringArray: [Engineering] {
        let set = engineering as? Set<Engineering> ?? []
        return set.sorted {
            $0.description ?? "" < $1.description ?? ""
        }
    }
    
    var expensesArray: [Expense] {
        let set = expenses as? Set<Expense> ?? []
        return set.sorted {
            $0.description ?? "" < $1.description ?? ""
        }
    }
    
    var taxesArray: [CustomTax] {
        let set = taxes as? Set<CustomTax> ?? []
        return set.sorted {
            $0.name ?? "" < $1.name ?? ""
        }
    }
    
    var subtotalProducts: Double {
        let items = itemsArray
        return items.reduce(0) { $0 + $1.amount }
    }
    
    var subtotalEngineering: Double {
        let engineering = engineeringArray
        return engineering.reduce(0) { $0 + $1.amount }
    }
    
    var subtotalExpenses: Double {
        let expenses = expensesArray
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    var subtotalTaxes: Double {
        let taxes = taxesArray
        return taxes.reduce(0) { $0 + $1.amount }
    }
    
    var totalCost: Double {
        var cost = 0.0
        for item in itemsArray {
            if let product = item.product {
                cost += product.partnerPrice * item.quantity
            }
        }
        return cost + subtotalExpenses
    }
    
    var grossProfit: Double {
        return totalAmount - totalCost
    }
    
    var profitMargin: Double {
        if totalAmount == 0 {
            return 0
        }
        return (grossProfit / totalAmount) * 100
    }
}

// ProposalItem extension
extension ProposalItem {
    var productName: String {
        return product?.name ?? "Unknown Product"
    }
    
    var productCode: String {
        return product?.code ?? "Unknown Code"
    }
    
    var formattedAmount: String {
        return String(format: "%.2f", amount)
    }
}

// Engineering extension
extension Engineering {
    var formattedAmount: String {
        return String(format: "%.2f", amount)
    }
}

// Expense extension
extension Expense {
    var formattedAmount: String {
        return String(format: "%.2f", amount)
    }
}

// CustomTax extension
extension CustomTax {
    var formattedRate: String {
        return String(format: "%.2f%%", rate)
    }
    
    var formattedAmount: String {
        return String(format: "%.2f", amount)
    }
}
EOF

echo -e "${GREEN}Creating Model and Utility files...${NC}"

# Create FinancialCalculator
cat > Models/FinancialCalculator.swift << 'EOF'
// FinancialCalculator.swift
// Handles complex pricing calculations for proposals

import Foundation
import CoreData

class FinancialCalculator {
    // Calculate pricing with various discount levels
    static func calculatePrice(listPrice: Double, discount: Double) -> Double {
        return listPrice * (1 - discount / 100)
    }
    
    // Calculate profit margin percentage
    static func calculateProfitMargin(revenue: Double, cost: Double) -> Double {
        if revenue == 0 {
            return 0
        }
        return ((revenue - cost) / revenue) * 100
    }
    
    // Calculate break-even discount
    static func calculateBreakEvenDiscount(listPrice: Double, partnerPrice: Double) -> Double {
        if listPrice == 0 {
            return 0
        }
        let breakEvenDiscount = ((listPrice - partnerPrice) / listPrice) * 100
        return breakEvenDiscount
    }
    
    // Calculate tax amount
    static func calculateTaxAmount(amount: Double, taxRate: Double) -> Double {
        return amount * (taxRate / 100)
    }
    
    // Calculate total proposal amount with all components
    static func calculateTotalProposalAmount(proposal: Proposal) -> Double {
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        return productsTotal + engineeringTotal + expensesTotal + taxesTotal
    }
    
    // Format currency based on locale
    static func formatCurrency(_ amount: Double, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(String(format: "%.2f", amount))"
    }
}
EOF

# Create CSVParser
cat > Utilities/CSVParser.swift << 'EOF'
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
                existingProduct.description = productData.description
                existingProduct.category = productData.category
                existingProduct.listPrice = productData.listPrice
                existingProduct.partnerPrice = productData.partnerPrice
            } else {
                // Create new product
                let product = Product(context: context)
                product.id = UUID()
                product.code = productData.code
                product.name = productData.name
                product.description = productData.description
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
            let description = product.description ?? ""
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

// Struct to hold product data from CSV
struct ProductData {
    let code: String
    let name: String
    let description: String
    let category: String
    let listPrice: Double
    let partnerPrice: Double
}
EOF

# Create PDFGenerator
cat > Utilities/PDFGenerator.swift << 'EOF'
// PDFGenerator.swift
// Generate PDF proposals for sharing and printing

import Foundation
import UIKit
import CoreData
import PDFKit

class PDFGenerator {
    // Main function to generate a PDF from a proposal
    static func generateProposalPDF(from proposal: Proposal) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "ProposalCRM App",
            kCGPDFContextAuthor: "Generated on \(Date().formatted())"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Use A4 page size
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            // First page with header and customer information
            context.beginPage()
            
            // Draw company logo or name
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let companyName = "Your Company Name"
            let companyNameSize = companyName.size(withAttributes: titleAttributes)
            let companyRect = CGRect(x: 30, y: 30, width: companyNameSize.width, height: companyNameSize.height)
            companyName.draw(in: companyRect, withAttributes: titleAttributes)
            
            // Draw proposal title
            let proposalFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
            let proposalAttributes: [NSAttributedString.Key: Any] = [
                .font: proposalFont,
                .foregroundColor: UIColor.black
            ]
            let proposalTitle = "PROPOSAL"
            let proposalTitleSize = proposalTitle.size(withAttributes: proposalAttributes)
            let proposalRect = CGRect(x: 30, y: 70, width: proposalTitleSize.width, height: proposalTitleSize.height)
            proposalTitle.draw(in: proposalRect, withAttributes: proposalAttributes)
            
            // Draw proposal number and date
            let detailFont = UIFont.systemFont(ofSize: 12)
            let detailAttributes: [NSAttributedString.Key: Any] = [
                .font: detailFont,
                .foregroundColor: UIColor.black
            ]
            
            let proposalNumber = "Proposal Number: \(proposal.formattedNumber)"
            let proposalNumberSize = proposalNumber.size(withAttributes: detailAttributes)
            let proposalNumberRect = CGRect(x: 30, y: 110, width: proposalNumberSize.width, height: proposalNumberSize.height)
            proposalNumber.draw(in: proposalNumberRect, withAttributes: detailAttributes)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Date: \(dateFormatter.string(from: proposal.creationDate ?? Date()))"
            let dateStringSize = dateString.size(withAttributes: detailAttributes)
            let dateRect = CGRect(x: 30, y: 130, width: dateStringSize.width, height: dateStringSize.height)
            dateString.draw(in: dateRect, withAttributes: detailAttributes)
            
            // Draw customer information
            let sectionFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionFont,
                .foregroundColor: UIColor.black
            ]
            
            let customerTitle = "Customer Information"
            let customerTitleSize = customerTitle.size(withAttributes: sectionAttributes)
            let customerTitleRect = CGRect(x: 30, y: 190, width: customerTitleSize.width, height: customerTitleSize.height)
            customerTitle.draw(in: customerTitleRect, withAttributes: sectionAttributes)
            
            // Basic PDF content implementation - would be expanded in real app
            // ...
        }
        
        return data
    }
    
    // Save PDF to Files app
    static func savePDF(_ pdfData: Data, fileName: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: url)
            return url
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    // Preview PDF
    static func previewPDF(_ url: URL) -> UIViewController {
        let pdfView = PDFView()
        pdfView.autoScales = true
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        let viewController = UIViewController()
        viewController.view = pdfView
        viewController.title = "Proposal Preview"
        
        return viewController
    }
}
EOF

echo -e "${GREEN}Creating Customer Views...${NC}"

# Create Customer View files
cat > Views/Customers/CustomerListView.swift << 'EOF'
// CustomerListView.swift
// Displays a list of customers with search functionality

import SwiftUI
import CoreData

struct CustomerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Customer>
    
    @State private var searchText = ""
    @State private var showingAddCustomer = false
    
    var body: some View {
        List {
            ForEach(filteredCustomers, id: \.self) { customer in
                NavigationLink(destination: CustomerDetailView(customer: customer)) {
                    VStack(alignment: .leading) {
                        Text(customer.formattedName)
                            .font(.headline)
                        Text(customer.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteCustomers)
        }
        .searchable(text: $searchText, prompt: "Search Customers")
        .navigationTitle("Customers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCustomer = true }) {
                    Label("Add Customer", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCustomer) {
            AddCustomerView()
        }
    }
    
    private var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                customer.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                customer.email?.localizedCaseInsensitiveContains(searchText) ?? false ||
                customer.phone?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredCustomers[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting customer: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
EOF

cat > Views/Customers/CustomerDetailView.swift << 'EOF'
// CustomerDetailView.swift
// Shows details for a specific customer and their proposals

import SwiftUI

struct CustomerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    @State private var isEditing = false
    @State private var showingNewProposal = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Customer Info Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(customer.formattedName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { isEditing = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Label(customer.email ?? "No Email", systemImage: "envelope")
                    }
                    
                    HStack {
                        Label(customer.phone ?? "No Phone", systemImage: "phone")
                    }
                    
                    HStack {
                        Label(customer.address ?? "No Address", systemImage: "location")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Proposals Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Proposals")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingNewProposal = true }) {
                            Label("New Proposal", systemImage: "plus")
                        }
                    }
                    
                    if customer.proposalsArray.isEmpty {
                        Text("No proposals yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(customer.proposalsArray, id: \.self) { proposal in
                            NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(proposal.formattedNumber)
                                            .font(.headline)
                                        Text(proposal.formattedDate)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(proposal.formattedTotal)
                                            .font(.headline)
                                        Text(proposal.formattedStatus)
                                            .font(.caption)
                                            .padding(4)
                                            .background(statusColor(for: proposal.formattedStatus))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Customer Details")
        .sheet(isPresented: $isEditing) {
            EditCustomerView(customer: customer)
        }
        .sheet(isPresented: $showingNewProposal) {
            CreateProposalView(customer: customer)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft":
            return .gray
        case "Pending":
            return .orange
        case "Sent":
            return .blue
        case "Won":
            return .green
        case "Lost":
            return .red
        case "Expired":
            return .purple
        default:
            return .gray
        }
    }
}
EOF

cat > Views/Customers/AddCustomerView.swift << 'EOF'
// AddCustomerView.swift
// Form for adding a new customer

import SwiftUI

struct AddCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customer Information")) {
                    TextField("Company Name", text: $name)
                        .autocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("New Customer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCustomer() {
        let newCustomer = Customer(context: viewContext)
        newCustomer.id = UUID()
        newCustomer.name = name
        newCustomer.email = email
        newCustomer.phone = phone
        newCustomer.address = address
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving customer: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

cat > Views/Customers/EditCustomerView.swift << 'EOF'
// EditCustomerView.swift
// Form for editing an existing customer

import SwiftUI

struct EditCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var customer: Customer
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    
    init(customer: Customer) {
        self.customer = customer
        _name = State(initialValue: customer.name ?? "")
        _email = State(initialValue: customer.email ?? "")
        _phone = State(initialValue: customer.phone ?? "")
        _address = State(initialValue: customer.address ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customer Information")) {
                    TextField("Company Name", text: $name)
                        .autocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("Edit Customer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateCustomer()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func updateCustomer() {
        customer.name = name
        customer.email = email
        customer.phone = phone
        customer.address = address
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating customer: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

echo -e "${GREEN}Creating Product Views...${NC}"

# Create Product View files
cat > Views/Products/ProductListView.swift << 'EOF'
// ProductListView.swift
// Displays a list of products with search and filter capabilities

import SwiftUI
import CoreData

struct ProductListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var searchText = ""
    @State private var showingAddProduct = false
    @State private var showingImportCSV = false
    @State private var selectedCategory: String? = nil
    
    var categories: [String] {
        let categorySet = Set(products.compactMap { $0.category })
        return Array(categorySet).sorted()
    }
    
    var body: some View {
        VStack {
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
                    
                    List {
                        ForEach(filteredProducts, id: \.self) { product in
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
                                
                                Text(product.description ?? "")
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
                        .onDelete(perform: deleteProducts)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Products")
        .navigationTitle("Products")
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
        var filtered = products
        
        // Apply category filter if selected
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { product in
                product.code?.localizedCaseInsensitiveContains(searchText) ?? false ||
                product.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                product.description?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return Array(filtered)
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
EOF

cat > Views/Products/ProductImportView.swift << 'EOF'
// ProductImportView.swift
// Import products from CSV files

import SwiftUI
import UniformTypeIdentifiers

struct ProductImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isImporting = false
    @State private var importedCSVString: String?
    @State private var importedProducts: [CSVProduct] = []
    @State private var showPreview = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isImportingData = false
    
    struct CSVProduct: Identifiable {
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
            VStack {
                if importedCSVString == nil {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Import Products from CSV")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("The CSV file should have headers and the following columns:\ncode,name,description,category,listPrice,partnerPrice")
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
                    }
                    .padding()
                } else if showPreview {
                    VStack {
                        // Preview header
                        HStack {
                            Text("Products to Import: \(importedProducts.count)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                importedCSVString = nil
                                importedProducts = []
                                showPreview = false
                            }) {
                                Text("Cancel")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Products preview
                        List {
                            ForEach(importedProducts) { product in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(product.code)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(product.category)
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text(product.name)
                                        .font(.headline)
                                    
                                    Text(product.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    
                                    HStack {
                                        Text("List: \(String(format: "%.2f", product.listPrice))")
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
                        
                        // Import button
                        Button(action: {
                            isImportingData = true
                            saveImportedProducts()
                        }) {
                            if isImportingData {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Import \(importedProducts.count) Products")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isImportingData)
                        .padding()
                    }
                }
            }
            .navigationTitle("Import Products")
            .sheet(isPresented: $isImporting) {
                DocumentPicker(importedCSVString: $importedCSVString, errorMessage: $errorMessage)
                    .onDisappear {
                        if let csvString = importedCSVString {
                            parseCSV(csvString)
                        }
                    }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Import Error"),
                    message: Text(errorMessage ?? "Unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func parseCSV(_ csvString: String) {
        // Simple CSV parsing logic
        let rows = csvString.components(separatedBy: .newlines)
        guard rows.count > 1 else {
            errorMessage = "CSV file is empty or invalid"
            showError = true
            return
        }
        
        // Check header row
        let headerRow = rows[0].components(separatedBy: ",")
        let expectedHeaders = ["code", "name", "description", "category", "listPrice", "partnerPrice"]
        
        // Simple header validation (in a real app, would be more robust)
        if !headerRow.map({ $0.lowercased() }).containsAll(elements: expectedHeaders) {
            errorMessage = "CSV headers do not match expected format"
            showError = true
            return
        }
        
        // Parse data rows
        importedProducts = []
        for i in 1..<rows.count {
            let row = rows[i]
            if row.isEmpty { continue }
            
            let columns = row.components(separatedBy: ",")
            if columns.count >= 6 {
                // Basic error handling for number parsing
                let listPrice = Double(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                let partnerPrice = Double(columns[5].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                
                let product = CSVProduct(
                    code: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                    name: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                    description: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                    category: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                    listPrice: listPrice,
                    partnerPrice: partnerPrice
                )
                importedProducts.append(product)
            }
        }
        
        showPreview = true
    }
    
    private func saveImportedProducts() {
        for csvProduct in importedProducts {
            let product = Product(context: viewContext)
            product.id = UUID()
            product.code = csvProduct.code
            product.name = csvProduct.name
            product.description = csvProduct.description
            product.category = csvProduct.category
            product.listPrice = csvProduct.listPrice
            product.partnerPrice = csvProduct.partnerPrice
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            errorMessage = "Failed to save products: \(nsError.localizedDescription)"
            showError = true
            isImportingData = false
        }
    }
}

// Document picker for CSV files
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var importedCSVString: String?
    @Binding var errorMessage: String?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText])
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
            
            do {
                let data = try Data(contentsOf: url)
                if let string = String(data: data, encoding: .utf8) {
                    parent.importedCSVString = string
                } else {
                    parent.errorMessage = "Failed to convert file to text"
                }
            } catch {
                parent.errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }
}

extension Array where Element: Equatable {
    func containsAll(elements: [Element]) -> Bool {
        for element in elements {
            if !self.contains(element) {
                return false
            }
        }
        return true
    }
}
EOF

cat > Views/Products/AddProductView.swift << 'EOF'
// AddProductView.swift
// Form for adding a new product

import SwiftUI

struct AddProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var code = ""
    @State private var name = ""
    @State private var productDescription = ""
    @State private var category = ""
    @State private var listPrice = ""
    @State private var partnerPrice = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Information")) {
                    TextField("Product Code", text: $code)
                        .autocapitalization(.none)
                    
                    TextField("Product Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Description", text: $productDescription)
                    
                    TextField("Category", text: $category)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Pricing")) {
                    TextField("List Price", text: $listPrice)
                        .keyboardType(.decimalPad)
                    
                    TextField("Partner Price", text: $partnerPrice)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Product")
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
                    .disabled(code.isEmpty || name.isEmpty || listPrice.isEmpty)
                }
            }
        }
    }
    
    private func saveProduct() {
        let product = Product(context: viewContext)
        product.id = UUID()
        product.code = code
        product.name = name
        product.description = productDescription
        product.category = category
        product.listPrice = Double(listPrice) ?? 0.0
        product.partnerPrice = Double(partnerPrice) ?? 0.0
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving product: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

echo -e "${GREEN}Creating basic Proposal Views...${NC}"

# Create basic Proposal View files
cat > Views/Proposals/ProposalListView.swift << 'EOF'
// ProposalListView.swift
// Displays a list of all proposals with filtering options

import SwiftUI
import CoreData

struct ProposalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    @State private var searchText = ""
    @State private var showingCreateProposal = false
    @State private var selectedStatus: String? = nil
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    var body: some View {
        VStack {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: { selectedStatus = nil }) {
                        Text("All")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedStatus == nil ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedStatus == nil ? .white : .primary)
                            .cornerRadius(20)
                    }
                    
                    ForEach(statusOptions, id: \.self) { status in
                        Button(action: { selectedStatus = status }) {
                            Text(status)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedStatus == status ? statusColor(for: status) : Color.gray.opacity(0.2))
                                .foregroundColor(selectedStatus == status ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            if filteredProposals.isEmpty {
                VStack(spacing: 20) {
                    if proposals.isEmpty {
                        Text("No Proposals Yet")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Create your first proposal to get started")
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingCreateProposal = true }) {
                            Label("Create Proposal", systemImage: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Text("No matching proposals")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Try changing your search or filter")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(filteredProposals, id: \.self) { proposal in
                        NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(proposal.formattedNumber)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(proposal.formattedStatus)
                                        .font(.caption)
                                        .padding(4)
                                        .background(statusColor(for: proposal.formattedStatus))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                
                                Text(proposal.customerName)
                                    .font(.subheadline)
                                
                                HStack {
                                    Text(proposal.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(proposal.formattedTotal)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteProposals)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Proposals")
        .navigationTitle("Proposals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateProposal = true }) {
                    Label("Create", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateProposal) {
            CustomerSelectionForProposalView()
        }
    }
    
    private var filteredProposals: [Proposal] {
        var filtered = proposals
        
        // Apply status filter if selected
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { proposal in
                proposal.number?.localizedCaseInsensitiveContains(searchText) ?? false ||
                proposal.customer?.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return Array(filtered)
    }
    
    private func deleteProposals(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredProposals[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting proposal: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft":
            return .gray
        case "Pending":
            return .orange
        case "Sent":
            return .blue
        case "Won":
            return .green
        case "Lost":
            return .red
        case "Expired":
            return .purple
        default:
            return .gray
        }
    }
}
EOF

cat > Views/Proposals/CustomerSelectionForProposalView.swift << 'EOF'
// CustomerSelectionForProposalView.swift
// Select a customer for a new proposal

import SwiftUI
import CoreData

struct CustomerSelectionForProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Customer>
    
    @State private var searchText = ""
    @State private var showingAddCustomer = false
    @State private var selectedCustomer: Customer?
    @State private var navigateToProposalForm = false
    
    var body: some View {
        NavigationView {
            VStack {
                if customers.isEmpty {
                    VStack(spacing: 20) {
                        Text("No Customers Available")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Add a customer first to create a proposal")
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingAddCustomer = true }) {
                            Label("Add Customer", systemImage: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredCustomers, id: \.self) { customer in
                            Button(action: {
                                selectedCustomer = customer
                                navigateToProposalForm = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(customer.formattedName)
                                            .font(.headline)
                                        Text(customer.email ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search Customers")
                }
            }
            .navigationTitle("Select Customer")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView()
            }
            .background(
                NavigationLink(
                    destination: CreateProposalView(customer: selectedCustomer),
                    isActive: $navigateToProposalForm,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    private var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                customer.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                customer.email?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
}
EOF

cat > Views/Proposals/ProposalDetailView.swift << 'EOF'
// ProposalDetailView.swift
// View a proposal's details with the ability to edit components

import SwiftUI

struct ProposalDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var proposal: Proposal
    
    @State private var showingItemSelection = false
    @State private var showingEngineeringForm = false
    @State private var showingExpensesForm = false
    @State private var showingCustomTaxForm = false
    @State private var showingEditProposal = false
    @State private var showingFinancialDetails = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Proposal header
                ProposalHeaderView(proposal: proposal)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Items Section
                SectionWithAddButton(
                    title: "Products",
                    count: proposal.itemsArray.count,
                    onAdd: { showingItemSelection = true }
                ) {
                    ForEach(proposal.itemsArray, id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.productName)
                                    .font(.headline)
                                Text(item.productCode)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(Int(item.quantity))x")
                                    .font(.subheadline)
                                Text(item.formattedAmount)
                                    .font(.headline)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Engineering Section
                SectionWithAddButton(
                    title: "Engineering",
                    count: proposal.engineeringArray.count,
                    onAdd: { showingEngineeringForm = true }
                ) {
                    ForEach(proposal.engineeringArray, id: \.self) { engineering in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(engineering.description ?? "")
                                    .font(.headline)
                                Text("\(engineering.days) days @ \(engineering.rate)/day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(engineering.formattedAmount)
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Expenses Section
                SectionWithAddButton(
                    title: "Expenses",
                    count: proposal.expensesArray.count,
                    onAdd: { showingExpensesForm = true }
                ) {
                    ForEach(proposal.expensesArray, id: \.self) { expense in
                        HStack {
                            Text(expense.description ?? "")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(expense.formattedAmount)
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Custom Taxes Section
                SectionWithAddButton(
                    title: "Custom Taxes",
                    count: proposal.taxesArray.count,
                    onAdd: { showingCustomTaxForm = true }
                ) {
                    ForEach(proposal.taxesArray, id: \.self) { tax in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tax.name ?? "")
                                    .font(.headline)
                                Text(tax.formattedRate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(tax.formattedAmount)
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Financial Summary
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Financial Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingFinancialDetails = true }) {
                            Label("Details", systemImage: "chart.bar")
                        }
                    }
                    
                    Divider()
                    
                    Group {
                        HStack {
                            Text("Products Subtotal")
                            Spacer()
                            Text(String(format: "%.2f", proposal.subtotalProducts))
                        }
                        
                        HStack {
                            Text("Engineering Subtotal")
                            Spacer()
                            Text(String(format: "%.2f", proposal.subtotalEngineering))
                        }
                        
                        HStack {
                            Text("Expenses Subtotal")
                            Spacer()
                            Text(String(format: "%.2f", proposal.subtotalExpenses))
                        }
                        
                        HStack {
                            Text("Taxes")
                            Spacer()
                            Text(String(format: "%.2f", proposal.subtotalTaxes))
                        }
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f", proposal.totalAmount))
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Profit Margin")
                            Spacer()
                            Text(String(format: "%.1f%%", proposal.profitMargin))
                                .foregroundColor(proposal.profitMargin < 20 ? .red : .green)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Notes Section
                if !proposal.notes!.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        Text(proposal.notes ?? "")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
        .navigationTitle("Proposal Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditProposal = true }) {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingItemSelection) {
            ItemSelectionView(proposal: proposal)
        }
        .sheet(isPresented: $showingEngineeringForm) {
            EngineeringView(proposal: proposal)
        }
        .sheet(isPresented: $showingExpensesForm) {
            ExpensesView(proposal: proposal)
        }
        .sheet(isPresented: $showingCustomTaxForm) {
            CustomTaxView(proposal: proposal)
        }
        .sheet(isPresented: $showingEditProposal) {
            EditProposalView(proposal: proposal)
        }
        .sheet(isPresented: $showingFinancialDetails) {
            FinancialSummaryDetailView(proposal: proposal)
        }
    }
}
EOF

# Create placeholder for other proposal files
cat > Views/Proposals/CreateProposalView.swift << 'EOF'
// CreateProposalView.swift
// Create a new proposal for a selected customer

import SwiftUI

struct CreateProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var customer: Customer?
    
    @State private var proposalNumber = ""
    @State private var status = "Draft"
    @State private var notes = ""
    @State private var creationDate = Date()
    
    @State private var showingItemSelection = false
    @State private var showingEngineeringForm = false
    @State private var showingExpensesForm = false
    @State private var showingCustomTaxForm = false
    
    @State private var proposal: Proposal?
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    var body: some View {
        Form {
            Section(header: Text("Proposal Information")) {
                TextField("Proposal Number", text: $proposalNumber)
                
                Picker("Status", selection: $status) {
                    ForEach(statusOptions, id: \.self) { status in
                        Text(status).tag(status)
                    }
                }
                
                DatePicker("Date", selection: $creationDate, displayedComponents: .date)
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .onAppear {
            // Generate a proposal number if empty
            if proposalNumber.isEmpty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let dateString = dateFormatter.string(from: Date())
                proposalNumber = "PROP-\(dateString)-001"
            }
            
            // Create the proposal object
            createProposal()
        }
        .navigationTitle("Create Proposal")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProposal()
                }
                .disabled(proposalNumber.isEmpty)
            }
        }
    }
    
    private func createProposal() {
        let newProposal = Proposal(context: viewContext)
        newProposal.id = UUID()
        newProposal.number = proposalNumber
        newProposal.creationDate = creationDate
        newProposal.status = status
        newProposal.customer = customer
        newProposal.totalAmount = 0
        newProposal.notes = notes
        
        do {
            try viewContext.save()
            proposal = newProposal
        } catch {
            let nsError = error as NSError
            print("Error creating proposal: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func saveProposal() {
        if let createdProposal = proposal {
            createdProposal.number = proposalNumber
            createdProposal.creationDate = creationDate
            createdProposal.status = status
            createdProposal.notes = notes
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving proposal: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
EOF

cat > Views/Proposals/EditProposalView.swift << 'EOF'
// EditProposalView.swift
// Form for editing an existing proposal

import SwiftUI

struct EditProposalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    @State private var proposalNumber: String
    @State private var status: String
    @State private var notes: String
    @State private var creationDate: Date
    
    let statusOptions = ["Draft", "Pending", "Sent", "Won", "Lost", "Expired"]
    
    init(proposal: Proposal) {
        self.proposal = proposal
        _proposalNumber = State(initialValue: proposal.number ?? "")
        _status = State(initialValue: proposal.status ?? "Draft")
        _notes = State(initialValue: proposal.notes ?? "")
        _creationDate = State(initialValue: proposal.creationDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Proposal Information")) {
                    TextField("Proposal Number", text: $proposalNumber)
                    
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    
                    DatePicker("Date", selection: $creationDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Customer")
                        Spacer()
                        Text(proposal.customerName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Proposal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProposal()
                    }
                    .disabled(proposalNumber.isEmpty)
                }
            }
        }
    }
    
    private func saveProposal() {
        proposal.number = proposalNumber
        proposal.status = status
        proposal.creationDate = creationDate
        proposal.notes = notes
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

cat > Views/Proposals/ProposalHeaderView.swift << 'EOF'
// ProposalHeaderView.swift
// Header view for the proposal detail screen

import SwiftUI

struct ProposalHeaderView: View {
    @ObservedObject var proposal: Proposal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(proposal.formattedNumber)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(proposal.formattedStatus)
                    .font(.subheadline)
                    .padding(6)
                    .background(statusColor(for: proposal.formattedStatus))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Customer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(proposal.customerName)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(proposal.formattedDate)
                        .font(.headline)
                }
            }
            
            HStack {
                Text("Total Amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(proposal.formattedTotal)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft":
            return .gray
        case "Pending":
            return .orange
        case "Sent":
            return .blue
        case "Won":
            return .green
        case "Lost":
            return .red
        case "Expired":
            return .purple
        default:
            return .gray
        }
    }
}
EOF

cat > Views/Proposals/SectionWithAddButton.swift << 'EOF'
// SectionWithAddButton.swift
// Reusable section component with add button

import SwiftUI

struct SectionWithAddButton<Content: View>: View {
    let title: String
    let count: Int
    let onAdd: () -> Void
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                }
            }
            
            Divider()
            
            if count == 0 {
                HStack {
                    Spacer()
                    Text("No \(title.lowercased()) added yet")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical)
            } else {
                content()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
EOF

echo -e "${GREEN}Creating Component Views...${NC}"

# Create Component View files
cat > Views/Components/ItemSelectionView.swift << 'EOF'
// ItemSelectionView.swift
// Select products to add to a proposal

import SwiftUI
import CoreData

struct ItemSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var proposal: Proposal
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedProducts: Set<UUID> = []
    @State private var quantities: [UUID: Double] = [:]
    @State private var discounts: [UUID: Double] = [:]
    
    var categories: [String] {
        let categorySet = Set(products.compactMap { $0.category })
        return Array(categorySet).sorted()
    }
    
    var body: some View {
        NavigationView {
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
                
                List {
                    ForEach(filteredProducts, id: \.self) { product in
                        HStack {
                            Button(action: {
                                toggleProductSelection(product)
                            }) {
                                HStack {
                                    Image(systemName: isSelected(product) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(isSelected(product) ? .blue : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.formattedName)
                                            .font(.headline)
                                        
                                        HStack {
                                            Text(product.formattedCode)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text(String(format: "%.2f", product.listPrice))
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if isSelected(product) {
                                Stepper(
                                    value: Binding(
                                        get: { self.quantities[product.id!] ?? 1 },
                                        set: { self.quantities[product.id!] = $0 }
                                    ),
                                    in: 1...100
                                ) {
                                    Text("\(Int(quantities[product.id!] ?? 1))")
                                        .frame(minWidth: 30)
                                }
                                .frame(width: 120)
                            }
                        }
                    }
                }
                
                // Selected products
                if !selectedProducts.isEmpty {
                    VStack {
                        Text("Selected Products (\(selectedProducts.count))")
                            .font(.headline)
                            .padding(.top)
                        
                        Divider()
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(selectedProductsArray(), id: \.self) { product in
                                    VStack {
                                        HStack {
                                            Text(product.formattedName)
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            Text("Qty: \(Int(quantities[product.id!] ?? 1))")
                                        }
                                        
                                        HStack {
                                            Text("Discount %:")
                                            
                                            Slider(
                                                value: Binding(
                                                    get: { self.discounts[product.id!] ?? 0 },
                                                    set: { self.discounts[product.id!] = $0 }
                                                ),
                                                in: 0...50,
                                                step: 1
                                            )
                                            
                                            Text("\(Int(discounts[product.id!] ?? 0))%")
                                                .frame(width: 50, alignment: .trailing)
                                        }
                                        
                                        HStack {
                                            Text("Unit: \(String(format: "%.2f", product.listPrice * (1 - (discounts[product.id!] ?? 0) / 100)))")
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Text("Total: \(String(format: "%.2f", calculateTotal(for: product)))")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 200)
                        
                        // Summary and add button
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total: \(String(format: "%.2f", calculateGrandTotal()))")
                                    .font(.headline)
                                
                                Text("\(selectedProducts.count) products, \(calculateTotalQuantity()) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                addItemsToProposal()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Add to Proposal")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
            .searchable(text: $searchText, prompt: "Search Products")
            .navigationTitle("Select Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredProducts: [Product] {
        var filtered = products
        
        // Apply category filter if selected
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { product in
                product.code?.localizedCaseInsensitiveContains(searchText) ?? false ||
                product.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                product.description?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return Array(filtered)
    }
    
    private func toggleProductSelection(_ product: Product) {
        if let id = product.id {
            if selectedProducts.contains(id) {
                selectedProducts.remove(id)
            } else {
                selectedProducts.insert(id)
                if quantities[id] == nil {
                    quantities[id] = 1
                }
                if discounts[id] == nil {
                    discounts[id] = 0
                }
            }
        }
    }
    
    private func isSelected(_ product: Product) -> Bool {
        if let id = product.id {
            return selectedProducts.contains(id)
        }
        return false
    }
    
    private func selectedProductsArray() -> [Product] {
        return products.filter { product in
            if let id = product.id {
                return selectedProducts.contains(id)
            }
            return false
        }
    }
    
    private func calculateTotal(for product: Product) -> Double {
        guard let id = product.id else { return 0 }
        
        let quantity = quantities[id] ?? 1
        let discount = discounts[id] ?? 0
        let unitPrice = product.listPrice * (1 - discount / 100)
        
        return unitPrice * quantity
    }
    
    private func calculateGrandTotal() -> Double {
        let selectedProducts = selectedProductsArray()
        return selectedProducts.reduce(0) { total, product in
            return total + calculateTotal(for: product)
        }
    }
    
    private func calculateTotalQuantity() -> Int {
        return selectedProducts.reduce(0) { total, id in
            return total + Int(quantities[id] ?? 1)
        }
    }
    
    private func addItemsToProposal() {
        for product in selectedProductsArray() {
            guard let productId = product.id else { continue }
            
            let quantity = quantities[productId] ?? 1
            let discount = discounts[productId] ?? 0
            let unitPrice = product.listPrice * (1 - discount / 100)
            let total = unitPrice * quantity
            
            let proposalItem = ProposalItem(context: viewContext)
            proposalItem.id = UUID()
            proposalItem.product = product
            proposalItem.proposal = proposal
            proposalItem.quantity = quantity
            proposalItem.unitPrice = unitPrice
            proposalItem.discount = discount
            proposalItem.amount = total
        }
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
        } catch {
            let nsError = error as NSError
            print("Error adding items to proposal: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func updateProposalTotal() {
        // Calculate total amount
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal total: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

cat > Views/Components/EngineeringView.swift << 'EOF'
// EngineeringView.swift
// Add engineering services to a proposal

import SwiftUI

struct EngineeringView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var proposal: Proposal
    
    @State private var description = ""
    @State private var days = 1.0
    @State private var rate = 800.0
    
    var amount: Double {
        return days * rate
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Engineering Details")) {
                    TextField("Description", text: $description)
                    
                    Stepper(value: $days, in: 0.5...100, step: 0.5) {
                        HStack {
                            Text("Days")
                            Spacer()
                            Text("\(days, specifier: "%.1f")")
                        }
                    }
                    
                    HStack {
                        Text("Day Rate")
                        Spacer()
                        TextField("Rate", value: $rate, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Total Amount")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f", amount))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Add Engineering")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addEngineering()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }
    
    private func addEngineering() {
        let engineering = Engineering(context: viewContext)
        engineering.id = UUID()
        engineering.description = description
        engineering.days = days
        engineering.rate = rate
        engineering.amount = amount
        engineering.proposal = proposal
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error adding engineering: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func updateProposalTotal() {
        // Calculate total amount
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal total: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

cat > Views/Components/ExpensesView.swift << 'EOF'
// ExpensesView.swift
// Add expenses to a proposal

import SwiftUI

struct ExpensesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var proposal: Proposal
    
    @State private var description = ""
    @State private var amount = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Description", text: $description)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", value: $amount, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(description.isEmpty || amount <= 0)
                }
            }
        }
    }
    
    private func addExpense() {
        let expense = Expense(context: viewContext)
        expense.id = UUID()
        expense.description = description
        expense.amount = amount
        expense.proposal = proposal
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error adding expense: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func updateProposalTotal() {
        // Calculate total amount
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal total: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

cat > Views/Components/CustomTaxView.swift << 'EOF'
// CustomTaxView.swift
// Add custom taxes to a proposal

import SwiftUI

struct CustomTaxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var proposal: Proposal
    
    @State private var name = ""
    @State private var rate = 0.0
    
    var subtotal: Double {
        return proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
    }
    
    var amount: Double {
        return subtotal * (rate / 100)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Tax Details")) {
                    TextField("Tax Name", text: $name)
                    
                    HStack {
                        Text("Rate (%)")
                        Spacer()
                        Slider(value: $rate, in: 0...30, step: 0.5)
                        Text("\(rate, specifier: "%.1f")%")
                            .frame(width: 50)
                    }
                    
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(String(format: "%.2f", subtotal))
                    }
                    
                    HStack {
                        Text("Tax Amount")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f", amount))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Add Custom Tax")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCustomTax()
                    }
                    .disabled(name.isEmpty || rate <= 0)
                }
            }
        }
    }
    
    private func addCustomTax() {
        let tax = CustomTax(context: viewContext)
        tax.id = UUID()
        tax.name = name
        tax.rate = rate
        tax.amount = amount
        tax.proposal = proposal
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error adding custom tax: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func updateProposalTotal() {
        // Calculate total amount
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal total: \(nsError), \(nsError.userInfo)")
        }
    }
}
EOF

cat > Views/Components/FinancialSummaryView.swift << 'EOF'
// FinancialSummaryView.swift
// Dashboard showing financial metrics for all proposals

import SwiftUI
import CoreData

struct FinancialSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    @State private var selectedTimePeriod = "All Time"
    
    let timePeriods = ["Last Month", "Last 3 Months", "Last 6 Months", "Last Year", "All Time"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time period picker
                Picker("Time Period", selection: $selectedTimePeriod) {
                    ForEach(timePeriods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Status Overview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Proposal Status Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            StatusCardView(
                                title: "Draft",
                                count: proposalCountByStatus("Draft"),
                                value: proposalValueByStatus("Draft"),
                                color: .gray
                            )
                            
                            StatusCardView(
                                title: "Pending",
                                count: proposalCountByStatus("Pending"),
                                value: proposalValueByStatus("Pending"),
                                color: .orange
                            )
                            
                            StatusCardView(
                                title: "Sent",
                                count: proposalCountByStatus("Sent"),
                                value: proposalValueByStatus("Sent"),
                                color: .blue
                            )
                            
                            StatusCardView(
                                title: "Won",
                                count: proposalCountByStatus("Won"),
                                value: proposalValueByStatus("Won"),
                                color: .green
                            )
                            
                            StatusCardView(
                                title: "Lost",
                                count: proposalCountByStatus("Lost"),
                                value: proposalValueByStatus("Lost"),
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Financial Summary
                VStack(alignment: .leading, spacing: 10) {
                    Text("Financial Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        // Total proposed amount
                        SummaryCardView(
                            title: "Total Proposed",
                            value: totalProposedAmount(),
                            subtitle: "\(filteredProposals.count) proposals",
                            color: .blue,
                            icon: "doc.text"
                        )
                        
                        // Won amount
                        SummaryCardView(
                            title: "Won Revenue",
                            value: proposalValueByStatus("Won"),
                            subtitle: "Success Rate: \(String(format: "%.1f%%", successRate()))",
                            color: .green,
                            icon: "checkmark.circle"
                        )
                        
                        // Average proposal value
                        SummaryCardView(
                            title: "Average Proposal Value",
                            value: averageProposalValue(),
                            subtitle: "Median: \(String(format: "%.2f", medianProposalValue()))",
                            color: .purple,
                            icon: "chart.bar"
                        )
                        
                        // Average profit margin
                        SummaryCardView(
                            title: "Average Profit Margin",
                            value: averageProfitMargin(),
                            valueFormat: "%.1f%%",
                            subtitle: "Total Profit: \(String(format: "%.2f", totalProfit()))",
                            color: .orange,
                            icon: "chart.pie"
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Financial Dashboard")
    }
    
    // MARK: - Filtered Data
    
    var filteredProposals: [Proposal] {
        let filtered = Array(proposals)
        
        // If "All Time" is selected, return all proposals
        if selectedTimePeriod == "All Time" {
            return filtered
        }
        
        // Get cutoff date based on selected time period
        let calendar = Calendar.current
        let now = Date()
        var cutoffDate: Date?
        
        switch selectedTimePeriod {
        case "Last Month":
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now)
        case "Last 3 Months":
            cutoffDate = calendar.date(byAdding: .month, value: -3, to: now)
        case "Last 6 Months":
            cutoffDate = calendar.date(byAdding: .month, value: -6, to: now)
        case "Last Year":
            cutoffDate = calendar.date(byAdding: .year, value: -1, to: now)
        default:
            cutoffDate = nil
        }
        
        // Filter proposals by date
        if let cutoffDate = cutoffDate {
            return filtered.filter { proposal in
                if let date = proposal.creationDate {
                    return date >= cutoffDate
                }
                return false
            }
        }
        
        return filtered
    }
    
    // MARK: - Financial Calculations
    
    private func proposalCountByStatus(_ status: String) -> Int {
        return filteredProposals.filter { $0.status == status }.count
    }
    
    private func proposalValueByStatus(_ status: String) -> Double {
        let statusProposals = filteredProposals.filter { $0.status == status }
        return statusProposals.reduce(0) { $0 + $1.totalAmount }
    }
    
    private func totalProposedAmount() -> Double {
        return filteredProposals.reduce(0) { $0 + $1.totalAmount }
    }
    
    private func averageProposalValue() -> Double {
        if filteredProposals.isEmpty {
            return 0
        }
        return totalProposedAmount() / Double(filteredProposals.count)
    }
    
    private func medianProposalValue() -> Double {
        let values = filteredProposals.map { $0.totalAmount }.sorted()
        
        if values.isEmpty {
            return 0
        }
        
        if values.count % 2 == 0 {
            let midIndex = values.count / 2
            return (values[midIndex - 1] + values[midIndex]) / 2
        } else {
            return values[values.count / 2]
        }
    }
    
    private func successRate() -> Double {
        let totalCompleted = proposalCountByStatus("Won") + proposalCountByStatus("Lost")
        if totalCompleted == 0 {
            return 0
        }
        return Double(proposalCountByStatus("Won")) / Double(totalCompleted) * 100
    }
    
    private func averageProfitMargin() -> Double {
        let relevantProposals = filteredProposals.filter { $0.totalAmount > 0 }
        if relevantProposals.isEmpty {
            return 0
        }
        
        let totalMargin = relevantProposals.reduce(0) { $0 + $1.profitMargin }
        return totalMargin / Double(relevantProposals.count)
    }
    
    private func totalProfit() -> Double {
        return filteredProposals.reduce(0) { $0 + $1.grossProfit }
    }
}
EOF

cat > Views/Components/StatusCardView.swift << 'EOF'
// StatusCardView.swift
// Card showing proposal status statistics

import SwiftUI

struct StatusCardView: View {
    let title: String
    let count: Int
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
            
            Text(String(format: "%.2f", value))
                .font(.subheadline)
        }
        .padding()
        .frame(width: 140, height: 120)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
EOF

cat > Views/Components/SummaryCardView.swift << 'EOF'
// SummaryCardView.swift
// Card showing a financial metric with icon

import SwiftUI

struct SummaryCardView: View {
    let title: String
    let value: Double
    var valueFormat: String = "%.2f"
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(String(format: valueFormat, value))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
EOF

echo -e "${GREEN}Creating placeholder for additional views...${NC}"

# Create placeholder for additional files
cat > Views/Proposals/FinancialSummaryDetailView.swift << 'EOF'
// FinancialSummaryDetailView.swift
// Detailed financial analysis of a proposal

import SwiftUI

struct FinancialSummaryDetailView: View {
    @ObservedObject var proposal: Proposal
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Revenue Breakdown
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Revenue Breakdown")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        // Placeholder for pie chart
                        Text("Revenue breakdown chart would go here")
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        
                        Group {
                            HStack {
                                Text("Products")
                                Spacer()
                                Text(String(format: "%.2f", proposal.subtotalProducts))
                            }
                            
                            HStack {
                                Text("Engineering")
                                Spacer()
                                Text(String(format: "%.2f", proposal.subtotalEngineering))
                            }
                            
                            HStack {
                                Text("Expenses")
                                Spacer()
                                Text(String(format: "%.2f", proposal.subtotalExpenses))
                            }
                            
                            HStack {
                                Text("Taxes")
                                Spacer()
                                Text(String(format: "%.2f", proposal.subtotalTaxes))
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Cost & Profit Analysis
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cost & Profit Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        Group {
                            HStack {
                                Text("Total Revenue")
                                Spacer()
                                Text(String(format: "%.2f", proposal.totalAmount))
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Total Cost")
                                Spacer()
                                Text(String(format: "%.2f", proposal.totalCost))
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Gross Profit")
                                Spacer()
                                Text(String(format: "%.2f", proposal.grossProfit))
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Profit Margin")
                                Spacer()
                                Text(String(format: "%.1f%%", proposal.profitMargin))
                                    .fontWeight(.bold)
                                    .foregroundColor(proposal.profitMargin < 20 ? .red : .green)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Financial Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
EOF

cat > Views/Proposals/PieChartView.swift << 'EOF'
// PieChartView.swift
// Simple pie chart for financial visualization

import SwiftUI

struct PieSlice {
    let value: Double
    let color: Color
    let title: String
}

struct PieChartView: View {
    let slices: [PieSlice]
    let total: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Placeholder for pie chart implementation
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                Text("Pie Chart")
                    .font(.headline)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

struct PieSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}
EOF

echo -e "${BLUE}=== Project Setup Complete ===${NC}"
echo -e "${GREEN}Files and folders have been created in $PROJECT_ROOT${NC}"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Open Xcode and create a new SwiftUI project named 'ProposalCRM'"
echo -e "2. Make sure to check 'Use Core Data' when creating the project"
echo -e "3. Set up the Core Data model file using the schema in Models/ProposalCRM.xcdatamodeld/README.txt"
echo -e "4. Replace the default generated files with the ones created by this script"
echo -e "5. Build and run the app in the iPad simulator"

echo -e "${BLUE}File structure created:${NC}"
find . -type f | grep -v .DS_Store | sort

echo -e "${GREEN}Done!${NC}"
