import SwiftUI
import Charts
import CoreData

struct EnhancedDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch proposals
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    // Fetch tasks
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        predicate: NSPredicate(format: "status != %@", "Completed"),
        animation: .default)
    private var pendingTasks: FetchedResults<Task>
    
    // Time period for chart data
    @State private var selectedTimePeriod = "3 Months"
    let timePeriods = ["1 Month", "3 Months", "6 Months", "1 Year", "All"]
    
    // Dashboard tab selection
    @State private var selectedTab = "Overview"
    let dashboardTabs = ["Overview", "Sales", "Tasks", "Financial", "Analytics"]
    
    // User preferences
    @AppStorage("dashboardColorScheme") private var colorScheme = "Default"
    let colorSchemes = ["Default", "Blue", "Green", "Purple", "Dark"]
    
    // Animation states
    @State private var isRefreshing = false
    @State private var showInsights = false
    
    // Selected chart data points for interactive charts
    @State private var selectedDataPoint: String?
    @State private var selectedTaskStatus: String?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Dashboard header with tabs
                VStack(spacing: 0) {
                    // Main header with title and actions
                    dashboardHeader
                    
                    // Tab selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(dashboardTabs, id: \.self) { tab in
                                TabButton(
                                    title: tab,
                                    isSelected: selectedTab == tab,
                                    action: { withAnimation { selectedTab = tab } }
                                )
                                .frame(width: geometry.size.width / CGFloat(min(dashboardTabs.count, 5)))
                            }
                        }
                    }
                    .padding(.top, 4)
                    .background(Color(UIColor.systemBackground))
                }
                
                // Main content area based on selected tab
                ScrollView {
                    VStack(spacing: 20) {
                        // Dynamic content based on selected tab
                        switch selectedTab {
                        case "Overview":
                            overviewTab
                        case "Sales":
                            salesPipelineTab
                        case "Tasks":
                            tasksManagementTab
                        case "Financial":
                            financialAnalysisTab
                        case "Analytics":
                            advancedAnalyticsTab
                        default:
                            overviewTab
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .frame(width: geometry.size.width)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: - Dashboard Header
    private var dashboardHeader: some View {
        HStack {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.leading)
            
            Spacer()
            
            // Theme selector
            Menu {
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(colorSchemes, id: \.self) { scheme in
                        Text(scheme).tag(scheme)
                    }
                }
            } label: {
                Image(systemName: "paintpalette")
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 5)
            
            // Refresh button with animation
            Button(action: {
                withAnimation {
                    isRefreshing = true
                    // Simulate refresh
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isRefreshing = false
                    }
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(accentColor)
                    .rotationEffect(Angle(degrees: isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
            .padding(.trailing)
        }
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Tab Button
    struct TabButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(
                    VStack {
                        Spacer()
                        if isSelected {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 3)
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 20) {
            // Key metrics cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                // Pending Tasks Card
                metricCard(
                    title: "Pending Tasks",
                    value: "\(pendingTasks.count)",
                    detail: "\(overdueTasks) overdue",
                    icon: "checklist",
                    iconColor: overdueTasks > 0 ? .red : .orange,
                    bgColor: cardBackgroundColor
                )
                
                // Success Rate Card
                metricCard(
                    title: "Success Rate",
                    value: "\(formatPercent(successRate))%",
                    detail: "\(wonProposalsCount) won proposals",
                    icon: "chart.xyaxis.line",
                    iconColor: .green,
                    bgColor: cardBackgroundColor
                )
                
                // Active Proposals Card
                metricCard(
                    title: "Active Proposals",
                    value: "\(activeProposalsCount)",
                    detail: "$\(formatValue(activeProposalsValue))",
                    icon: "doc.text.fill",
                    iconColor: accentColor,
                    bgColor: cardBackgroundColor
                )
                
                // Avg Deal Card
                metricCard(
                    title: "Avg Deal Size",
                    value: "$\(formatValue(avgDealSize))",
                    detail: "\(closedProposalsCount) closed deals",
                    icon: "dollarsign.circle",
                    iconColor: .purple,
                    bgColor: cardBackgroundColor
                )
            }
            
            // Sales performance chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sales Performance")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Time Period", selection: $selectedTimePeriod) {
                        ForEach(timePeriods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                }
                .padding([.horizontal])
                
                salesPerformanceChart
                    .frame(height: 220)
                    .padding([.horizontal, .bottom])
            }
            .background(cardBackgroundColor)
            .cornerRadius(12)
            
            // Recent activities and Tasks
            HStack(alignment: .top, spacing: 15) {
                // Recent proposals
                recentProposalsSection
                    .frame(maxWidth: .infinity)
                
                // Recent activity feed
                recentActivityFeed
                    .frame(maxWidth: .infinity)
            }
            
            // Insights and recommendations
            if showInsights {
                insightsSection
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Toggle insights button
            Button(action: {
                withAnimation {
                    showInsights.toggle()
                }
            }) {
                HStack {
                    Text(showInsights ? "Hide Insights" : "Show Insights")
                    Image(systemName: showInsights ? "chevron.up" : "chevron.down")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(accentColor.opacity(0.1))
                .foregroundColor(accentColor)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Sales Pipeline Tab
    private var salesPipelineTab: some View {
        VStack(spacing: 20) {
            // Pipeline overview section
            salesPipelineOverview
            
            // Pipeline stages visualization
            pipelineStagesView
            
            // Recent and upcoming deals
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent & Upcoming Deals")
                    .font(.headline)
                    .padding([.horizontal])
                
                dealsTimelineView
            }
            .background(cardBackgroundColor)
            .cornerRadius(12)
            
            // Conversion metrics
            conversionMetricsGrid
            
            // Win/loss analysis chart
            winLossAnalysisChart
        }
    }
    
    // MARK: - Tasks Management Tab
    private var tasksManagementTab: some View {
        VStack(spacing: 20) {
            // Tasks overview metrics
            tasksOverviewMetrics
            
            // Task priority distribution chart
            taskPriorityDistributionChart
            
            // Tasks calendar view
            taskCalendarView
            
            // Task completion trend
            taskCompletionTrendChart
            
            // Upcoming tasks section
            VStack(alignment: .leading, spacing: 10) {
                Text("Upcoming Tasks")
                    .font(.headline)
                    .padding([.horizontal])
                
                upcomingTasksListView
                    .padding([.horizontal])
            }
            .padding(.vertical)
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Financial Analysis Tab
    private var financialAnalysisTab: some View {
        VStack(spacing: 20) {
            // Financial metrics summary
            financialMetricsSummary
            
            // Revenue breakdown chart
            revenueBreakdownChart
            
            // Profit margin analysis
            profitMarginAnalysisChart
            
            // Monthly revenue trend
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Monthly Revenue")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Time Period", selection: $selectedTimePeriod) {
                        ForEach(timePeriods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                }
                .padding([.horizontal])
                
                monthlyRevenueChartView
                    .frame(height: 180)
                    .padding([.horizontal, .bottom])
            }
            .background(cardBackgroundColor)
            .cornerRadius(12)
            
            // Revenue by customer
            revenueByCustomerChart
        }
    }
    
    // MARK: - Advanced Analytics Tab
    private var advancedAnalyticsTab: some View {
        VStack(spacing: 20) {
            // Performance trends
            performanceTrendsChart
            
            // Forecast projections
            forecastProjectionsChart
            
            // Comparative analysis
            comparativeAnalysisSection
            
            // Advanced metrics grid
            advancedMetricsGrid
            
            // Data insights section
            VStack(alignment: .leading, spacing: 10) {
                Text("Data Insights")
                    .font(.headline)
                    .padding([.horizontal])
                
                dataInsightsList
            }
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Component Views
    
    // Sales Performance Chart
    private var salesPerformanceChart: some View {
        // Generate combined chart with revenue and deals
        let monthlyData = prepareMonthlyRevenueData()
        let avgRevenue = calculateAverageMonthlyRevenue(from: monthlyData)

        return Chart {
            ForEach(monthlyData, id: \.month) { dataPoint in
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Revenue", dataPoint.revenue)
                )
                .foregroundStyle(accentColor)
                .cornerRadius(4)
            }
            
            // Revenue trend line - fixed version
            LineMark(
                x: .value("Month", monthlyData[0].month),
                y: .value("Trend", monthlyData[0].revenue)
            )
            .lineStyle(StrokeStyle(lineWidth: 3))
            .foregroundStyle(Color.orange)
            
            // Add remaining points to continue the line
            ForEach(monthlyData.dropFirst(), id: \.month) { dataPoint in
                LineMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Trend", dataPoint.revenue)
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                .foregroundStyle(Color.orange)
            }
            
            // Symbol for each point on the line
            ForEach(monthlyData, id: \.month) { dataPoint in
                PointMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Trend", dataPoint.revenue)
                )
                .foregroundStyle(Color.orange)
                .symbolSize(8)
            }
            
            // Average revenue line
            RuleMark(
                y: .value("Average", avgRevenue)
            )
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .foregroundStyle(Color.green)
            .annotation(position: .trailing) {
                Text("Avg: $\(formatValue(avgRevenue))")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // Monthly Revenue Chart
    private var monthlyRevenueChartView: some View {
        // Prepare monthly data
        let monthlyData = prepareMonthlyRevenueData()
        let avgRevenue = calculateAverageMonthlyRevenue(from: monthlyData)
        
        return Chart {
            ForEach(monthlyData, id: \.month) { dataPoint in
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Revenue", dataPoint.revenue)
                )
                .foregroundStyle(Color.blue)
            }
            
            // Average revenue line
            RuleMark(
                y: .value("Average", avgRevenue)
            )
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .foregroundStyle(Color.green)
            .annotation(position: .top) {
                Text("Avg: $\(formatValue(avgRevenue))")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // Upcoming Tasks List View
    private var upcomingTasksListView: some View {
        VStack(spacing: 12) {
            if pendingTasks.isEmpty {
                Text("No upcoming tasks")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Limited to first 3 tasks for performance
                let tasksToDisplay = Array(pendingTasks.prefix(3))
                
                ForEach(tasksToDisplay, id: \.self) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        upcomingTaskRow(task: task)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Recent Proposals Section
    private var recentProposalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Proposals")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: ProposalListView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(accentColor)
                }
            }
            
            if proposals.isEmpty {
                Text("No proposals yet")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(proposals.prefix(3)), id: \.self) { proposal in
                    NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(proposal.formattedNumber)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(proposal.customerName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(proposal.formattedDate)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(proposal.formattedTotal)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(proposal.formattedStatus)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(statusColor(for: proposal.formattedStatus))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Recent Activity Feed
    private var recentActivityFeed: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: GlobalActivityView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(accentColor)
                }
            }
            
            let activities = fetchRecentActivities()
            
            if activities.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(activities, id: \.self) { activity in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(activity.typeColor)
                                .frame(width: 10, height: 10)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activity.desc ?? "")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                if let timestamp = activity.timestamp {
                                    Text(timeAgoFormatter.localizedString(for: timestamp, relativeTo: Date()))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Insights & Recommendations")
                .font(.headline)
                .padding([.horizontal])
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    insightCard(
                        title: "Follow-up Required",
                        description: "2 proposals have been open for more than 30 days",
                        icon: "bell.badge",
                        color: .orange
                    )
                    
                    insightCard(
                        title: "Overdue Tasks",
                        description: "Schedule time to complete \(overdueTasks) overdue tasks",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                    
                    insightCard(
                        title: "Deal Opportunity",
                        description: "Acme Corp's proposal is ready for final review",
                        icon: "dollarsign.circle",
                        color: .green
                    )
                }
                .padding([.horizontal])
            }
            .frame(height: 160)
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Insight Card
    private func insightCard(title: String, description: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            Spacer()
            
            Button("View Details") {
                // Action would go here
            }
            .font(.caption)
            .foregroundColor(color)
        }
        .padding()
        .frame(width: 250, height: 140)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // Sales Pipeline Overview
    private var salesPipelineOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pipeline Overview")
                .font(.headline)
                .padding([.horizontal])
            
            HStack(spacing: 15) {
                pipelineStageCard(
                    stage: "Draft",
                    count: proposalCountByStatus["Draft"] ?? 0,
                    value: proposalValueByStatus["Draft"] ?? 0,
                    color: .gray
                )
                
                pipelineStageCard(
                    stage: "Sent",
                    count: proposalCountByStatus["Sent"] ?? 0,
                    value: proposalValueByStatus["Sent"] ?? 0,
                    color: .blue
                )
                
                pipelineStageCard(
                    stage: "Won",
                    count: proposalCountByStatus["Won"] ?? 0,
                    value: proposalValueByStatus["Won"] ?? 0,
                    color: .green
                )
                
                pipelineStageCard(
                    stage: "Lost",
                    count: proposalCountByStatus["Lost"] ?? 0,
                    value: proposalValueByStatus["Lost"] ?? 0,
                    color: .red
                )
            }
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Pipeline Stage Card
    private func pipelineStageCard(stage: String, count: Int, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stage)
                .font(.headline)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("$\(formatValue(value))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    // Pipeline Stages View
    private var pipelineStagesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pipeline Flow")
                .font(.headline)
                .padding([.horizontal])
            
            // Interactive pipeline visualization
            HStack(spacing: 0) {
                ForEach(["Draft", "Pending", "Sent", "Won"], id: \.self) { stage in
                    let stageCount = proposalCountByStatus[stage] ?? 0
                    let stageValue = proposalValueByStatus[stage] ?? 0
                    
                    VStack(spacing: 8) {
                        Text(stage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            Circle()
                                .stroke(Color(UIColor.tertiarySystemBackground), lineWidth: 3)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .fill(statusColor(for: stage))
                                .frame(width: 50, height: 50)
                            
                            VStack {
                                Text("\(stageCount)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("$\(formatValue(stageValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if stage != "Won" {
                        VStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.tertiarySystemBackground))
                            Spacer()
                        }
                        .frame(width: 30)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding([.horizontal])
            
            // Conversion rates
            HStack(spacing: 20) {
                ConversionIndicator(
                    from: "Draft",
                    to: "Pending",
                    rate: calculateConversionRate(from: "Draft", to: "Pending")
                )
                
                ConversionIndicator(
                    from: "Pending",
                    to: "Sent",
                    rate: calculateConversionRate(from: "Pending", to: "Sent")
                )
                
                ConversionIndicator(
                    from: "Sent",
                    to: "Won",
                    rate: calculateConversionRate(from: "Sent", to: "Won")
                )
            }
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Conversion Indicator
    struct ConversionIndicator: View {
        let from: String
        let to: String
        let rate: Double
        
        var body: some View {
            VStack(spacing: 4) {
                Text("\(from) → \(to)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(rate))%")
                    .font(.headline)
                    .foregroundColor(rate > 50 ? .green : (rate > 30 ? .orange : .red))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    // Deals Timeline View
    private var dealsTimelineView: some View {
        VStack(spacing: 0) {
            if proposals.isEmpty {
                Text("No deals to display")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(proposals.prefix(4)), id: \.self) { proposal in
                    HStack(spacing: 15) {
                        // Date indicator
                        VStack(spacing: 0) {
                            Circle()
                                .fill(statusColor(for: proposal.formattedStatus))
                                .frame(width: 12, height: 12)
                            
                            if proposal != proposals.prefix(4).last {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 2, height: 40)
                            }
                        }
                        .frame(width: 20)
                        
                        // Deal details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(proposal.formattedNumber)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(proposal.customerName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text(proposal.formattedDate)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Deal value and status
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(proposal.formattedTotal)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(proposal.formattedStatus)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor(for: proposal.formattedStatus))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding([.horizontal])
                    
                    if proposal != proposals.prefix(4).last {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // Conversion Metrics Grid
    private var conversionMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            // Average Deal Lifecycle
            metricCard(
                title: "Deal Lifecycle",
                value: "18 days",
                detail: "From draft to close",
                icon: "clock",
                iconColor: .purple,
                bgColor: cardBackgroundColor
            )
            
            // Win Rate
            metricCard(
                title: "Win Rate",
                value: "\(formatPercent(successRate))%",
                detail: "Closed deals",
                icon: "chart.bar.fill",
                iconColor: .green,
                bgColor: cardBackgroundColor
            )
            
            // Average Response Time
            metricCard(
                title: "Avg Response",
                value: "2.5 days",
                detail: "Customer response",
                icon: "timer",
                iconColor: .orange,
                bgColor: cardBackgroundColor
            )
        }
    }
    
    // Win/Loss Analysis Chart
    private var winLossAnalysisChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Win/Loss Analysis")
                .font(.headline)
                .padding([.horizontal])
            
            VStack(spacing: 15) {
                // Ratio visualization
                HStack(spacing: 0) {
                    // Prepare ratio data
                    let winRatioValue = calculateWinRatio()
                    let lossRatioValue = 1 - winRatioValue
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: UIScreen.main.bounds.width * 0.7 * CGFloat(winRatioValue), height: 30)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: UIScreen.main.bounds.width * 0.7 * CGFloat(lossRatioValue), height: 30)
                        .cornerRadius(4)
                }
                .padding([.horizontal])
                
                // Labels
                HStack {
                    Text("\(wonProposalsCount) Won")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("\(lostProposalsCount) Lost")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding([.horizontal])
                
                // Reason analysis (placeholder)
                if wonProposalsCount > 0 || lostProposalsCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Factors")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding([.horizontal])
                        
                        HStack(spacing: 15) {
                            winLossFactorView(factor: "Pricing", percentage: 40, isPositive: false)
                            winLossFactorView(factor: "Features", percentage: 65, isPositive: true)
                            winLossFactorView(factor: "Timing", percentage: 30, isPositive: false)
                        }
                        .padding([.horizontal])
                    }
                }
            }
            .padding(.vertical)
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Win/Loss Factor View
    private func winLossFactorView(factor: String, percentage: Int, isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(factor)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 5) {
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    // Tasks Overview Metrics
    private var tasksOverviewMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tasks Overview")
                .font(.headline)
                .padding([.horizontal])
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                let taskStatuses = prepareTaskStatusCounts()
                
                taskStatusMetric(status: "New", count: taskStatuses["New"] ?? 0, color: .blue)
                taskStatusMetric(status: "In Progress", count: taskStatuses["In Progress"] ?? 0, color: .orange)
                taskStatusMetric(status: "Completed", count: taskStatuses["Completed"] ?? 0, color: .green)
                taskStatusMetric(status: "Overdue", count: overdueTasks, color: .red)
            }
            .padding([.horizontal])
            
            // Weekly completion target
            WeeklyCompletionTargetView(completed: completedTasksCount, total: totalTasksCount)
                .padding([.horizontal])
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Weekly Completion Target View
    struct WeeklyCompletionTargetView: View {
        let completed: Int
        let total: Int
        
        var progress: Double {
            guard total > 0 else { return 0 }
            return Double(completed) / Double(total)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Completion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(completed)/\(total) Tasks")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(progress >= 0.6 ? .green : .orange)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(UIColor.tertiarySystemBackground))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(progress >= 0.6 ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    // Task Status Metric
    private func taskStatusMetric(status: String, count: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Task Priority Distribution Chart
    private var taskPriorityDistributionChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Priority Distribution")
                .font(.headline)
                .padding([.horizontal])
            
            HStack(spacing: 20) {
                // Simple pie layout instead of donut chart
                VStack {
                    ZStack {
                        let taskCounts = taskCountByPriority
                        let total = taskCounts.values.reduce(0, +)
                        
                        Text("\(total)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(70)
                }
                
                // Priority breakdown
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text("High Priority")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(taskCountByPriority["High"] ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                        
                        Text("Medium Priority")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(taskCountByPriority["Medium"] ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                        
                        Text("Low Priority")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(taskCountByPriority["Low"] ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Task Calendar View (simplified)
    private var taskCalendarView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Calendar")
                .font(.headline)
                .padding([.horizontal])
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<7) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                        
                        VStack(spacing: 8) {
                            // Day of week
                            Text(weekdayFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Date number
                            ZStack {
                                Circle()
                                    .fill(Calendar.current.isDateInToday(date) ? accentColor : Color.clear)
                                    .frame(width: 36, height: 36)
                                
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.subheadline)
                                    .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)
                                    .foregroundColor(Calendar.current.isDateInToday(date) ? .white : .primary)
                            }
                            
                            // Task indicator
                            let taskCount = getTaskCountForDate(date)
                            if taskCount > 0 {
                                Text("\(taskCount)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(hasOverdueTasksForDate(date) ? Color.red : Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text("0")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding([.horizontal])
            }
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Task Completion Trend Chart
    private var taskCompletionTrendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Completion Trend")
                .font(.headline)
                .padding([.horizontal])
            
            // This is a placeholder - in real app would have real chart
            HStack {
                Text("Chart placeholder - No chart available in this version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 200)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Financial Metrics Summary
    private var financialMetricsSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Financial Overview")
                .font(.headline)
                .padding([.horizontal])
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                // Total Revenue
                metricCard(
                    title: "Total Revenue",
                    value: "$\(formatValue(totalRevenue))",
                    detail: "All time",
                    icon: "dollarsign.circle.fill",
                    iconColor: accentColor,
                    bgColor: cardBackgroundColor
                )
                
                // Total Profit
                metricCard(
                    title: "Total Profit",
                    value: "$\(formatValue(totalProfit))",
                    detail: "All time",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    bgColor: cardBackgroundColor
                )
                
                // Average Margin
                metricCard(
                    title: "Average Margin",
                    value: "\(formatPercent(averageMargin))%",
                    detail: "All proposals",
                    icon: "percent",
                    iconColor: .purple,
                    bgColor: cardBackgroundColor
                )
                
                // Current Quarter
                metricCard(
                    title: "Current Quarter",
                    value: "$\(formatValue(currentQuarterRevenue))",
                    detail: "Q\(currentQuarter) \(currentYear)",
                    icon: "calendar",
                    iconColor: .orange,
                    bgColor: cardBackgroundColor
                )
            }
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Revenue Breakdown Chart
    private var revenueBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Revenue Breakdown")
                .font(.headline)
                .padding([.horizontal])
            
            // Simplified version - just text placeholder
            HStack {
                Text("Chart placeholder - No chart available in this version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 250)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Profit Margin Analysis Chart
    private var profitMarginAnalysisChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profit Margin Analysis")
                .font(.headline)
                .padding([.horizontal])
            
            // Simplified version - just text placeholder
            HStack {
                Text("Chart placeholder - No chart available in this version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 200)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Revenue by Customer Chart
    private var revenueByCustomerChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Revenue by Customer")
                .font(.headline)
                .padding([.horizontal])
            
            // Simplified version - just text placeholder
            HStack {
                Text("Chart placeholder - No chart available in this version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 200)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Performance Trends Chart
    private var performanceTrendsChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Performance Trends")
                .font(.headline)
                .padding([.horizontal])
            
            // Simplified version - just text placeholder
            HStack {
                Text("Chart placeholder - No chart available in this version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 250)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Forecast Projections Chart
    private var forecastProjectionsChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Future Projections")
                .font(.headline)
                .padding([.horizontal])
            
            // Simplified version - just text placeholder
            HStack {
                Text("Chart placeholder - No chart available in this version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 250)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Comparative Analysis Section
    private var comparativeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comparative Analysis")
                .font(.headline)
                .padding([.horizontal])
            
            // Time period comparison
            HStack(spacing: 20) {
                // Current period
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ComparisonMetricView(
                        title: "Revenue",
                        current: 15000,
                        previous: 12000,
                        format: { "$\(formatValue($0))" }
                    )
                    
                    ComparisonMetricView(
                        title: "Proposals",
                        current: 8,
                        previous: 5,
                        format: { "\($0)" }
                    )
                    
                    ComparisonMetricView(
                        title: "Win Rate",
                        current: 60,
                        previous: 40,
                        format: { "\($0)%" }
                    )
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // Yearly comparison
                VStack(alignment: .leading, spacing: 8) {
                    Text("Year-over-Year")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ComparisonMetricView(
                        title: "Revenue",
                        current: 50000,
                        previous: 35000,
                        format: { "$\(formatValue($0))" }
                    )
                    
                    ComparisonMetricView(
                        title: "Proposals",
                        current: 25,
                        previous: 18,
                        format: { "\($0)" }
                    )
                    
                    ComparisonMetricView(
                        title: "Avg Deal",
                        current: 6000,
                        previous: 5000,
                        format: { "$\(formatValue($0))" }
                    )
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Comparison Metric View
    struct ComparisonMetricView: View {
        let title: String
        let current: Double
        let previous: Double
        let format: (Double) -> String
        
        var percentChange: Double {
            guard previous > 0 else { return 0 }
            return ((current - previous) / previous) * 100
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(format(current))
                        .font(.headline)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: percentChange >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(percentChange >= 0 ? .green : .red)
                        
                        Text("\(String(format: "%.1f", abs(percentChange)))%")
                            .font(.caption)
                            .foregroundColor(percentChange >= 0 ? .green : .red)
                    }
                }
            }
        }
    }
    
    // Advanced Metrics Grid
    private var advancedMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Advanced Metrics")
                .font(.headline)
                .padding([.horizontal])
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                // Customer Acquisition Cost
                advancedMetricCard(
                    title: "Acquisition Cost",
                    value: "$1,250",
                    detail: "Per customer",
                    trend: "+5% from prev.",
                    trendUp: false
                )
                
                // Customer Lifetime Value
                advancedMetricCard(
                    title: "Lifetime Value",
                    value: "$42,500",
                    detail: "Average",
                    trend: "+12% from prev.",
                    trendUp: true
                )
                
                // Cost of Sales
                advancedMetricCard(
                    title: "Cost of Sales",
                    value: "8.5%",
                    detail: "Of revenue",
                    trend: "-2.1% from prev.",
                    trendUp: true
                )
                
                // Sales Cycle Length
                advancedMetricCard(
                    title: "Sales Cycle",
                    value: "32 days",
                    detail: "Average",
                    trend: "-4 days from prev.",
                    trendUp: true
                )
                
                // Renewal Rate
                advancedMetricCard(
                    title: "Renewal Rate",
                    value: "85%",
                    detail: "Annual",
                    trend: "+3% from prev.",
                    trendUp: true
                )
                
                // Upsell Rate
                advancedMetricCard(
                    title: "Upsell Rate",
                    value: "24%",
                    detail: "Existing customers",
                    trend: "+5% from prev.",
                    trendUp: true
                )
            }
            .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Advanced Metric Card
    private func advancedMetricCard(title: String, value: String, detail: String, trend: String, trendUp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: trendUp ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                    .foregroundColor(trendUp ? .green : .red)
                
                Text(trend)
                    .font(.caption2)
                    .foregroundColor(trendUp ? .green : .red)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Data Insights List
    private var dataInsightsList: some View {
        VStack(spacing: 12) {
            insightRow(
                title: "Revenue Acceleration",
                description: "Revenue growth is accelerating by 15% quarter-over-quarter",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            insightRow(
                title: "Proposal Optimization",
                description: "Proposals with engineering services have 18% higher win rates",
                icon: "lightbulb.fill",
                color: .yellow
            )
            
            insightRow(
                title: "Customer Concentration",
                description: "Top 3 customers represent 45% of your revenue - consider diversification",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
            
            insightRow(
                title: "Task Efficiency",
                description: "Task completion efficiency increased by 22% in the last month",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
        .padding()
    }
    
    // Insight Row
    private func insightRow(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    // MARK: - Helper Components
    
    private func metricCard(title: String, value: String, detail: String, icon: String, iconColor: Color, bgColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        .cornerRadius(12)
    }
    
    // Task row for upcoming task list
    private func upcomingTaskRow(task: Task) -> some View {
        HStack {
            Circle()
                .fill(task.priorityColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let dueDate = task.dueDate {
                    Text(dateFormatter.string(from: dueDate))
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Data Helper Methods
    
    // Format values for display
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Draft": return .gray
        case "Pending": return .orange
        case "Sent": return .blue
        case "Won": return .green
        case "Lost": return .red
        case "Expired": return .purple
        default: return .gray
        }
    }
    
    private var accentColor: Color {
        switch colorScheme {
        case "Blue": return .blue
        case "Green": return .green
        case "Purple": return .purple
        case "Dark": return .indigo
        default: return .blue
        }
    }
    
    private var cardBackgroundColor: Color {
        return Color(UIColor.systemGray6)
    }
    
    // Compute active proposals
    private var activeProposalsCount: Int {
        var count = 0
        for proposal in proposals {
            if let status = proposal.status, status != "Won" && status != "Lost" {
                count += 1
            }
        }
        return count
    }
    
    private var activeProposalsValue: Double {
        var total = 0.0
        for proposal in proposals {
            if let status = proposal.status, status != "Won" && status != "Lost" {
                total += proposal.totalAmount
            }
        }
        return total
    }
    
    // Compute overdue tasks
    private var overdueTasks: Int {
        var count = 0
        for task in pendingTasks {
            if task.isOverdue {
                count += 1
            }
        }
        return count
    }
    
    // Task status counts
    private func prepareTaskStatusCounts() -> [String: Int] {
        var counts: [String: Int] = [
            "New": 0,
            "In Progress": 0,
            "Completed": 0,
            "Deferred": 0
        ]
        
        // Safer approach to fetch all tasks
        let fetchRequest = NSFetchRequest<Task>(entityName: "Task")
        
        do {
            let allTasks = try viewContext.fetch(fetchRequest)
            for task in allTasks {
                if let status = task.status {
                    counts[status, default: 0] += 1
                }
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
        
        return counts
    }
    
    // Task priority counts
    private var taskCountByPriority: [String: Int] {
        var counts: [String: Int] = [
            "High": 0,
            "Medium": 0,
            "Low": 0
        ]
        
        let fetchRequest = NSFetchRequest<Task>(entityName: "Task")
        
        do {
            let allTasks = try viewContext.fetch(fetchRequest)
            for task in allTasks {
                if let priority = task.priority {
                    counts[priority, default: 0] += 1
                }
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
        
        return counts
    }
    
    private var completedTasksCount: Int {
        let counts = prepareTaskStatusCounts()
        return counts["Completed"] ?? 0
    }
    
    private var totalTasksCount: Int {
        let counts = prepareTaskStatusCounts()
        let total = counts.values.reduce(0, +)
        return total > 0 ? total : 1 // Avoid division by zero
    }
    
    private var completedTasksRatio: Double {
        return Double(completedTasksCount) / Double(totalTasksCount)
    }
    
    // Proposal statistics
    private var wonProposalsCount: Int {
        var count = 0
        for proposal in proposals {
            if proposal.status == "Won" {
                count += 1
            }
        }
        return count
    }
    
    private var lostProposalsCount: Int {
        var count = 0
        for proposal in proposals {
            if proposal.status == "Lost" {
                count += 1
            }
        }
        return count
    }
    
    private var closedProposalsCount: Int {
        return wonProposalsCount + lostProposalsCount
    }
    
    private var successRate: Double {
        if closedProposalsCount == 0 {
            return 0
        }
        return Double(wonProposalsCount) / Double(closedProposalsCount) * 100
    }
    
    private func calculateWinRatio() -> Double {
        if closedProposalsCount == 0 {
            return 0.5 // Default to 50/50 when no data
        }
        return Double(wonProposalsCount) / Double(closedProposalsCount)
    }
    
    private var avgDealSize: Double {
        var totalAmount = 0.0
        var count = 0
        
        for proposal in proposals {
            if proposal.status == "Won" {
                totalAmount += proposal.totalAmount
                count += 1
            }
        }
        
        if count == 0 {
            return 0
        }
        
        return totalAmount / Double(count)
    }
    
    // Proposal status value data
    private var proposalValueByStatus: [String: Double] {
        var values: [String: Double] = [:]
        
        for proposal in proposals {
            if let status = proposal.status {
                values[status, default: 0] += proposal.totalAmount
            }
        }
        
        return values
    }
    
    // Proposal status count data
    private var proposalCountByStatus: [String: Int] {
        var counts: [String: Int] = [:]
        
        for proposal in proposals {
            if let status = proposal.status {
                counts[status, default: 0] += 1
            }
        }
        
        return counts
    }
    
    // Calculate conversion rate between pipeline stages
    private func calculateConversionRate(from startStage: String, to endStage: String) -> Double {
        let startCount = Double(proposalCountByStatus[startStage] ?? 0)
        let endCount = Double(proposalCountByStatus[endStage] ?? 0)
        
        if startCount == 0 {
            return 0
        }
        
        return min((endCount / startCount) * 100, 100) // Cap at 100%
    }
    
    // MARK: - Financial Metrics
    
    private var totalRevenue: Double {
        return proposals.filter { $0.status == "Won" }.reduce(0) { $0 + $1.totalAmount }
    }
    
    private var totalProfit: Double {
        return proposals.filter { $0.status == "Won" }.reduce(0) { $0 + $1.grossProfit }
    }
    
    private var averageMargin: Double {
        let wonProposalsWithRevenue = proposals.filter { $0.status == "Won" && $0.totalAmount > 0 }
        
        if wonProposalsWithRevenue.isEmpty {
            return 0
        }
        
        let totalMargin = wonProposalsWithRevenue.reduce(0.0) { $0 + $1.profitMargin }
        return totalMargin / Double(wonProposalsWithRevenue.count)
    }
    
    private var currentQuarter: Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        return ((month - 1) / 3) + 1
    }
    
    private var currentYear: Int {
        return Calendar.current.component(.year, from: Date())
    }
    
    private var currentQuarterRevenue: Double {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        // Calculate the start and end of the current quarter
        let quarterStartMonth = (month - 1) / 3 * 3 + 1
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = quarterStartMonth
        startComponents.day = 1
        
        guard let startDate = calendar.date(from: startComponents) else { return 0 }
        
        // Filter proposals within the current quarter
        return proposals
            .filter { proposal in
                guard let date = proposal.creationDate, proposal.status == "Won" else { return false }
                return date >= startDate && date <= now
            }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    // MARK: - Monthly Revenue Data
    
    private struct MonthlyData {
        let month: String
        let revenue: Double
    }
    
    private func prepareMonthlyRevenueData() -> [MonthlyData] {
        // Generate monthly data based on selected time period
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyData] = []
        
        // Determine number of months to display
        let monthsToShow: Int
        switch selectedTimePeriod {
        case "1 Month": monthsToShow = 4  // Show 4 weeks
        case "3 Months": monthsToShow = 3
        case "6 Months": monthsToShow = 6
        case "1 Year": monthsToShow = 12
        default: monthsToShow = 6
        }
        
        // Generate the monthly labels and calculate revenue
        for i in 0..<monthsToShow {
            if let date = calendar.date(byAdding: .month, value: -(monthsToShow - 1 - i), to: now) {
                let month = getMonthString(from: date)
                let revenue = calculateRevenueForMonth(date)
                
                result.append(MonthlyData(month: month, revenue: revenue))
            }
        }
        
        return result
    }
    
    private func getMonthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func calculateRevenueForMonth(_ month: Date) -> Double {
        let calendar = Calendar.current
        
        var monthlyRevenue = 0.0
        for proposal in proposals {
            if proposal.status == "Won",
               let creationDate = proposal.creationDate,
               calendar.isDate(creationDate, equalTo: month, toGranularity: .month) {
                monthlyRevenue += proposal.totalAmount
            }
        }
        
        return monthlyRevenue
    }
    
    private func calculateAverageMonthlyRevenue(from data: [MonthlyData]) -> Double {
        if data.isEmpty {
            return 0
        }
        
        let totalRevenue = data.reduce(0) { $0 + $1.revenue }
        return totalRevenue / Double(data.count)
    }
    
    // MARK: - Task Calendar Helpers
    
    private func getTaskCountForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return pendingTasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }.count
    }
    
    private func hasOverdueTasksForDate(_ date: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // If the date is in the past, check for overdue tasks
        if date < now && calendar.isDate(date, inSameDayAs: now) == false {
            return pendingTasks.contains { task in
                if let dueDate = task.dueDate {
                    return calendar.isDate(dueDate, inSameDayAs: date) && dueDate < now
                }
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Recent Activities
    
    private func fetchRecentActivities() -> [Activity] {
        let fetchRequest = NSFetchRequest<Activity>(entityName: "Activity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.timestamp, ascending: false)]
        fetchRequest.fetchLimit = 3
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching recent activities: \(error)")
            return []
        }
    }
    
    // MARK: - Formatters
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var timeAgoFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

// Preview provider
struct EnhancedDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EnhancedDashboardView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
