import SwiftUI
import CoreData
import PDFKit
import UIKit
import MessageUI

struct ProposalDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var proposal: Proposal
    @Environment(\.colorScheme) private var colorScheme
    
    // State variables for showing different sheets
    @State private var showingItemSelection = false
    @State private var showingEngineeringForm = false
    @State private var showingExpensesForm = false
    @State private var showingCustomTaxForm = false
    @State private var showingEditProposal = false
    @State private var showingFinancialDetails = false
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: ProposalItem?
    
    // Task and activity state variables
    @State private var showingAddTask = false
    @State private var showingAddComment = false
    @State private var commentText = ""
    @State private var refreshId = UUID()  // Simple refresh trigger
    
    // State variables for product item editing
    @State private var itemToEdit: ProposalItem?
    @State private var showEditItemSheet = false
    @State private var didSaveItemChanges = false  // Track if changes were saved
    
    // State variables for engineering editing
    @State private var engineeringToEdit: Engineering?
    @State private var showEditEngineeringSheet = false
    
    // State variables for expense editing
    @State private var expenseToEdit: Expense?
    @State private var showEditExpenseSheet = false
    
    // State variables for custom tax editing
    @State private var taxToEdit: CustomTax?
    @State private var showEditTaxSheet = false
    
    // PDF Export state variables
    @State private var showingPdfPreview = false
    @State private var pdfUrl: URL?
    @State private var isGeneratingPdf = false
    @State private var showShareSheet = false
    
    // Email state variables
    @State private var showingEmailSender = false
    @State private var emailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingEmailAlert = false
    @State private var emailAlertMessage = ""
    
    var body: some View {
        ZStack {
            // Solid background to prevent drawing overlay issues
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Enhanced header section with detailed customer info
                    EnhancedProposalHeaderSection(
                        proposal: proposal,
                        onEditTapped: { showingEditProposal = true }
                    )
                    
                    // Content sections with proper spacing
                    VStack(alignment: .leading, spacing: 20) {
                        // PRODUCTS SECTION
                        ProductsTableSection(
                            proposal: proposal,
                            onAdd: { showingItemSelection = true },
                            onEdit: { item in
                                itemToEdit = item
                                showEditItemSheet = true
                            },
                            onDelete: { item in
                                itemToDelete = item
                                showDeleteConfirmation = true
                            }
                        )
                        .id(refreshId)  // Force refresh when id changes
                        
                        // ENGINEERING SECTION
                        EngineeringTableSection(
                            proposal: proposal,
                            onAdd: { showingEngineeringForm = true },
                            onEdit: { engineering in
                                engineeringToEdit = engineering
                                showEditEngineeringSheet = true
                            },
                            onDelete: { engineering in
                                deleteEngineering(engineering)
                            }
                        )
                        
                        // EXPENSES SECTION
                        ExpensesTableSection(
                            proposal: proposal,
                            onAdd: { showingExpensesForm = true },
                            onEdit: { expense in
                                expenseToEdit = expense
                                showEditExpenseSheet = true
                            },
                            onDelete: { expense in
                                deleteExpense(expense)
                            }
                        )
                        
                        // CUSTOM TAXES SECTION
                        CustomTaxesTableSection(
                            proposal: proposal,
                            onAdd: { showingCustomTaxForm = true },
                            onEdit: { tax in
                                taxToEdit = tax
                                showEditTaxSheet = true
                            },
                            onDelete: { tax in
                                deleteTax(tax)
                            }
                        )
                        
                        // FINANCIAL SUMMARY SECTION
                        financialSummarySection
                        
                        // TASK SECTION
                        taskSummarySection
                        
                        // ACTIVITY SECTION
                        activitySummarySection
                        
                        // NOTES SECTION
                        if let notes = proposal.notes, !notes.isEmpty {
                            notesSection(notes: notes)
                        }
                        
                        // Add spacing at bottom for floating button
                        Spacer().frame(height: 80)
                    }
                    .padding(.vertical, 20)
                }
            }
            
            // Floating export buttons positioned at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        emailExportButton
                        pdfExportButton
                    }
                    .padding(.bottom, 30)
                    .padding(.trailing, 20)
                }
            }
        }
        .navigationBarHidden(true)
        // SHEET PRESENTATIONS
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
            EnhancedFinancialSummaryView(proposal: proposal)
        }
        .sheet(isPresented: $showEditEngineeringSheet) {
            if let engineering = engineeringToEdit {
                NavigationView {
                    EditEngineeringView(engineering: engineering)
                        .navigationTitle("Edit Engineering")
                        .navigationBarItems(trailing: Button("Done") {
                            showEditEngineeringSheet = false
                            updateProposalTotal()
                        })
                }
            }
        }
        .sheet(isPresented: $showEditExpenseSheet) {
            if let expense = expenseToEdit {
                NavigationView {
                    EditExpenseView(expense: expense)
                        .navigationTitle("Edit Expense")
                        .navigationBarItems(trailing: Button("Done") {
                            showEditExpenseSheet = false
                            updateProposalTotal()
                        })
                }
            }
        }
        .sheet(isPresented: $showEditTaxSheet) {
            if let tax = taxToEdit {
                NavigationView {
                    EditCustomTaxView(customTax: tax, proposal: proposal)
                        .navigationTitle("Edit Custom Tax")
                        .navigationBarItems(trailing: Button("Done") {
                            showEditTaxSheet = false
                            updateProposalTotal()
                        })
                }
            }
        }
        .sheet(isPresented: $showEditItemSheet, onDismiss: {
            // Reset edit state
            itemToEdit = nil
            showEditItemSheet = false
            
            // Force complete view refresh
            if didSaveItemChanges {
                refreshId = UUID()
                didSaveItemChanges = false
            }
        }) {
            if let item = itemToEdit {
                ProposalItemDebugWrapper(
                    item: item,
                    didSave: $didSaveItemChanges,
                    onSave: {
                        // Force view refresh
                        DispatchQueue.main.async {
                            refreshId = UUID()
                        }
                    }
                )
                .environment(\.managedObjectContext, viewContext)
            }
        }
        // PDF PREVIEW SHEET
        .sheet(isPresented: $showingPdfPreview) {
            if let url = pdfUrl {
                PDFPreviewView(url: url)
            }
        }
        // EMAIL SENDER SHEET
        .sheet(isPresented: $showingEmailSender) {
            EmailSender(
                proposal: proposal,
                toRecipients: ["alisami@e3tam.com"],
                completion: { result in
                    self.emailResult = result
                    
                    switch result {
                    case .success(let mailResult):
                        switch mailResult {
                        case .sent:
                            emailAlertMessage = "Email sent successfully!"
                        case .saved:
                            emailAlertMessage = "Email saved as draft."
                        case .cancelled:
                            // Don't show alert for cancelled
                            return
                        case .failed:
                            emailAlertMessage = "Failed to send email."
                        @unknown default:
                            emailAlertMessage = "Unknown result."
                        }
                    case .failure(let error):
                        emailAlertMessage = "Error: \(error.localizedDescription)"
                    }
                    
                    // Only show alert for non-cancelled results
                    if case .success(let mailResult) = result, mailResult != .cancelled {
                        showingEmailAlert = true
                    }
                }
            )
        }
        // TASK PRESENTATION SHEET
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(proposal: proposal)
                .environment(\.managedObjectContext, viewContext)
        }
        // COMMENT ALERT
        .alert("Add Comment", isPresented: $showingAddComment) {
            TextField("Comment", text: $commentText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !commentText.isEmpty {
                    addComment()
                }
            }
        } message: {
            Text("Enter a comment for this proposal")
        }
        // DELETE CONFIRMATION
        .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    deleteItem(item)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item from the proposal?")
        }
        // EMAIL RESULT ALERT
        .alert(isPresented: $showingEmailAlert) {
            Alert(
                title: Text("Email Result"),
                message: Text(emailAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - PDF Export Components
    
    // PDF Export Button
    var pdfExportButton: some View {
        Button(action: {
            exportToPdf()
        }) {
            HStack {
                Image(systemName: "doc.text")
                Text("Export PDF")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
        }
        .disabled(isGeneratingPdf)
        .overlay(
            isGeneratingPdf ?
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .padding(.trailing, 8)
            : nil
        )
    }
    
    // Email Export Button
    var emailExportButton: some View {
        Button(action: {
            if MFMailComposeViewController.canSendMail() {
                showingEmailSender = true
            } else {
                emailAlertMessage = "Your device is not configured to send emails. Please set up an email account in your mail app."
                showingEmailAlert = true
            }
        }) {
            HStack {
                Image(systemName: "envelope")
                Text("Send Email")
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
        }
    }
    
    // PDF Export function
    private func exportToPdf() {
        isGeneratingPdf = true
        
        // Generate PDF in background
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfData = PDFGenerator.generateProposalPDF(from: proposal) {
                let fileName = "Proposal_\(proposal.formattedNumber)_\(Date().timeIntervalSince1970).pdf"
                if let url = PDFGenerator.savePDF(pdfData, fileName: fileName) {
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        self.pdfUrl = url
                        self.isGeneratingPdf = false
                        self.showingPdfPreview = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isGeneratingPdf = false
                        // Handle error - could add alert here
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isGeneratingPdf = false
                    // Handle error - could add alert here
                }
            }
        }
    }
    
    // MARK: - Financial Summary Section


    struct EnhancedFinancialSummaryView: View {
        @ObservedObject var proposal: Proposal
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.colorScheme) var colorScheme
        
        // MARK: - Data Preparation
        
        // Revenue breakdown data
        private var revenueData: [DoughnutChartItem] {
            var data: [DoughnutChartItem] = []
            if proposal.subtotalProducts > 0 {
                data.append(DoughnutChartItem(name: "Products", value: proposal.subtotalProducts, color: .blue))
            }
            if proposal.subtotalEngineering > 0 {
                data.append(DoughnutChartItem(name: "Engineering", value: proposal.subtotalEngineering, color: .green))
            }
            if proposal.subtotalExpenses > 0 {
                data.append(DoughnutChartItem(name: "Expenses", value: proposal.subtotalExpenses, color: .orange))
            }
            if proposal.subtotalTaxes > 0 {
                data.append(DoughnutChartItem(name: "Taxes", value: proposal.subtotalTaxes, color: .red))
            }
            return data
        }
        
        // Product categories data
        private var productCategoryData: [BarChartItem] {
            var categoryTotals: [String: (total: Double, cost: Double)] = [:]
            for item in proposal.itemsArray {
                let category = item.product?.category ?? "Uncategorized"
                let amount = item.amount
                let cost = (item.product?.partnerPrice ?? 0) * item.quantity
                
                if let existing = categoryTotals[category] {
                    categoryTotals[category] = (
                        total: existing.total + amount,
                        cost: existing.cost + cost
                    )
                } else {
                    categoryTotals[category] = (total: amount, cost: cost)
                }
            }
            
            return categoryTotals.map { category, values in
                let profit = values.total - values.cost
                return BarChartItem(name: category, value: values.total, color: profit >= 0 ? .blue : .red)
            }.sorted { $0.value > $1.value }
        }
        
        // Profit by category data
        private var profitCategoryData: [BarChartItem] {
            var categoryTotals: [String: (total: Double, cost: Double)] = [:]
            for item in proposal.itemsArray {
                let category = item.product?.category ?? "Uncategorized"
                let amount = item.amount
                let cost = (item.product?.partnerPrice ?? 0) * item.quantity
                
                if let existing = categoryTotals[category] {
                    categoryTotals[category] = (
                        total: existing.total + amount,
                        cost: existing.cost + cost
                    )
                } else {
                    categoryTotals[category] = (total: amount, cost: cost)
                }
            }
            
            return categoryTotals.map { category, values in
                let profit = values.total - values.cost
                return BarChartItem(name: category, value: profit, color: profit >= 0 ? .green : .red)
            }.sorted { abs($0.value) > abs($1.value) }
        }
        
        // Cost breakdown data
        private var costBreakdownData: [DoughnutChartItem] {
            var costs: [DoughnutChartItem] = []
            
            // Product costs
            let productsCost = proposal.itemsArray.reduce(0.0) { total, item in
                total + ((item.product?.partnerPrice ?? 0) * item.quantity)
            }
            if productsCost > 0 {
                costs.append(DoughnutChartItem(name: "Products", value: productsCost, color: .blue))
            }
            
            // Engineering costs (if any are considered costs)
            // This assumes engineering is not a cost but revenue, adjust if needed
            
            // Expenses by category
            let travelExpenses = proposal.expensesArray.filter {
                ($0.desc?.lowercased().contains("travel") ?? false) ||
                ($0.desc?.lowercased().contains("flight") ?? false) ||
                ($0.desc?.lowercased().contains("hotel") ?? false)
            }.reduce(0.0) { $0 + $1.amount }
            
            let shippingExpenses = proposal.expensesArray.filter {
                ($0.desc?.lowercased().contains("shipping") ?? false) ||
                ($0.desc?.lowercased().contains("delivery") ?? false)
            }.reduce(0.0) { $0 + $1.amount }
            
            let otherExpenses = proposal.subtotalExpenses - travelExpenses - shippingExpenses
            
            if travelExpenses > 0 {
                costs.append(DoughnutChartItem(name: "Travel", value: travelExpenses, color: .orange))
            }
            if shippingExpenses > 0 {
                costs.append(DoughnutChartItem(name: "Shipping", value: shippingExpenses, color: .purple))
            }
            if otherExpenses > 0 {
                costs.append(DoughnutChartItem(name: "Other Expenses", value: otherExpenses, color: .gray))
            }
            
            return costs
        }
        
        // Discount analysis data
        private var discountAnalysisData: [BarChartItem] {
            var categoryDiscounts: [String: [Double]] = [:]
            
            for item in proposal.itemsArray {
                let category = item.product?.category ?? "Uncategorized"
                categoryDiscounts[category, default: []].append(item.discount)
            }
            
            return categoryDiscounts.map { category, discounts in
                let totalDiscount = discounts.reduce(0, +)
                let avgDiscount = discounts.isEmpty ? 0 : totalDiscount / Double(discounts.count)
                return BarChartItem(name: category, value: avgDiscount, color: .orange)
            }.sorted { $0.value > $1.value }
        }
        
        // Financial ratio data
        private var financialRatios: [FinancialRatioViewModel] {
            let profitMargin = proposal.profitMargin
            
            // Calculate return on investment
            let totalCost = proposal.totalCost
            let grossProfit = proposal.grossProfit
            let roi = totalCost > 0 ? (grossProfit / totalCost) * 100 : 0
            
            // Calculate average discount
            let totalDiscount = proposal.itemsArray.reduce(0.0) { $0 + $1.discount }
            let avgDiscount = proposal.itemsArray.isEmpty ? 0 : totalDiscount / Double(proposal.itemsArray.count)
            
            // Calculate engineering percentage
            let engineeringPercent = proposal.totalAmount > 0 ?
                                  (proposal.subtotalEngineering / proposal.totalAmount) * 100 : 0
            
            return [
                FinancialRatioViewModel(
                    title: "Profit Margin",
                    value: profitMargin,
                    targetValue: 35.0,
                    formatter: Formatters.formatPercent,
                    description: "Revenue remaining as profit after expenses",
                    iconName: "chart.pie.fill"
                ),
                FinancialRatioViewModel(
                    title: "Return on Investment",
                    value: roi,
                    targetValue: 40.0,
                    formatter: Formatters.formatPercent,
                    description: "Profit relative to costs",
                    iconName: "arrow.up.right"
                ),
                FinancialRatioViewModel(
                    title: "Avg. Discount",
                    value: avgDiscount,
                    targetValue: 15.0,
                    formatter: Formatters.formatPercent,
                    description: "Average discount offered",
                    iconName: "tag.fill",
                    valueIncreasingIsGood: false
                ),
                FinancialRatioViewModel(
                    title: "Engineering %",
                    value: engineeringPercent,
                    targetValue: 20.0,
                    formatter: Formatters.formatPercent,
                    description: "Engineering as % of revenue",
                    iconName: "wrench.and.screwdriver.fill"
                )
            ]
        }
        
        // Financial performance comparison data
        private var performanceComparisonData: (actual: [String: Double], target: [String: Double], descriptions: [String: String]) {
            // For this example, we're using static targets
            // In a real app, these would come from business targets
            
            let actual = [
                "Revenue": proposal.totalAmount,
                "Profit": proposal.grossProfit,
                "Margin": proposal.profitMargin
            ]
            
            // Example targets (could be customized per proposal)
            let target = [
                "Revenue": 25000.0, // Example target
                "Profit": 8750.0,   // Example target (35% margin)
                "Margin": 35.0      // Example target percentage
            ]
            
            let descriptions = [
                "Revenue": "Total revenue from all sources",
                "Profit": "Gross profit after all costs",
                "Margin": "Percentage of revenue retained as profit"
            ]
            
            return (actual, target, descriptions)
        }
        
        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header Summary
                    headerSummarySection
                    
                    // MARK: - Revenue Breakdown
                    revenueBreakdownSection
                    
                    // MARK: - Cost Structure
                    costBreakdownSection
                    
                    // MARK: - Product Categories
                    productCategoriesSection
                    
                    // MARK: - Profit Analysis
                    profitAnalysisSection
                    
                    // MARK: - Financial Ratios
                    FinancialRatioGrid(ratios: financialRatios)
                    
                    // MARK: - Performance Comparison
                    let compData = performanceComparisonData
                    FinancialComparisonSection(
                        actualValues: compData.actual,
                        targetValues: compData.target,
                        descriptions: compData.descriptions
                    )
                    
                    // MARK: - Discount Analysis
                    discountAnalysisSection
                    
                    // MARK: - Engineering Analysis (if applicable)
                    if !proposal.engineeringArray.isEmpty {
                        engineeringAnalysisSection
                    }
                    
                    // MARK: - Tax Breakdown (if applicable)
                    if !proposal.taxesArray.isEmpty {
                        taxBreakdownSection
                    }
                }
                .padding()
            }
            .navigationTitle("Financial Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        
        // MARK: - Section Views
        
        private var headerSummarySection: some View {
            VStack(spacing: 16) {
                Text("Financial Summary")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Key metrics cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(
                        title: "Total Revenue",
                        value: Formatters.formatEuro(proposal.totalAmount),
                        subtitle: "All revenue sources",
                        icon: "dollarsign.circle.fill",
                        trend: "",
                        trendUp: true
                    )
                    
                    MetricCard(
                        title: "Total Cost",
                        value: Formatters.formatEuro(proposal.totalCost),
                        subtitle: "Products & expenses",
                        icon: "cart.fill",
                        trend: "",
                        trendUp: false
                    )
                    
                    MetricCard(
                        title: "Gross Profit",
                        value: Formatters.formatEuro(proposal.grossProfit),
                        subtitle: "Revenue - Costs",
                        icon: "chart.line.uptrend.xyaxis",
                        trend: "",
                        trendUp: proposal.grossProfit > 0
                    )
                    
                    MetricCard(
                        title: "Profit Margin",
                        value: Formatters.formatPercent(proposal.profitMargin),
                        subtitle: "Profit ÷ Revenue",
                        icon: "percent",
                        trend: "",
                        trendUp: proposal.profitMargin > 30
                    )
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var revenueBreakdownSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Revenue Breakdown")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(revenueData, id: \.id) { item in
                            SectorMark(
                                angle: .value("Value", item.value),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(item.color)
                            .cornerRadius(5)
                            .annotation(position: .overlay) {
                                Text(item.value > (proposal.totalAmount * 0.1) ?
                                     String(format: "%.0f%%", (item.value/proposal.totalAmount)*100) : "")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                    .frame(height: 240)
                } else {
                    // Fallback for iOS 15
                    DoughnutChart(items: revenueData, innerRadiusFraction: 0.6)
                        .frame(height: 240)
                    
                    ChartLegend(items: revenueData, columns: 2)
                        .padding(.top, 8)
                }
                
                // Revenue details
                VStack(spacing: 8) {
                    ForEach(revenueData, id: \.id) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            Text(item.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(Formatters.formatPercent((item.value / proposal.totalAmount) * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(Formatters.formatEuro(item.value))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total Revenue")
                            .font(.headline)
                        Spacer()
                        Text(Formatters.formatEuro(proposal.totalAmount))
                            .font(.headline)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var costBreakdownSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cost Structure")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if costBreakdownData.isEmpty {
                    Text("No cost data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(costBreakdownData, id: \.id) { item in
                                SectorMark(
                                    angle: .value("Value", item.value),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(5)
                                .annotation(position: .overlay) {
                                    Text(item.value > (proposal.totalCost * 0.1) ?
                                         String(format: "%.0f%%", (item.value/proposal.totalCost)*100) : "")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                        .frame(height: 200)
                    } else {
                        // Fallback for iOS 15
                        DoughnutChart(items: costBreakdownData, innerRadiusFraction: 0.6)
                            .frame(height: 200)
                        
                        ChartLegend(items: costBreakdownData, columns: 2)
                            .padding(.top, 8)
                    }
                    
                    // Cost details
                    VStack(spacing: 8) {
                        ForEach(costBreakdownData, id: \.id) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(Formatters.formatPercent((item.value / proposal.totalCost) * 100))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(Formatters.formatEuro(item.value))
                                    .font(.subheadline)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Cost")
                                .font(.headline)
                            Spacer()
                            Text(Formatters.formatEuro(proposal.totalCost))
                                .font(.headline)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var productCategoriesSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Product Category Performance")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if productCategoryData.isEmpty {
                    Text("No product data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(productCategoryData, id: \.id) { item in
                                BarMark(
                                    x: .value("Revenue", item.value),
                                    y: .value("Category", item.name)
                                )
                                .foregroundStyle(item.color.gradient)
                                .annotation(position: .trailing) {
                                    Text(Formatters.formatEuro(item.value))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(height: CGFloat(min(productCategoryData.count * 50, 250)))
                        .padding(.vertical)
                    } else {
                        // Fallback for iOS 15
                        HorizontalBarChart(
                            items: productCategoryData,
                            valueFormatter: Formatters.formatEuro
                        )
                        .frame(height: CGFloat(min(productCategoryData.count * 30 + 20, 200)))
                    }
                    
                    Divider()
                    
                    Text("Category Distribution")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    // Calculate the percentage distribution
                    let totalRevenue = productCategoryData.reduce(0.0) { $0 + $1.value }
                    
                    LabeledBarChart(
                        items: productCategoryData.map { item in
                            BarChartItem(
                                name: item.name,
                                value: (item.value / totalRevenue) * 100,
                                color: item.color
                            )
                        },
                        valueFormatter: Formatters.formatPercent
                    )
                    .frame(height: CGFloat(min(productCategoryData.count * 35 + 20, 200)))
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var profitAnalysisSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Profit Analysis by Category")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if profitCategoryData.isEmpty {
                    Text("No profit data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(profitCategoryData, id: \.id) { item in
                                BarMark(
                                    x: .value("Profit", item.value),
                                    y: .value("Category", item.name)
                                )
                                .foregroundStyle(item.color.gradient)
                                .annotation(position: .trailing) {
                                    Text(Formatters.formatEuro(item.value))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(height: CGFloat(min(profitCategoryData.count * 50, 250)))
                        .padding(.vertical)
                    } else {
                        // Fallback for iOS 15
                        PositiveNegativeBarChart(
                            items: profitCategoryData,
                            valueFormatter: Formatters.formatEuro
                        )
                        .frame(height: CGFloat(min(profitCategoryData.count * 30 + 20, 200)))
                    }
                    
                    Divider()
                    
                    // Profit margin by category details
                    Text("Profit Margins by Category")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        ForEach(profitCategoryData, id: \.id) { item in
                            let categoryTotals = proposal.itemsArray
                                .filter { ($0.product?.category ?? "Uncategorized") == item.name }
                                .reduce((total: 0.0, cost: 0.0)) { result, item in
                                    let cost = (item.product?.partnerPrice ?? 0) * item.quantity
                                    return (result.total + item.amount, result.cost + cost)
                                }
                            
                            let margin = categoryTotals.total > 0 ?
                                       ((categoryTotals.total - categoryTotals.cost) / categoryTotals.total) * 100 : 0
                            
                            HStack {
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(Formatters.formatPercent(margin))
                                    .font(.subheadline)
                                    .foregroundColor(margin > 20 ? .green : (margin > 10 ? .orange : .red))
                                Text(Formatters.formatEuro(item.value))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(item.value >= 0 ? .green : .red)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Profit")
                                .font(.headline)
                            Spacer()
                            Text(Formatters.formatEuro(proposal.grossProfit))
                                .font(.headline)
                                .foregroundColor(proposal.grossProfit >= 0 ? .green : .red)
                        }
                        
                        HStack {
                            Text("Overall Margin")
                                .font(.headline)
                            Spacer()
                            Text(Formatters.formatPercent(proposal.profitMargin))
                                .font(.headline)
                                .foregroundColor(proposal.profitMargin > 30 ? .green :
                                               (proposal.profitMargin > 15 ? .blue : .red))
                        }
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var discountAnalysisSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Discount Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if discountAnalysisData.isEmpty {
                    Text("No discount data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(discountAnalysisData, id: \.id) { item in
                                BarMark(
                                    x: .value("Discount", item.value),
                                    y: .value("Category", item.name)
                                )
                                .foregroundStyle(item.color.gradient)
                                .annotation(position: .trailing) {
                                    Text(Formatters.formatPercent(item.value))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(position: .bottom) { value in
                                if let percentage = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(Formatters.formatPercent(percentage))
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .frame(height: CGFloat(min(discountAnalysisData.count * 50, 250)))
                        .padding(.vertical)
                    } else {
                        // Fallback for iOS 15
                        HorizontalBarChart(
                            items: discountAnalysisData,
                            valueFormatter: Formatters.formatPercent
                        )
                        .frame(height: CGFloat(min(discountAnalysisData.count * 30 + 20, 200)))
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        ForEach(discountAnalysisData, id: \.id) { item in
                            let itemsCount = proposal.itemsArray.filter {
                                ($0.product?.category ?? "Uncategorized") == item.name
                            }.count
                            
                            HStack {
                                Text(item.name)
                                    .font(.subheadline)
                                    
                                Spacer()
                                
                                Text("\(itemsCount) item\(itemsCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    
                                Text(Formatters.formatPercent(item.value))
                                    .font(.headline)
                                    .foregroundColor(item.value > 20 ? .red : (item.value > 10 ? .orange : .green))
                            }
                        }
                        
                        if !proposal.itemsArray.isEmpty {
                            Divider()
                            
                            let totalDiscount = proposal.itemsArray.reduce(0.0) { $0 + $1.discount }
                            let avgDiscount = totalDiscount / Double(proposal.itemsArray.count)
                            
                            HStack {
                                Text("Average Discount")
                                    .font(.headline)
                                Spacer()
                                Text(Formatters.formatPercent(avgDiscount))
                                    .font(.headline)
                                    .foregroundColor(avgDiscount > 20 ? .red : (avgDiscount > 10 ? .orange : .green))
                            }
                        }
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var engineeringAnalysisSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Engineering Services")
                    .font(.title2)
                    .fontWeight(.bold)
                
                let totalDays = proposal.engineeringArray.reduce(0.0) { $0 + $1.days }
                let avgRate = totalDays > 0 ? proposal.subtotalEngineering / totalDays : 0
                
                HStack {
                    MetricCard(
                        title: "Total Days",
                        value: String(format: "%.1f", totalDays),
                        subtitle: "Engineering time",
                        icon: "clock.fill",
                        trend: "",
                        trendUp: true
                    )
                    
                    MetricCard(
                        title: "Avg Daily Rate",
                        value: Formatters.formatEuro(avgRate),
                        subtitle: "Per engineer day",
                        icon: "eurosign.circle.fill",
                        trend: "",
                        trendUp: true
                    )
                }
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(proposal.engineeringArray, id: \.id) { engineering in
                            BarMark(
                                x: .value("Amount", engineering.amount),
                                y: .value("Description", engineering.desc ?? "Engineering")
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                    }
                    .frame(height: CGFloat(min(proposal.engineeringArray.count * 40 + 30, 250)))
                    .padding(.vertical)
                } else {
                    // Fallback for iOS 15
                    VStack(spacing: 10) {
                        ForEach(proposal.engineeringArray, id: \.id) { engineering in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(engineering.desc ?? "Engineering Service")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 20)
                                            .cornerRadius(4)
                                        
                                        let maxAmount = proposal.engineeringArray.map { $0.amount }.max() ?? 1.0
                                        let width = geo.size.width * (engineering.amount / maxAmount)
                                        
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: width, height: 20)
                                            .cornerRadius(4)
                                        
                                        HStack {
                                            Spacer()
                                            Text(Formatters.formatEuro(engineering.amount))
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.trailing, 8)
                                        }
                                    }
                                }
                                .frame(height: 20)
                                
                                Text("\(String(format: "%.1f", engineering.days)) days @ \(Formatters.formatEuro(engineering.rate))/day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(height: CGFloat(min(proposal.engineeringArray.count * 60 + 20, 250)))
                }
                
                Divider()
                
                HStack {
                    Text("Total Engineering")
                        .font(.headline)
                    Spacer()
                    Text(Formatters.formatEuro(proposal.subtotalEngineering))
                        .font(.headline)
                }
                
                // Engineering as percentage of total
                let engineeringPercentage = proposal.totalAmount > 0 ?
                                         (proposal.subtotalEngineering / proposal.totalAmount) * 100 : 0
                
                HStack {
                    Text("% of Total Revenue")
                        .font(.subheadline)
                    Spacer()
                    Text(Formatters.formatPercent(engineeringPercentage))
                        .font(.subheadline)
                        .foregroundColor(engineeringPercentage > 30 ? .green : .blue)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
        
        private var taxBreakdownSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tax Breakdown")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Calculate the tax base
                let taxBase = proposal.subtotalProducts + proposal.subtotalEngineering + proposal.subtotalExpenses
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(proposal.taxesArray, id: \.id) { tax in
                            BarMark(
                                x: .value("Amount", tax.amount),
                                y: .value("Name", tax.name ?? "Tax")
                            )
                            .foregroundStyle(Color.red.gradient)
                        }
                    }
                    .frame(height: CGFloat(min(proposal.taxesArray.count * 40 + 30, 200)))
                    .padding(.vertical)
                } else {
                    // Fallback for iOS 15
                    VStack(spacing: 10) {
                        ForEach(proposal.taxesArray, id: \.id) { tax in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tax.name ?? "Tax")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 20)
                                            .cornerRadius(4)
                                        
                                        let maxAmount = proposal.taxesArray.map { $0.amount }.max() ?? 1.0
                                        let width = geo.size.width * (tax.amount / maxAmount)
                                        
                                        Rectangle()
                                            .fill(Color.red)
                                            .frame(width: width, height: 20)
                                            .cornerRadius(4)
                                        
                                        HStack {
                                            Spacer()
                                            Text(Formatters.formatEuro(tax.amount))
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.trailing, 8)
                                        }
                                    }
                                }
                                .frame(height: 20)
                                
                                Text("Rate: \(Formatters.formatPercent(tax.rate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(height: CGFloat(min(proposal.taxesArray.count * 60 + 20, 200)))
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tax Base")
                            .font(.subheadline)
                        Spacer()
                        Text(Formatters.formatEuro(taxBase))
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Total Taxes")
                            .font(.headline)
                        Spacer()
                        Text(Formatters.formatEuro(proposal.subtotalTaxes))
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Effective Tax Rate")
                            .font(.subheadline)
                        Spacer()
                        Text(Formatters.formatPercent(taxBase > 0 ? (proposal.subtotalTaxes / taxBase) * 100 : 0))
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(15)
        }
    }

    // Preview provider
    struct EnhancedFinancialSummaryView_Previews: PreviewProvider {
        static var previews: some View {
            let context = PersistenceController.preview.container.viewContext
            let fetchRequest: NSFetchRequest<Proposal> = Proposal.fetchRequest()
            let proposals = try? context.fetch(fetchRequest)
            let proposal = proposals?.first ?? Proposal(context: context)
            
            NavigationView {
                EnhancedFinancialSummaryView(proposal: proposal)
            }
            .environment(\.managedObjectContext, context)
        }
    }
    
    // MARK: - Task Summary Section
    private var taskSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tasks")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !proposal.tasksArray.isEmpty {
                    Text("(\(proposal.tasksArray.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddTask = true
                }) {
                    Label("Add", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            TaskSummaryView(proposal: proposal)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Activity Summary Section
    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: { showingAddComment = true }) {
                        Label("Add Comment", systemImage: "text.bubble")
                            .foregroundColor(.blue)
                    }
                    
                    NavigationLink(destination: ActivityDetailView(proposal: proposal)) {
                        Label("View All", systemImage: "list.bullet")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ActivityLogView(proposal: proposal)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Notes Section
    private func notesSection(notes: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                
                Text(notes)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Components
    
    private struct SummaryRow: View {
        let title: String
        let value: Double
        var titleColor: Color = .white
        var valueColor: Color = .white
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(titleColor)
                Spacer()
                Text(String(format: "%.2f", value))
                    .foregroundColor(valueColor)
            }
            .padding(.vertical, 3)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculatePartnerCost() -> Double {
        var totalCost = 0.0
        
        // Sum partner cost for all products
        for item in proposal.itemsArray {
            let partnerPrice = item.product?.partnerPrice ?? 0
            totalCost += partnerPrice * item.quantity
        }
        
        // Add expenses
        totalCost += proposal.subtotalExpenses
        
        return totalCost
    }
    
    // MARK: - CRUD Operations
    
    private func deleteItem(_ item: ProposalItem) {
        withAnimation {
            // Log activity before deleting
            if let product = item.product {
                ActivityLogger.logItemRemoved(
                    proposal: proposal,
                    context: viewContext,
                    itemType: "Product",
                    itemName: product.name ?? "Unknown"
                )
            }
            
            viewContext.delete(item)
            
            do {
                try viewContext.save()
                updateProposalTotal()
                refreshId = UUID() // Force refresh
            } catch {
                let nsError = error as NSError
                print("Error deleting item: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteEngineering(_ engineering: Engineering) {
        withAnimation {
            // Log engineering removal
            ActivityLogger.logItemRemoved(
                proposal: proposal,
                context: viewContext,
                itemType: "Engineering",
                itemName: engineering.desc ?? "Engineering entry"
            )
            
            viewContext.delete(engineering)
            
            do {
                try viewContext.save()
                updateProposalTotal()
            } catch {
                let nsError = error as NSError
                print("Error deleting engineering: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            // Log expense removal
            ActivityLogger.logItemRemoved(
                proposal: proposal,
                context: viewContext,
                itemType: "Expense",
                itemName: expense.desc ?? "Expense entry"
            )
            
            viewContext.delete(expense)
            
            do {
                try viewContext.save()
                updateProposalTotal()
            } catch {
                let nsError = error as NSError
                print("Error deleting expense: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteTax(_ tax: CustomTax) {
        withAnimation {
            // Log tax removal
            ActivityLogger.logItemRemoved(
                proposal: proposal,
                context: viewContext,
                itemType: "Tax",
                itemName: tax.name ?? "Custom tax"
            )
            
            viewContext.delete(tax)
            
            do {
                try viewContext.save()
                updateProposalTotal()
            } catch {
                let nsError = error as NSError
                print("Error deleting tax: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Function to update the proposal total after changes
    private func updateProposalTotal() {
        // Calculate total amount from all components
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
    
    private func addComment() {
        ActivityLogger.logCommentAdded(
            proposal: proposal,
            context: viewContext,
            comment: commentText
        )
        
        commentText = ""
    }
}
// MARK: - PDF Preview Components

// PDF Preview View
struct PDFPreviewView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            PDFKitView(url: url)
                .navigationTitle("Proposal PDF")
                .navigationBarItems(
                    leading: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                )
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: [url])
                }
        }
    }
}

// PDFKit wrapper
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Nothing to update
    }
}

// ShareSheet view
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

// MARK: - Enhanced Proposal Header Section
struct EnhancedProposalHeaderSection: View {
    let proposal: Proposal
    let onEditTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Customer Information Section
            if let customer = proposal.customer {
                VStack(alignment: .leading, spacing: 16) {
                    // Customer header
                    HStack {
                        Text("Customer Information")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Customer details card
                    VStack(alignment: .leading, spacing: 12) {
                        // Company name
                        HStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text(customer.formattedName)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        // Contact person
                        if let contactName = customer.contactName, !contactName.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "person")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                                    .frame(width: 30)
                                
                                Text(contactName)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Email
                        if let email = customer.email, !email.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Phone
                        if let phone = customer.phone, !phone.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .font(.system(size: 20))
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Address
                        if let address = customer.address, !address.isEmpty {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "location")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            
            // Proposal Information Section
            VStack(alignment: .leading, spacing: 16) {
                // Proposal header with edit button
                HStack {
                    Text("Proposal Information")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onEditTapped) {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Proposal number
                    HStack {
                        Text("Proposal #")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(proposal.formattedNumber)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // Creation date
                    HStack {
                        Text("Date")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(proposal.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    // Status
                    HStack {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(proposal.formattedStatus)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor(for: proposal.formattedStatus))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    
                    // Total amount
                    HStack {
                        Text("Total Amount")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(proposal.formattedTotal)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color.black)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft": return .gray
        case "Pending": return .orange
        case "Sent": return .blue
        case "Won": return .green
        case "Lost": return .red
        case "Expired": return .purple
        default: return .gray
        }
    }
}
