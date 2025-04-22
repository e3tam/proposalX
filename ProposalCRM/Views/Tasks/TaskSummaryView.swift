//
//  TaskSummaryView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// TaskSummaryView.swift
// Summary view of tasks for a proposal

import SwiftUI

struct TaskSummaryView: View {
    @ObservedObject var proposal: Proposal
    @State private var showingAddTask = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if proposal.tasksArray.isEmpty {
                Text("No tasks created yet")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
            } else {
                ZStack {
                    // Solid background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                    
                    VStack(spacing: 0) {
                        // Task list
                        ForEach(proposal.tasksArray.prefix(5), id: \.self) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                HStack {
                                    Circle()
                                        .fill(task.statusColor)
                                        .frame(width: 12, height: 12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .strikethrough(task.status == "Completed")
                                        
                                        HStack {
                                            Circle()
                                                .fill(task.priorityColor)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(task.priority ?? "")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            if let dueDate = task.dueDate {
                                                Text("•")
                                                    .foregroundColor(.gray)
                                                
                                                Text(dueDate, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(task.isOverdue ? .red : .gray)
                                            }
                                            
                                            if task.isOverdue {
                                                Text("OVERDUE")
                                                    .font(.caption)
                                                    .padding(2)
                                                    .background(Color.red)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(Color.black.opacity(0.1))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                        
                        // Show more button if needed
                        if proposal.tasksArray.count > 5 {
                            NavigationLink(destination: TaskListViewForProposal(proposal: proposal)) {
                                Text("View All \(proposal.tasksArray.count) Tasks")
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(proposal: proposal)
        }
    }
}
