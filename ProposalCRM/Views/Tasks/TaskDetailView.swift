//
//  TaskDetailView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// TaskDetailView.swift
// Detailed view for a task with editing capability

import SwiftUI
import CoreData

struct TaskDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var task: Task
    
    @State private var isEditing = false
    @State private var title: String
    @State private var taskDescription: String
    @State private var priority: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var status: String
    @State private var notes: String
    
    let priorities = ["High", "Medium", "Low"]
    let statuses = ["New", "In Progress", "Completed", "Deferred"]
    
    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _taskDescription = State(initialValue: task.desc ?? "")
        _priority = State(initialValue: task.priority ?? "Medium")
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _status = State(initialValue: task.status ?? "New")
        _notes = State(initialValue: task.notes ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let proposal = task.proposal {
                            NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                                Text("Proposal: \(proposal.formattedNumber)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { isEditing.toggle() }) {
                        Text(isEditing ? "Done" : "Edit")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                if isEditing {
                    // Editable view
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Title", text: $title)
                            .font(.headline)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(priorities, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Picker("Status", selection: $status) {
                            ForEach(statuses, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Toggle("Has Due Date", isOn: $hasDueDate)
                            .padding(.vertical, 8)
                        
                        if hasDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        }
                        
                        Text("Description")
                            .font(.headline)
                        
                        TextEditor(text: $taskDescription)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Notes")
                            .font(.headline)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                } else {
                    // Read-only view
                    VStack(alignment: .leading, spacing: 15) {
                        // Priority and Status
                        HStack {
                            HStack {
                                Circle()
                                    .fill(task.priorityColor)
                                    .frame(width: 12, height: 12)
                                Text(task.priority ?? "Medium")
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            
                            Spacer()
                            
                            HStack {
                                Circle()
                                    .fill(task.statusColor)
                                    .frame(width: 12, height: 12)
                                Text(task.status ?? "New")
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Due date
                        if let dueDate = task.dueDate {
                            HStack {
                                Text("Due:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(dueDate, style: .date)
                                    .font(.subheadline)
                                
                                Text("at")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(dueDate, style: .time)
                                    .font(.subheadline)
                                
                                if task.isOverdue {
                                    Text("OVERDUE")
                                        .font(.caption)
                                        .padding(2)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description:")
                                .font(.headline)
                            
                            if let desc = task.desc, !desc.isEmpty {
                                Text(desc)
                                    .foregroundColor(.primary)
                            } else {
                                Text("No description provided")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        
                        // Notes
                        if let notes = task.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes:")
                                    .font(.headline)
                                
                                Text(notes)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Creation info
                        HStack {
                            Text("Created:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let creationDate = task.creationDate {
                                Text(creationDate, style: .date)
                                    .font(.caption)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Quick actions
                        HStack {
                            if task.status != "Completed" {
                                Button(action: markAsComplete) {
                                    Label("Mark as Complete", systemImage: "checkmark.circle")
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            } else {
                                Button(action: reopenTask) {
                                    Label("Reopen Task", systemImage: "arrow.clockwise")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { isEditing = true }) {
                                Label("Edit", systemImage: "pencil")
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Task Details")
    }
    
    private func saveChanges() {
        task.title = title
        task.desc = taskDescription
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.status = status
        task.notes = notes
        
        // Check if status changed to completed
        let wasCompleted = task.status == "Completed" && status != "Completed"
        let nowCompleted = task.status != "Completed" && status == "Completed"
        
        do {
            try viewContext.save()
            
            if let proposal = task.proposal {
                // Log the status change if applicable
                if nowCompleted {
                    ActivityLogger.logTaskCompleted(
                        proposal: proposal,
                        context: viewContext,
                        taskTitle: title
                    )
                } else if wasCompleted || status != task.status {
                    ActivityLogger.logActivity(
                        type: "TaskUpdated",
                        description: "Updated task status to \(status)",
                        proposal: proposal,
                        context: viewContext
                    )
                } else {
                    ActivityLogger.logActivity(
                        type: "TaskUpdated",
                        description: "Updated task details",
                        proposal: proposal,
                        context: viewContext
                    )
                }
            }
            
            isEditing = false
        } catch {
            let nsError = error as NSError
            print("Error saving task changes: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func markAsComplete() {
        status = "Completed"
        saveChanges()
    }
    
    private func reopenTask() {
        status = "In Progress"
        saveChanges()
    }
}