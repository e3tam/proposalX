// TaskSummarySection.swift
// Component for displaying task summary in proposal detail view

import SwiftUI

struct TaskSummarySection: View {
    @ObservedObject var proposal: Proposal
    @State private var showingAddTask = false
    
    var body: some View {
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
            
            // Task summary view
            if proposal.tasksArray.isEmpty {
                EmptyTasksView()
            } else {
                ProposalTaskListView(tasks: proposal.tasksArray)
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(proposal: proposal)
        }
    }
}

struct EmptyTasksView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
            
            VStack(spacing: 10) {
                Image(systemName: "checklist")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                Text("No tasks yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Add tasks to track important actions for this proposal")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Renamed from TaskListView to ProposalTaskListView
struct ProposalTaskListView: View {
    let tasks: [Task]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(tasks.prefix(3), id: \.self) { task in
                    TaskRow(task: task)
                    
                    if task != tasks.prefix(3).last {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
                
                if tasks.count > 3 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    NavigationLink(destination: Text("All Tasks View")) {
                        HStack {
                            Text("View all \(tasks.count) tasks")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
        }
    }
}

struct TaskRow: View {
    @ObservedObject var task: Task
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator
            Image(systemName: task.status == "Completed" ? "checkmark.circle.fill" : "circle")
                .foregroundColor(statusColor)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Text("Due:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .gray)
                    }
                }
            }
            
            Spacer()
            
            // Priority indicator
            if let priority = task.priority, priority != "Normal" {
                Text(priority)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch task.status {
        case "Completed": return .green
        case "In Progress": return .blue
        default: return task.isOverdue ? .red : .orange
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case "High": return .red
        case "Medium": return .orange
        default: return .blue
        }
    }
}
