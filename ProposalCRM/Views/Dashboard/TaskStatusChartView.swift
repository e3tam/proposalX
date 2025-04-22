//
//  TaskStatusChartView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


import SwiftUI
import Charts

struct TaskStatusChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.status, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    @State private var selectedStatus: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks by Status")
                .font(.headline)
            
            if tasks.isEmpty {
                Text("No tasks available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 20) {
                    // Pie chart
                    Chart {
                        ForEach(taskStatusCounts.keys.sorted(), id: \.self) { status in
                            SectorMark(
                                angle: .value("Count", taskStatusCounts[status] ?? 0),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("Status", status))
                            .opacity(selectedStatus == status ? 1 : (selectedStatus == nil ? 1 : 0.3))
                        }
                    }
                    .chartForegroundStyleScale([
                        "New": Color.blue,
                        "In Progress": Color.orange,
                        "Completed": Color.green,
                        "Deferred": Color.gray
                    ])
                    .chartLegend(position: .bottom, spacing: 20)
                    .chartAngleSelection(value: $selectedStatus)
                    .frame(height: 240)
                    
                    // Status breakdown
                    VStack(spacing: 10) {
                        ForEach(taskStatusCounts.keys.sorted(), id: \.self) { status in
                            if let count = taskStatusCounts[status], count > 0 {
                                HStack {
                                    statusIndicator(for: status)
                                    
                                    Text(status)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    ProgressView(value: Double(count), total: Double(totalTasks))
                                        .progressViewStyle(LinearProgressViewStyle(tint: statusColor(for: status)))
                                        .frame(maxWidth: .infinity)
                                    
                                    Text("\(count)")
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                                .background(selectedStatus == status ? Color(UIColor.tertiarySystemBackground) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    withAnimation {
                                        if selectedStatus == status {
                                            selectedStatus = nil
                                        } else {
                                            selectedStatus = status
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Task priority distribution
                    HStack(spacing: 15) {
                        priorityCard(title: "High", count: taskCountByPriority["High"] ?? 0, color: .red)
                        priorityCard(title: "Medium", count: taskCountByPriority["Medium"] ?? 0, color: .orange)
                        priorityCard(title: "Low", count: taskCountByPriority["Low"] ?? 0, color: .blue)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func statusIndicator(for status: String) -> some View {
        Circle()
            .fill(statusColor(for: status))
            .frame(width: 12, height: 12)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "New": return .blue
        case "In Progress": return .orange
        case "Completed": return .green
        case "Deferred": return .gray
        default: return .secondary
        }
    }
    
    private func priorityCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text("Tasks")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    private var taskStatusCounts: [String: Int] {
        var counts: [String: Int] = [
            "New": 0,
            "In Progress": 0,
            "Completed": 0,
            "Deferred": 0
        ]
        
        for task in tasks {
            if let status = task.status {
                counts[status, default: 0] += 1
            }
        }
        
        return counts
    }
    
    private var taskCountByPriority: [String: Int] {
        var counts: [String: Int] = [
            "High": 0,
            "Medium": 0,
            "Low": 0
        ]
        
        for task in tasks {
            if let priority = task.priority {
                counts[priority, default: 0] += 1
            }
        }
        
        return counts
    }
    
    private var totalTasks: Int {
        tasks.count
    }
}

struct TaskStatusChartView_Previews: PreviewProvider {
    static var previews: some View {
        TaskStatusChartView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}