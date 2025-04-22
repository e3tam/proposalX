// ProposalDetailView.swift
// Main view for displaying proposal details

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
                        FinancialSummarySection(proposal: proposal) {
                            showingFinancialDetails = true
                        }
                        
                        // TASK SECTION
                        TaskSummarySection(proposal: proposal)
                        
                        // ACTIVITY SECTION
                        ActivitySummarySection(proposal: proposal)
                        
                        // NOTES SECTION
                        if let notes = proposal.notes, !notes.isEmpty {
                            NotesSection(notes: notes)
                        }
                        
                        // Add spacing at bottom for floating button
                        Spacer().frame(height: 80)
                    }
                    .padding(.vertical, 20)
                }
            }
            
            // Floating export buttons
            ExportButtonGroup(proposal: proposal)
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
        } catch {
            let nsError = error as NSError
            print("Error updating proposal total: \(nsError), \(nsError.userInfo)")
        }
    }
}

// Lightweight previews to avoid build slowdowns
struct ProposalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview placeholder")
    }
}
