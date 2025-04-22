//
//  TaskSummaryDashboard.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// TaskSummaryDashboard.swift
// Condensed task summary for dashboard widgets
//

import SwiftUI

struct TaskSummaryDashboard: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        predicate: NSPredicate(format: "status != %@", "Completed"),
        animation: .default)
    private var pendingTasks: FetchedResults<Task>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Tasks Overview")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: TaskListView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            // Task stats summary
            HStack(spacing: 20) {
                TaskStatBox(
                    count: pendingTasks.count,
                    label: "Pending",
                    color: .blue
                )
                
                TaskStatBox(
                    count: overdueTasksCount,
                    label: "Overdue",
                    color: .red
                )
                
                TaskStatBox(
                    count: todayTasksCount,
                    label: "Today",
                    color: .orange
                )
                
                TaskStatBox(
                    count: highPriorityCount,
                    label: "High Priority",
                    color: .purple
                )
            }
            
            // Next upcoming task
            if let nextTask = pendingTasks.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Task")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nextTask.title ?? "")
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let dueDate = nextTask.dueDate {
                                Text("Due: \(dueDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(nextTask.isOverdue ? .red : .secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(nextTask.priorityColor)
                            .frame(width: 12, height: 12)
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var overdueTasksCount: Int {
        return pendingTasks.filter { $0.isOverdue }.count
    }
    
    private var todayTasksCount: Int {
        return pendingTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }.count
    }
    
    private var highPriorityCount: Int {
        return pendingTasks.filter { $0.priority == "High" }.count
    }
}

struct TaskStatBox: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
}