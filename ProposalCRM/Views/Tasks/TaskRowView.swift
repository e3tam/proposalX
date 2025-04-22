//
//  TaskRowView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// TaskRowView.swift
// Row component for displaying a task in a list

import SwiftUI

struct TaskRowView: View {
    @ObservedObject var task: Task
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(task.statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title ?? "")
                        .font(.headline)
                        .strikethrough(task.status == "Completed")
                    
                    if task.isOverdue {
                        Text("OVERDUE")
                            .font(.caption)
                            .padding(2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    if let proposal = task.proposal {
                        Text(proposal.formattedNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Priority indicator
            Circle()
                .fill(task.priorityColor)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
        .opacity(task.status == "Completed" ? 0.6 : 1.0)
    }
}