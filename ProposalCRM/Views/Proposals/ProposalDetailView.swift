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
            FinancialSummaryDetailView(proposal: proposal)
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
    private var financialSummarySection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 15) {
                // Progress bar at the top
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(.gray.opacity(0.3))
                    .overlay(
                        GeometryReader { geometry in
                            Rectangle()
                                .frame(width: geometry.size.width * 0.65)
                                .foregroundColor(.white)
                        }
                    )
                    .cornerRadius(2)
                    .padding(.bottom, 20)
                
                HStack {
                    Text("Financial Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showingFinancialDetails = true }) {
                        Label("Details", systemImage: "chart.bar")
                            .foregroundColor(.blue)
                    }
                }
                
                Group {
                    SummaryRow(title: "Products Subtotal", value: proposal.subtotalProducts)
                    SummaryRow(title: "Engineering Subtotal", value: proposal.subtotalEngineering)
                    SummaryRow(title: "Expenses Subtotal", value: proposal.subtotalExpenses)
                    SummaryRow(title: "Taxes", value: proposal.subtotalTaxes)
                    
                    // Total with more prominent styling
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.2f", proposal.totalAmount))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 5)
                    
                    Divider().background(Color.gray.opacity(0.5))
                    
                    // Partner Cost Section
                    let partnerCost = calculatePartnerCost()
                    SummaryRow(title: "Partner Cost", value: partnerCost, titleColor: .gray, valueColor: .gray)
                    
                    // Total Profit
                    let totalProfit = proposal.totalAmount - partnerCost
                    HStack {
                        Text("Total Profit")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.2f", totalProfit))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(totalProfit >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 5)
                    
                    // Profit Margin
                    HStack {
                        Text("Profit Margin")
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1f%%", proposal.totalAmount > 0 ? (totalProfit / proposal.totalAmount) * 100 : 0))
                            .fontWeight(.semibold)
                            .foregroundColor(totalProfit >= 0 ? .green : .red)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
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
