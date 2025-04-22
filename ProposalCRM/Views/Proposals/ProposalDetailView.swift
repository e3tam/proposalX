// ProposalDetailView.swift
// Final updated version with proper Payment Terms integration

import SwiftUI
import CoreData
import PDFKit
import UIKit
import MessageUI
import PencilKit

struct ProposalDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var proposal: Proposal
    @Environment(\.colorScheme) private var colorScheme
    
    // Reference the navigation state
    @ObservedObject private var navigationState = NavigationState.shared
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Pass colorScheme to header section
                    EnhancedProposalHeaderSection(
                        proposal: proposal,
                        onEditTapped: { showingEditProposal = true }
                    )
                    
                    // Content sections with proper spacing
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
                        
                        // Payment Terms Section - properly integrated
                        PaymentTermsSection(proposal: proposal)
                            .environment(\.colorScheme, colorScheme)
                        
                        // Attachments Section
                        AttachmentsSection(proposal: proposal)
                            .environment(\.colorScheme, colorScheme)
                        
                        // Drawing Notes Section
                        DrawingNotesSection(proposal: proposal)
                            .environment(\.colorScheme, colorScheme)
                        
                        // Financial Summary Section
                        FinancialSummarySection(proposal: proposal) {
                            showingFinancialDetails = true
                        }
                        .environment(\.colorScheme, colorScheme)
                        
                        // Tasks and Activity sections
                        TaskSummarySection(proposal: proposal)
                            .environment(\.colorScheme, colorScheme)
                        
                        ActivitySummarySection(proposal: proposal)
                            .environment(\.colorScheme, colorScheme)
                        
                        // Notes section
                        if let notes = proposal.notes, !notes.isEmpty {
                            NotesSection(notes: notes)
                                .environment(\.colorScheme, colorScheme)
                        }
                        
                        // Add spacing at bottom for floating button
                        Spacer().frame(height: 80)
                    }
                    .padding(.vertical, 20)
                }
            }
            
            // Floating export buttons
            ExportButtonGroup(proposal: proposal)
                .environment(\.colorScheme, colorScheme)
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .onAppear {
            // Hide the sidebar when this view appears
            navigationState.showSidebar = false
        }
        .onDisappear {
            // Restore sidebar when leaving this view
            navigationState.showSidebar = true
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
            
            // Force complete view refresh
            if didSaveItemChanges {
                // Refresh the context to ensure all relationships are fully loaded
                viewContext.refreshAllObjects()
                
                // Update the UI
                refreshId = UUID()
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
                        
                        // Force view refresh
                        DispatchQueue.main.async {
                            // Refresh all objects to ensure latest data
                            viewContext.refreshAllObjects()
                            refreshId = UUID()
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
            
            // Update dependent calculations - direct method calls
            // First update custom taxes
            recalculateCustomTaxes()
            
            // Then update payment terms
            recalculatePaymentTerms()
            
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
        // Get payment terms as an array
        guard let termSet = proposal.paymentTerms as? Set<PaymentTerm> else { return }
        let terms = Array(termSet)
        
        // Update amounts for all terms
        for term in terms {
            term.amount = proposal.totalAmount * (term.percentage / 100)
        }
        
        // Save changes if needed
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
}

