//
//  TaskActivityDashboardView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
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
    
    // Computed properties moved outside of body
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats
                quickStatsSection
                
                // Upcoming Tasks Section
                upcomingTasksSection
                
                // Recent Activity Timeline
                recentActivitySection
                
                // Task Analysis Chart
                taskAnalysisSection
                
                // Proposal Status Chart
                proposalStatusSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
    
    // MARK: - Dashboard Sections
    
    private var quickStatsSection: some View {
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
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Upcoming Tasks", destination: TaskListView())
            
            if upcomingTasks.isEmpty {
                emptyStateView(message: "No upcoming tasks")
            } else {
                upcomingTasksList
            }
        }
    }
    
    private var upcomingTasksList: some View {
        VStack(spacing: 0) {
            ForEach(Array(upcomingTasks.prefix(5)), id: \.self) { task in
                upcomingTaskRow(task: task)
                
                if task != upcomingTasks.prefix(5).last {
                    Divider()
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func upcomingTaskRow(task: Task) -> some View {
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
                        Text("Proposal: \(proposal.number ?? "New Proposal")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Due date or overdue indicator
                taskDueDateView(task: task)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func taskDueDateView(task: Task) -> some View {
        Group {
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
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Recent Activity", destination: GlobalActivityView())
            
            if recentActivities.isEmpty {
                emptyStateView(message: "No recent activity")
            } else {
                recentActivitiesList
            }
        }
    }
    
    private var recentActivitiesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(recentActivities.prefix(5)), id: \.self) { activity in
                recentActivityRow(activity: activity)
                
                if activity != recentActivities.prefix(5).last {
                    Divider()
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func recentActivityRow(activity: Activity) -> some View {
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
                            Text("Proposal: \(proposal.number ?? "New Proposal")")
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
    }
    
    private var taskAnalysisSection: some View {
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
    }
    
    private var proposalStatusSection: some View {
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
    
    // MARK: - Helper Views
    
    private func sectionHeader<Destination: View>(title: String, destination: Destination) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            NavigationLink(destination: destination) {
                Text("View All")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func emptyStateView(message: String) -> some View {
        Text(message)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
    }
}

// MARK: - Preview Provider
struct TaskActivityDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskActivityDashboardView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
