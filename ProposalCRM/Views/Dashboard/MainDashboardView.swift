//
//  MainDashboardView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


import SwiftUI

struct MainDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("dashboardLayout") private var dashboardLayout = "Default"
    
    let layoutOptions = ["Default", "Financial Focus", "Pipeline Focus", "Task Focus"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Dashboard header with layout selection
                dashboardHeader
                
                // Dynamic dashboard content based on selected layout
                switch dashboardLayout {
                case "Financial Focus":
                    financialFocusLayout
                case "Pipeline Focus":
                    pipelineFocusLayout
                case "Task Focus":
                    taskFocusLayout
                default:
                    defaultLayout
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                refreshButton
            }
        }
    }
    
    // MARK: - Header
    
    private var dashboardHeader: some View {
        HStack {
            Text("Overview")
                .font(.headline)
            
            Spacer()
            
            Menu {
                Picker("Dashboard Layout", selection: $dashboardLayout) {
                    ForEach(layoutOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } label: {
                Label("Layout", systemImage: "square.grid.2x2")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            // Animation for refresh action
            withAnimation {
                // This would typically trigger a data refresh
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
    }
    
    // MARK: - Dashboard Layouts
    
    // Default balanced layout
    private var defaultLayout: some View {
        VStack(spacing: 20) {
            // Top stats cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    StatsSummaryCardView(
                        title: "Active Proposals",
                        metric: "2",
                        subtitle: "Value: $21,769.90",
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    StatsSummaryCardView(
                        title: "Pending Tasks",
                        metric: "3",
                        subtitle: "0 overdue",
                        icon: "checklist",
                        color: .orange
                    )
                    
                    StatsSummaryCardView(
                        title: "Success Rate",
                        metric: "0.0%",
                        subtitle: "0 won proposals",
                        icon: "chart.bar",
                        color: .green
                    )
                    
                    StatsSummaryCardView(
                        title: "Average Deal",
                        metric: "$0",
                        subtitle: "No deals closed yet",
                        icon: "dollarsign.circle",
                        color: .purple
                    )
                }
                .padding(.horizontal, 2)
            }
            
            // Main analytics charts
            ProposalAnalyticsChartView()
            
            // Task and financial details in two columns
            HStack(alignment: .top, spacing: 20) {
                TaskStatusChartView()
                    .frame(maxWidth: .infinity)
                
                TaskSummaryDashboard()
                    .frame(maxWidth: .infinity)
            }
            
            // Recently updated proposals and activity
            HStack(alignment: .top, spacing: 20) {
                RecentProposalView()
                    .frame(maxWidth: .infinity)
                
                RecentActivityDashboard()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // Financial focused layout
    private var financialFocusLayout: some View {
        VStack(spacing: 20) {
            // Primary financial metrics
            FinancialMetricsChartView()
            
            // Revenue pipeline view
            VStack(alignment: .leading, spacing: 8) {
                Text("Revenue Pipeline")
                    .font(.headline)
                
                RevenuePipelineView()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Financial supporting charts
            HStack(alignment: .top, spacing: 20) {
                // Profit margin breakdown
                ProfitMarginBreakdownView()
                    .frame(maxWidth: .infinity)
                
                // Revenue by customer
                RevenueByCustomerView()
                    .frame(maxWidth: .infinity)
            }
            
            // Recent won/lost deals
            RecentDealsView()
        }
    }
    
    // Sales pipeline focused layout
    private var pipelineFocusLayout: some View {
        VStack(spacing: 20) {
            // Pipeline stage metrics
            SalesPipelineView()
            
            // Main sales analytics chart
            ProposalAnalyticsChartView()
            
            // Sales performance metrics in columns
            HStack(alignment: .top, spacing: 20) {
                SalesConversionView()
                    .frame(maxWidth: .infinity)
                
                LeadTimeAnalysisView()
                    .frame(maxWidth: .infinity)
            }
            
            // Upcoming proposals that need attention
            ProposalsNeedingAttentionView()
        }
    }
    
    // Task focused layout
    private var taskFocusLayout: some View {
        VStack(spacing: 20) {
            // Task overview metrics
            TaskOverviewView()
            
            // Main task status chart
            TaskStatusChartView()
            
            // Due tasks by project/proposal
            HStack(alignment: .top, spacing: 20) {
                UpcomingTasksView()
                    .frame(maxWidth: .infinity)
                
                OverdueTasksView()
                    .frame(maxWidth: .infinity)
            }
            
            // Task completion trend
            TaskCompletionTrendView()
            
            // Task assignment breakdown
            TaskAssignmentView()
        }
    }
}

// MARK: - Helper Views

// Simple stats summary card
struct StatsSummaryCardView: View {
    let title: String
    let metric: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(metric)
                .font(.system(size: 24, weight: .bold))
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .frame(width: 170, height: 110)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Placeholder Views
// These would be implemented with real data in a complete implementation

struct RecentProposalView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Proposals")
                .font(.headline)
            
            ForEach(0..<3) { _ in
                proposalRow
                Divider()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var proposalRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROP-20250416-001")
                    .font(.subheadline)
                
                Text("Acme Corporation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$10,879.95")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Draft")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RevenuePipelineView: View {
    var body: some View {
        // Placeholder for the revenue pipeline visualization
        HStack(spacing: 0) {
            pipelineStage(label: "Draft", value: "$21,769.90", count: 2, color: .gray)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            pipelineStage(label: "Sent", value: "$0", count: 0, color: .blue)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            pipelineStage(label: "Won", value: "$0", count: 0, color: .green)
        }
        .frame(height: 160)
    }
    
    private func pipelineStage(label: String, value: String, count: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                VStack {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(count) proposals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct ProfitMarginBreakdownView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profit Margin Analysis")
                .font(.headline)
            
            Text("No data available yet")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RevenueByCustomerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Revenue by Customer")
                .font(.headline)
            
            Text("No data available yet")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RecentDealsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Deals")
                .font(.headline)
            
            Text("No closed deals yet")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SalesPipelineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sales Pipeline")
                .font(.headline)
            
            HStack {
                StatsSummaryCardView(
                    title: "Draft",
                    metric: "2",
                    subtitle: "$21,769.90",
                    icon: "doc.text",
                    color: .gray
                )
                
                StatsSummaryCardView(
                    title: "Pending",
                    metric: "0",
                    subtitle: "$0",
                    icon: "hourglass",
                    color: .orange
                )
                
                StatsSummaryCardView(
                    title: "Sent",
                    metric: "0",
                    subtitle: "$0",
                    icon: "paperplane.fill",
                    color: .blue
                )
                
                StatsSummaryCardView(
                    title: "Won",
                    metric: "0",
                    subtitle: "$0",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SalesConversionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sales Conversion")
                .font(.headline)
            
            Text("No data available yet")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct LeadTimeAnalysisView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lead Time Analysis")
                .font(.headline)
            
            Text("No data available yet")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProposalsNeedingAttentionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Proposals Needing Attention")
                .font(.headline)
            
            Text("No proposals currently need attention")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TaskOverviewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Overview")
                .font(.headline)
            
            HStack {
                StatsSummaryCardView(
                    title: "Pending",
                    metric: "3",
                    subtitle: "0 overdue",
                    icon: "clock",
                    color: .orange
                )
                
                StatsSummaryCardView(
                    title: "Today",
                    metric: "1",
                    subtitle: "Due soon",
                    icon: "calendar",
                    color: .blue
                )
                
                StatsSummaryCardView(
                    title: "Completed",
                    metric: "0",
                    subtitle: "This week",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatsSummaryCardView(
                    title: "Backlog",
                    metric: "2",
                    subtitle: "Not scheduled",
                    icon: "tray.full",
                    color: .gray
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct UpcomingTasksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Tasks")
                .font(.headline)
            
            ForEach(1...3, id: \.self) { index in
                taskRow(index: index)
                if index < 3 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func taskRow(index: Int) -> some View {
        HStack {
            Circle()
                .fill(index == 1 ? Color.blue : (index == 2 ? Color.orange : Color.purple))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(["Follow-up Call with Acme Corporation", "Request Proposal Feedback", "Final Decision Follow-up"][index-1])
                    .font(.subheadline)
                
                Text(["20 Apr 2025, 07:01", "20 Apr 2025, 07:11", "21 Apr 2025, 07:11"][index-1])
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct OverdueTasksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overdue Tasks")
                .font(.headline)
            
            Text("No overdue tasks")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TaskCompletionTrendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Completion Trend")
                .font(.headline)
            
            Text("No historical data available yet")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 200)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TaskAssignmentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Assignment")
                .font(.headline)
            
            Text("No assignment data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MainDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainDashboardView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}