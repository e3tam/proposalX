import SwiftUI
import CoreData

struct ProposalDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState
    
    // The proposal to display - using @ObservedObject instead of ID
    @ObservedObject var proposal: Proposal
    
    // Simplified loading state
    @State private var isLoading = false
    @State private var loadingError: String? = nil
    
    // State variables for showing different sheets
    @State private var showingItemSelection = false
    @State private var showingEngineeringForm = false
    @State private var showingExpensesForm = false
    @State private var showingCustomTaxForm = false
    @State private var showingEditProposal = false
    @State private var showingFinancialDetails = false
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: ProposalItem?
    
    // State variables for product item editing
    @State private var itemToEdit: ProposalItem?
    @State private var showEditItemSheet = false
    @State private var didSaveItemChanges = false
    
    // State variables for engineering editing
    @State private var engineeringToEdit: Engineering?
    @State private var showEditEngineeringSheet = false
    
    // State variables for expense editing
    @State private var expenseToEdit: Expense?
    @State private var showEditExpenseSheet = false
    
    // State variables for custom tax editing
    @State private var taxToEdit: CustomTax?
    @State private var showEditTaxSheet = false
    
    // State for refresh triggers
    @State private var refreshId = UUID()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                loadingView
            } else if let error = loadingError {
                errorView(message: error)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header section
                        EnhancedProposalHeaderSection(
                            proposal: proposal,
                            onEditTapped: { showingEditProposal = true }
                        )
                        
                        // Content sections
                        VStack(alignment: .leading, spacing: 20) {
                            // Products section
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
                            .id(refreshId)
                            
                            // Engineering section
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
                            
                            // Expenses section
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
                            
                            // Custom taxes section
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
                            
                            // Payment Terms Section
                            PaymentTermsSection(proposal: proposal)
                            
                            // Financial Summary Section
                            FinancialSummarySection(proposal: proposal) {
                                showingFinancialDetails = true
                            }
                            
                            // Notes section if available
                            if let notes = proposal.notes, !notes.isEmpty {
                                NotesSection(notes: notes)
                            }
                            
                            // Add spacing at bottom for floating button
                            Spacer().frame(height: 80)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .refreshable {
                    refreshProposal()
                }
                
                // Floating export buttons
                ExportButtonGroup(proposal: proposal)
            }
        }
        .navigationTitle("Proposal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshProposal()
        }
        
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
            
            // Force view refresh
            if didSaveItemChanges {
                refreshProposal()
                didSaveItemChanges = false
            }
        }) {
            if let item = itemToEdit {
                ProposalItemEditorWrapper(
                    item: item,
                    didSave: $didSaveItemChanges,
                    onSave: {
                        // Save the context explicitly to ensure all changes are persisted
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error saving context: \(error)")
                        }
                    }
                )
                .environment(\.managedObjectContext, viewContext)
            }
        }
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
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading proposal details...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
            Text("Please wait...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Add a cancel button after 5 seconds
            if isLoading {
                Button("Cancel Loading") {
                    isLoading = false
                }
                .padding(.top, 20)
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Error Loading Proposal")
                .font(.title)
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Try Again") {
                refreshProposal()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // MARK: - Data Operations
    
    private func refreshProposal() {
        isLoading = true
        loadingError = nil
        
        // Use a short timeout to ensure the UI doesn't hang
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // Refresh the proposal object
                viewContext.refresh(proposal, mergeChanges: true)
                
                // Access key properties to ensure they're loaded
                _ = proposal.number
                _ = proposal.customer?.name
                _ = proposal.itemsArray
                _ = proposal.engineeringArray
                _ = proposal.expensesArray
                _ = proposal.taxesArray
                
                // Update UI
                refreshId = UUID()
                isLoading = false
            } catch {
                print("Error refreshing proposal: \(error)")
                loadingError = "There was a problem loading the proposal: \(error.localizedDescription)"
                isLoading = false
            }
        }
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
            
            // Update dependent calculations
            recalculateCustomTaxes()
            recalculatePaymentTerms()
            
            // Force refresh
            refreshId = UUID()
        } catch {
            let nsError = error as NSError
            print("Error updating proposal total: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func recalculateCustomTaxes() {
        // Calculate the tax base - products marked with applyCustomTax
        let taxableItems = proposal.itemsArray.filter { $0.applyCustomTax }
        let taxBase = taxableItems.reduce(0.0) { total, item in
            if let product = item.product {
                return total + (item.quantity * product.partnerPrice)
            }
            return total
        }
        
        // Update all taxes
        let taxes = proposal.taxesArray
        for tax in taxes {
            let amount = taxBase * (tax.rate / 100)
            tax.amount = amount
        }
        
        // Save changes if needed
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }

    private func recalculatePaymentTerms() {
        // Get payment terms if available
        guard let termSet = proposal.paymentTerms as? Set<PaymentTerm>, !termSet.isEmpty else { return }
        
        // Update amounts for all terms
        for term in termSet {
            term.amount = proposal.totalAmount * (term.percentage / 100)
        }
        
        // Save changes if needed
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
}

// Helper view for displaying proposal notes
struct NotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(notes)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}
