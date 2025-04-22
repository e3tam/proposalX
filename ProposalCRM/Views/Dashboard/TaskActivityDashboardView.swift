//
//  TaskActivityDashboardView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// TaskActivityDashboardView.swift
// Enhanced dashboard with task and activity monitoring
//

import SwiftUI
import CoreData
import Charts

struct TaskActivityDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        predicate: NSPredicate(format: "status != %@", "Completed"),
        animation: .default)
    private var upcomingTasks: FetchedResults<Task>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.timestamp, ascending: false)],
        animation: .default)
    private var recentActivities: FetchedResults<Activity>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats
                HStack {
                    DashboardStatCard(
                        title: "Active Proposals",
                        value: String(activeProposalsCount),
                        subtitle: "Total value: \(String(format: "%.2f", activeProposalsValue))",
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    DashboardStatCard(
                        title: "Pending Tasks",
                        value: String(upcomingTasks.count),
                        subtitle: "\(overdueTasks) overdue",
                        icon: "checklist",
                        color: overdueTasks > 0 ? .red : .orange
                    )
                    
                    DashboardStatCard(
                        title: "Success Rate",
                        value: "\(String(format: "%.1f", successRate))%",
                        subtitle: "\(wonProposalsCount) won proposals",
                        icon: "chart.bar.fill",
                        color: .green
                    )
                }
                
                // Upcoming Tasks Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Upcoming Tasks")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: TaskListView()) {
                            Text("View All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if upcomingTasks.isEmpty {
                        Text("No upcoming tasks")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(upcomingTasks.prefix(5)), id: \.self) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    HStack {
                                        // Priority indicator
                                        Circle()
                                            .fill(task.priorityColor)
                                            .frame(width: 12, height: 12)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.title ?? "")
                                                .font(.headline)
                                                .lineLimit(1)
                                            
                                            if let proposal = task.proposal {
                                                Text("Proposal: \(proposal.formattedNumber)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Due date or overdue indicator
                                        if let dueDate = task.dueDate {
                                            VStack(alignment: .trailing) {
                                                if task.isOverdue {
                                                    Text("OVERDUE")
                                                        .font(.caption)
                                                        .padding(4)
                                                        .background(Color.red)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(4)
                                                } else if Calendar.current.isDateInToday(dueDate) {
                                                    Text("TODAY")
                                                        .font(.caption)
                                                        .padding(4)
                                                        .background(Color.orange)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(4)
                                                } else {
                                                    Text(dueDate, style: .date)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                if !task.isOverdue && !Calendar.current.isDateInToday(dueDate) {
                                                    Text(dueDate, style: .time)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if task != upcomingTasks.prefix(5).last {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                
                // Recent Activity Timeline
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Activity")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: GlobalActivityView()) {
                            Text("View All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if recentActivities.isEmpty {
                        Text("No recent activity")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(recentActivities.prefix(5)), id: \.self) { activity in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        // Activity type icon
                                        Image(systemName: activity.typeIcon)
                                            .foregroundColor(activity.typeColor)
                                        
                                        // Activity info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(activity.description ?? "")
                                                .lineLimit(1)
                                            
                                            HStack {
                                                if let proposal = activity.proposal {
                                                    Text("Proposal: \(proposal.formattedNumber)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(activity.formattedTimestamp)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                if activity != recentActivities.prefix(5).last {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                
                // Task Analysis Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Task Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    TaskStatusChartView()
                        .frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
                
                // Proposal Status Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Proposal Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ProposalStatusChart()
                        .frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
    
    // Computed properties
    private var activeProposalsCount: Int {
        return proposals.filter { $0.status != "Won" && $0.status != "Lost" }.count
    }
    
    private var activeProposalsValue: Double {
        return proposals
            .filter { $0.status != "Won" && $0.status != "Lost" }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    private var overdueTasks: Int {
        return upcomingTasks.filter { $0.isOverdue }.count
    }
    
    private var wonProposalsCount: Int {
        return proposals.filter { $0.status == "Won" }.count
    }
    
    private var successRate: Double {
        let closedProposals = proposals.filter { 
            $0.status == "Won" || $0.status == "Lost" 
        }
        
        guard closedProposals.count > 0 else { return 0 }
        
        let wonCount = closedProposals.filter { $0.status == "Won" }.count
        return Double(wonCount) / Double(closedProposals.count) * 100
    }
}
