//
//  TaskStatusChart.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// TaskStatusChart.swift
// Chart component for visualizing task statuses
//

import SwiftUI
import Charts

struct TaskStatusChart: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.status, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    var body: some View {
        Group {
            if tasks.isEmpty {
                Text("No tasks available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(taskStatusCounts.keys.sorted(), id: \.self) { status in
                        BarMark(
                            x: .value("Status", status),
                            y: .value("Count", taskStatusCounts[status] ?? 0)
                        )
                        .cornerRadius(8)
                        .foregroundStyle(by: .value("Status", status))
                    }
                }
                .chartForegroundStyleScale([
                    "New": Color.blue,
                    "In Progress": Color.orange,
                    "Completed": Color.green,
                    "Deferred": Color.gray
                ])
            }
        }
    }
    
    private var taskStatusCounts: [String: Int] {
        var counts: [String: Int] = [
            "New": 0,
            "In Progress": 0,
            "Completed": 0,
            "Deferred": 0
        ]
        
        tasks.forEach { task in
            if let status = task.status {
                counts[status, default: 0] += 1
            }
        }
        
        return counts
    }
}