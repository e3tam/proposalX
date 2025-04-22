import SwiftUI
import CoreData

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var proposal: Proposal
    
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var priority = "Medium"
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400) // tomorrow
    @State private var notes = ""
    
    let priorities = ["High", "Medium", "Low"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $taskDescription)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
                
                // Quick templates for common task types
                Section(header: Text("Quick Templates")) {
                    Button("Follow-up Call") {
                        title = "Follow-up Call with \(proposal.customerName)"
                        taskDescription = "Schedule a call to discuss proposal details"
                        priority = "High"
                        hasDueDate = true
                        dueDate = Date().addingTimeInterval(86400) // tomorrow
                    }
                    
                    Button("Send Pricing Update") {
                        title = "Send Updated Pricing"
                        taskDescription = "Send updated pricing information to the customer"
                        priority = "Medium"
                        hasDueDate = true
                        dueDate = Date().addingTimeInterval(172800) // 2 days
                    }
                    
                    Button("Request Feedback") {
                        title = "Request Proposal Feedback"
                        taskDescription = "Ask for feedback on the proposal to address any concerns"
                        priority = "Medium"
                        hasDueDate = true
                        dueDate = Date().addingTimeInterval(259200) // 3 days
                    }
                    
                    Button("Final Decision Follow-up") {
                        title = "Follow-up on Final Decision"
                        taskDescription = "Check with customer about final decision on the proposal"
                        priority = "High"
                        hasDueDate = true
                        dueDate = Date().addingTimeInterval(518400) // 6 days
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
        // Create the new task within a transaction
        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = title
        task.desc = taskDescription
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.notes = notes
        task.creationDate = Date()
        task.status = "New"
        
        // Important: Explicitly set the relationship to this proposal
        task.proposal = proposal
        
        do {
            // Save the changes to Core Data
            try viewContext.save()
            
            // Log the activity
            ActivityLogger.logTaskAdded(
                proposal: proposal,
                context: viewContext,
                taskTitle: title
            )
            
            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error adding task: \(nsError), \(nsError.userInfo)")
        }
    }
}
