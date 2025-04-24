// ProposalCRM/Views/Proposals/CreateProposalView.swift

import SwiftUI
import CoreData

struct CreateProposalView: View {
    // The customer object passed to this view. Should be a Core Data Customer entity.
    let customer: Customer // Keep the expected type

    // State variables for the form fields
    @State private var proposalName: String = ""
    // Add other relevant fields for a proposal if necessary
    // @State private var proposalDetails: String = ""

    // Environment variables for Core Data context and dismissing the view
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // Initialize the view, setting an initial proposal name based on the customer
    init(customer: Customer) {
        self.customer = customer
        // Use the customer's name for a default proposal title if the name exists
        // Initialize the state variable correctly using _variable = State(...)
        _proposalName = State(initialValue: "Proposal for \(customer.name ?? "Customer")")
        print("CreateProposalView initialized for customer: \(customer.name ?? "Unknown") (ID: \(customer.objectID))")
    }

    var body: some View {
        // Use NavigationView to provide a title bar and toolbar buttons
        NavigationView {
            Form {
                // Section for the proposal name
                Section(header: Text("Proposal Details")) {
                    TextField("Proposal Name", text: $proposalName)
                    // Add more fields as needed, e.g., TextEditor for details
                    // TextEditor(text: $proposalDetails)
                    //     .frame(height: 100)
                }

                // Section displaying the associated customer's name
                Section("Customer") {
                    // Safely access customer name - this part is likely okay.
                    Text(customer.name ?? "Unknown Customer")
                        .foregroundColor(.secondary) // Style as secondary info
                }

                // Potentially add sections for initial items, terms, etc.
            }
            .navigationTitle("New Proposal") // Set the title of the view
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Create Proposal cancelled.")
                        dismiss() // Dismiss the sheet
                    }
                }
                // Create button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        print("Create button tapped. Attempting to create proposal...")
                        createProposal() // Call the function to create the proposal
                    }
                    // Disable the Create button if the proposal name is empty after trimming whitespace
                    .disabled(proposalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // Log when the view appears
            .onAppear {
                print("CreateProposalView appeared for customer: \(customer.name ?? "Unknown")")
                // Double-check the type on appear for debugging
                print("On Appear - Customer type: \(type(of: customer))")
            }
            // Log when the view disappears
            .onDisappear {
                 print("CreateProposalView disappeared.")
            }
        }
        // It's generally better practice to handle potential errors within the save block
        // rather than catching NavigationView errors, unless specific navigation errors are expected.
    }

    // Function to handle the creation of the new proposal object
    private func createProposal() {
        print("Executing createProposal function...")

        // --- FIX STARTS HERE ---
        // **Crucial Check:** Verify that the `customer` object passed to this view
        // is indeed a `Customer` managed object before trying to access Core Data properties.
        // The error "-[__NSCFConstantString managedObjectContext]" strongly suggests that
        // sometimes a String or another incorrect type might be present in the `customer` variable.
        guard let validCustomer = customer as? Customer else {
             // Log detailed error information if the object is not a Customer
             print("CRITICAL ERROR in createProposal: The 'customer' object is not of type 'Customer'.")
             print("Actual type: \(type(of: customer))")
             print("Actual value: \(customer)")
             // TODO: Implement user-facing alert about the internal error
             // alertUserAboutInternalError()
             return // Stop execution to prevent crash
        }
        // If the guard passes, we know validCustomer is a Customer object.
        print("Customer object confirmed as type Customer: \(validCustomer.name ?? "Unknown")")
        // --- FIX ENDS HERE ---


        // Ensure the validated customer object has a managed object context.
        // This should generally be true if it's a valid managed object fetched correctly,
        // but it's a good safety check.
        guard let customerContext = validCustomer.managedObjectContext else {
            print("Error: Customer \(validCustomer.name ?? "Unknown") (ID: \(validCustomer.objectID)) does not have a managed object context. This might indicate it was deleted or is not properly registered in a context.")
            // TODO: Implement user-facing alert
            return
        }

        // Optional but recommended: Check if the customer's context matches the view's context.
        // Mismatches can cause Core Data issues ("Illegal attempt to establish a relationship '...' between objects in different contexts").
        if customerContext != viewContext {
             print("Warning: Customer's managed object context (\(customerContext)) differs from the view's context (\(viewContext)). This could lead to save issues. Proceeding with viewContext, but investigate context management if errors occur.")
             // Consider fetching the customer within the viewContext if necessary:
             // guard let customerInCorrectContext = viewContext.object(with: validCustomer.objectID) as? Customer else { ... handle error ... }
             // For now, we proceed assuming the relationship assignment will work if contexts are compatible,
             // but this is a potential point of failure if contexts are truly separate (e.g., different persistent stores).
        }

        print("Context check passed. Creating new Proposal object in context: \(viewContext)")

        // Create the new Proposal object within the view's managed object context
        let newProposal = Proposal(context: viewContext)
        newProposal.id = UUID() // Assign a unique ID
        // Use the state variable for the name, default if empty (button disable should prevent this)
        newProposal.proposalName = proposalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Proposal for \(validCustomer.name ?? "Customer")" : proposalName
        newProposal.creationDate = Date() // Set creation date
        newProposal.lastModifiedDate = Date() // Set last modified date
        newProposal.status = "Draft" // Set default status

        // **Crucial:** Associate with the *validated* customer object.
        // This operation requires both objects to be in compatible contexts.
        newProposal.customer = validCustomer

        print("New Proposal object created (ID: \(newProposal.id?.uuidString ?? "nil"), Name: \(newProposal.proposalName ?? "nil")). Attempting to save context.")

        // Attempt to save the changes to the Core Data store
        do {
            // Check for changes before saving (optional optimization)
            if viewContext.hasChanges {
                 try viewContext.save()
                 print("Successfully saved new proposal for customer \(validCustomer.name ?? "Unknown").")
                 // Log the successful activity
//                 ActivityLogger.shared.logActivity(message: "Created proposal '\(newProposal.proposalName ?? "Untitled")' for customer \(validCustomer.name ?? //"Unknown")", context: viewContext)
                 dismiss() // Dismiss the view upon successful creation
            } else {
                 print("No changes detected in context, skipping save.")
                 dismiss() // Dismiss even if no save was needed (e.g., validation failed silently before)
            }
        } catch {
            // Handle and log the Core Data save error
            let nsError = error as NSError
            print("FATAL ERROR saving context: \(nsError), \(nsError.userInfo)")
            // Rollback changes on failure
            viewContext.rollback()
            // Log the failed activity
           // ActivityLogger.shared.logActivity(message: "Failed to create proposal: \(error.localizedDescription)", context: viewContext)
            // TODO: Show an error message to the user via an alert
            // showSaveErrorAlert(error: nsError)
        }
    }

    // TODO: Placeholder for potential helper functions to show alerts
    // private func alertUserAboutInternalError() { ... }
    // private func showSaveErrorAlert(error: NSError) { ... }
}

// MARK: - Previews
struct CreateProposalView_Previews: PreviewProvider {
    static var previews: some View {
        // Obtain the preview context
        let previewContext = PersistenceController.preview.container.viewContext
        // Create a sample Customer in the preview context
        let sampleCustomer = Customer(context: previewContext)
        sampleCustomer.id = UUID()
        sampleCustomer.name = "Preview Customer Inc."
        sampleCustomer.email = "preview@example.com"
        sampleCustomer.phone = "555-1234"
        sampleCustomer.address = "123 Preview Lane"
        // Add any other necessary default attributes for the Customer entity

        // Attempt to save the sample customer (optional, but good practice for previews)
        // try? previewContext.save()

        // Return the view, injecting the preview context
        return CreateProposalView(customer: sampleCustomer)
            .environment(\.managedObjectContext, previewContext)
    }
}
