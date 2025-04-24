import SwiftUI
import Charts
import CoreData

// MARK: - Main Dashboard View
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
    
    // MARK: - Main View Body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Dashboard header with tabs
                VStack(spacing: 0) {
                    // Main header with title and actions
                    dashboardHeader
                    
                    // Tab selector
                    // Tab Selection Code Fix

                    // In the EnhancedDashboardView struct, replace the tab selector code with this:
                                        
                    // Tab selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(dashboardTabs, id: \.self) { tab in
                                Button(action: {
                                    withAnimation {
                                        selectedTab = tab
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tab)
                                            .font(.headline)
                                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                                    }
                                    .frame(height: 44)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        VStack {
                                            Spacer()
                                            if selectedTab == tab {
                                                Rectangle()
                                                    .fill(Color.blue)
                                                    .frame(height: 3)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
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
                        selectedTabContent
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .frame(width: geometry.size.width)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: - Tab Content Selection
    // For the "Generic parameter 'V' could not be inferred" error,
    // Update the selectedTabContent computed property to:

    private var selectedTabContent: some View {
        Group {
            switch selectedTab {
            case "Overview":
                OverviewTabContent(
                    proposals: proposals,
                    pendingTasks: pendingTasks,
                    selectedTimePeriod: $selectedTimePeriod,
                    showInsights: $showInsights,
                    accentColor: accentColor,
                    cardBackgroundColor: cardBackgroundColor
                )
            case "Sales":
                SalesTabContent(
                    proposals: proposals,
                    accentColor: accentColor,
                    cardBackgroundColor: cardBackgroundColor
                )
            case "Tasks":
                TasksTabContent(
                    pendingTasks: pendingTasks,
                    accentColor: accentColor,
                    cardBackgroundColor: cardBackgroundColor
                )
            case "Financial":
                FinancialTabContent(
                    proposals: proposals,
                    selectedTimePeriod: $selectedTimePeriod,
                    accentColor: accentColor,
                    cardBackgroundColor: cardBackgroundColor
                )
            case "Analytics":
                AnalyticsTabContent(
                    accentColor: accentColor,
                    cardBackgroundColor: cardBackgroundColor
                )
            default:
                Text("Select a tab")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
    
    // MARK: - Theme Color Helpers
    var accentColor: Color {
        switch colorScheme {
        case "Blue": return .blue
        case "Green": return .green
        case "Purple": return .purple
        case "Dark": return .indigo
        default: return .blue
        }
    }
    
    var cardBackgroundColor: Color {
        return Color(UIColor.systemGray6)
    }
}


// MARK: - Overview Tab Content
struct OverviewTabContent: View {
    let proposals: FetchedResults<Proposal>
    let pendingTasks: FetchedResults<Task>
    @Binding var selectedTimePeriod: String
    @Binding var showInsights: Bool
    let accentColor: Color
    let cardBackgroundColor: Color
    
    // Computed properties for the overview tab
    private var activeProposalsCount: Int {
        proposals.filter { $0.status != "Won" && $0.status != "Lost" }.count
    }
    
    private var activeProposalsValue: Double {
        proposals
            .filter { $0.status != "Won" && $0.status != "Lost" }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    private var overdueTasks: Int {
        pendingTasks.filter { $0.isOverdue }.count
    }
    
    private var wonProposalsCount: Int {
        proposals.filter { $0.status == "Won" }.count
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
        VStack(spacing: 20) {
            // Key metrics cards
            keyMetricsGrid
            
            // Sales performance chart
            salesPerformanceSection
            
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
            toggleInsightsButton
        }
    }
    
    // MARK: - Key Metrics Grid
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            // Pending Tasks Card
            MetricCardView(
                title: "Pending Tasks",
                value: "\(pendingTasks.count)",
                detail: "\(overdueTasks) overdue",
                icon: "checklist",
                iconColor: overdueTasks > 0 ? .red : .orange,
                bgColor: cardBackgroundColor
            )
            
            // Success Rate Card
            MetricCardView(
                title: "Success Rate",
                value: "\(formatPercent(successRate))%",
                detail: "\(wonProposalsCount) won proposals",
                icon: "chart.xyaxis.line",
                iconColor: .green,
                bgColor: cardBackgroundColor
            )
            
            // Active Proposals Card
            MetricCardView(
                title: "Active Proposals",
                value: "\(activeProposalsCount)",
                detail: "$\(formatValue(activeProposalsValue))",
                icon: "doc.text.fill",
                iconColor: accentColor,
                bgColor: cardBackgroundColor
            )
            
            // Avg Deal Card
            MetricCardView(
                title: "Avg Deal Size",
                value: "$\(formatValue(calculateAvgDealSize()))",
                detail: "\(calculateClosedProposalsCount()) closed deals",
                icon: "dollarsign.circle",
                iconColor: .purple,
                bgColor: cardBackgroundColor
            )
        }
    }
    
    // MARK: - Sales Performance Section
    private var salesPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sales Performance")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Period", selection: $selectedTimePeriod) {
                    ForEach(["1 Month", "3 Months", "6 Months", "1 Year", "All"], id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
            }
            .padding([.horizontal])
            
            SalesPerformanceChartView(
                proposals: proposals,
                selectedTimePeriod: selectedTimePeriod,
                accentColor: accentColor
            )
            .frame(height: 220)
            .padding([.horizontal, .bottom])
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Proposals Section
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
                        RecentProposalRowView(proposal: proposal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Activity Feed
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
                        ActivityRowItemView(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Insights & Recommendations")
                .font(.headline)
                .padding([.horizontal])
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    InsightCardView(
                        title: "Follow-up Required",
                        description: "2 proposals have been open for more than 30 days",
                        icon: "bell.badge",
                        color: .orange
                    )
                    
                    InsightCardView(
                        title: "Overdue Tasks",
                        description: "Schedule time to complete \(overdueTasks) overdue tasks",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                    
                    InsightCardView(
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
    
    // MARK: - Toggle Insights Button
    private var toggleInsightsButton: some View {
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
    
    // MARK: - Helper Methods
    
    private func fetchRecentActivities() -> [Activity] {
        let fetchRequest = NSFetchRequest<Activity>(entityName: "Activity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.timestamp, ascending: false)]
        fetchRequest.fetchLimit = 3
        
        do {
            let viewContext = proposals.first?.managedObjectContext ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching recent activities: \(error)")
            return []
        }
    }
    
    private func calculateAvgDealSize() -> Double {
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
    
    private func calculateClosedProposalsCount() -> Int {
        let wonCount = proposals.filter { $0.status == "Won" }.count
        let lostCount = proposals.filter { $0.status == "Lost" }.count
        return wonCount + lostCount
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
}

// MARK: - Activity Row Item View
struct ActivityRowItemView: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.typeColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.desc ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let timestamp = activity.timestamp {
                    Text(timeAgoString(from: timestamp))
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
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Recent Proposal Row View
struct RecentProposalRowView: View {
    @ObservedObject var proposal: Proposal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(proposal.number ?? "New Proposal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(proposal.customer?.name ?? "No Customer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let date = proposal.creationDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(proposal.totalAmount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(proposal.status ?? "Draft")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(for: proposal.status ?? "Draft"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
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
}

// MARK: - Insight Card View
struct InsightCardView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
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
}

// MARK: - Metric Card View
struct MetricCardView: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let iconColor: Color
    let bgColor: Color
    
    var body: some View {
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
}


// MARK: - Sales Performance Chart View
struct SalesPerformanceChartView: View {
    let proposals: FetchedResults<Proposal>
    let selectedTimePeriod: String
    let accentColor: Color
    
    // Data structure for monthly data
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: String
        let revenue: Double
    }
    
    var body: some View {
        // Generate combined chart with revenue and deals
        let monthlyData = prepareMonthlyRevenueData()
        let avgRevenue = calculateAverageMonthlyRevenue(from: monthlyData)

        // Using a simple Chart implementation without all the complex marks
        Chart {
            // Bar marks for monthly revenue
            ForEach(monthlyData) { dataPoint in
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Revenue", dataPoint.revenue)
                )
                .foregroundStyle(accentColor)
                .cornerRadius(4)
            }
            
            // Simple line for trend
            LineMark(
                x: .value("Month", monthlyData[0].month),
                y: .value("Trend", monthlyData[0].revenue)
            )
            .foregroundStyle(Color.orange)
            
            // Add remaining points to continue the line
            ForEach(monthlyData.dropFirst()) { dataPoint in
                LineMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Trend", dataPoint.revenue)
                )
                .foregroundStyle(Color.orange)
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
    
    // MARK: - Chart Data Preparation
    
    // Prepare monthly revenue data
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
    
    // Get month string from date
    private func getMonthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    // Calculate revenue for a specific month
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
    
    // Calculate average monthly revenue from data points
    private func calculateAverageMonthlyRevenue(from data: [MonthlyData]) -> Double {
        if data.isEmpty {
            return 0
        }
        
        let totalRevenue = data.reduce(0) { $0 + $1.revenue }
        return totalRevenue / Double(data.count)
    }
    
    // Format values for display
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}


// MARK: - Sales Tab Content
struct SalesTabContent: View {
    let proposals: FetchedResults<Proposal>
    let accentColor: Color
    let cardBackgroundColor: Color
    
    // Computed properties for pipeline data
    private var proposalValueByStatus: [String: Double] {
        var values: [String: Double] = [:]
        
        for proposal in proposals {
            if let status = proposal.status {
                values[status, default: 0] += proposal.totalAmount
            }
        }
        
        return values
    }
    
    private var proposalCountByStatus: [String: Int] {
        var counts: [String: Int] = [:]
        
        for proposal in proposals {
            if let status = proposal.status {
                counts[status, default: 0] += 1
            }
        }
        
        return counts
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Pipeline overview section
            salesPipelineOverview
            
            // Pipeline stages visualization
            pipelineStagesView
            
            // Recent and upcoming deals
            dealsTimelineSection
            
            // Conversion metrics
            conversionMetricsGrid
            
            // Win/loss analysis chart
            winLossAnalysisChart
        }
    }
    
    // MARK: - Sales Pipeline Overview
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
    
    // MARK: - Pipeline Stage Card
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
    
    // MARK: - Pipeline Stages View
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
                    
                    pipelineStageItem(stage: stage, count: stageCount, value: stageValue)
                    
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
    
    // Individual pipeline stage item
    private func pipelineStageItem(stage: String, count: Int, value: Double) -> some View {
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
                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text("$\(formatValue(value))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Deals Timeline Section
    private var dealsTimelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent & Upcoming Deals")
                .font(.headline)
                .padding([.horizontal])
            
            dealsTimelineView
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Deals Timeline View
    private var dealsTimelineView: some View {
        VStack(spacing: 0) {
            if proposals.isEmpty {
                Text("No deals to display")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                // Show only first 4 proposals for performance
                ForEach(Array(proposals.prefix(4)), id: \.self) { proposal in
                    dealTimelineItem(proposal: proposal)
                    
                    if proposal != proposals.prefix(4).last {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // Individual deal timeline item
    private func dealTimelineItem(proposal: Proposal) -> some View {
        HStack(spacing: 15) {
            // Date indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor(for: proposal.status ?? "Draft"))
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
                Text(proposal.number ?? "New Proposal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(proposal.customer?.name ?? "No Customer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                if let date = proposal.creationDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Deal value and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(proposal.totalAmount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(proposal.status ?? "Draft")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(for: proposal.status ?? "Draft"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 10)
        .padding([.horizontal])
    }
    
    // MARK: - Conversion Metrics Grid
    private var conversionMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            // Average Deal Lifecycle
            MetricCardView(
                title: "Deal Lifecycle",
                value: "18 days",
                detail: "From draft to close",
                icon: "clock",
                iconColor: .purple,
                bgColor: cardBackgroundColor
            )
            
            // Win Rate
            MetricCardView(
                title: "Win Rate",
                value: "\(formatPercent(calculateSuccessRate()))%",
                detail: "Closed deals",
                icon: "chart.bar.fill",
                iconColor: .green,
                bgColor: cardBackgroundColor
            )
            
            // Average Response Time
            MetricCardView(
                title: "Avg Response",
                value: "2.5 days",
                detail: "Customer response",
                icon: "timer",
                iconColor: .orange,
                bgColor: cardBackgroundColor
            )
        }
    }
    
    // MARK: - Win/Loss Analysis Chart
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
                    
                    winLossRatioBar(winRatio: winRatioValue, lossRatio: lossRatioValue)
                }
                .padding([.horizontal])
                
                // Labels
                HStack {
                    Text("\(calculateWonProposalsCount()) Won")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("\(calculateLostProposalsCount()) Lost")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding([.horizontal])
                
                // Reason analysis (placeholder)
                if calculateWonProposalsCount() > 0 || calculateLostProposalsCount() > 0 {
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
    
    // Win/Loss ratio visualization
    private func winLossRatioBar(winRatio: Double, lossRatio: Double) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * CGFloat(winRatio), height: 30)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: geometry.size.width * CGFloat(lossRatio), height: 30)
                    .cornerRadius(4)
            }
        }
        .frame(height: 30)
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
    
    // MARK: - Helper Methods
    
    // Calculate conversion rate between pipeline stages
    private func calculateConversionRate(from startStage: String, to endStage: String) -> Double {
        let startCount = Double(proposalCountByStatus[startStage] ?? 0)
        let endCount = Double(proposalCountByStatus[endStage] ?? 0)
        
        if startCount == 0 {
            return 0
        }
        
        return min((endCount / startCount) * 100, 100) // Cap at 100%
    }
    
    private func calculateWonProposalsCount() -> Int {
        return proposals.filter { $0.status == "Won" }.count
    }
    
    private func calculateLostProposalsCount() -> Int {
        return proposals.filter { $0.status == "Lost" }.count
    }
    
    private func calculateClosedProposalsCount() -> Int {
        return calculateWonProposalsCount() + calculateLostProposalsCount()
    }
    
    private func calculateSuccessRate() -> Double {
        let closed = calculateClosedProposalsCount()
        if closed == 0 {
            return 0
        }
        return Double(calculateWonProposalsCount()) / Double(closed) * 100
    }
    
    private func calculateWinRatio() -> Double {
        let closed = calculateClosedProposalsCount()
        if closed == 0 {
            return 0.5 // Default to 50/50 when no data
        }
        return Double(calculateWonProposalsCount()) / Double(closed)
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
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Conversion Indicator
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

// Add these structures to your EnhancedDashboardView.swift file

// MARK: - Tasks Tab Content
struct TasksTabContent: View {
    let pendingTasks: FetchedResults<Task>
    let accentColor: Color
    let cardBackgroundColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Tasks overview metrics
            tasksOverviewMetrics
            
            // Placeholder for Task priority distribution
            placeholderCard(title: "Task Priority Distribution")
            
            // Placeholder for Task calendar view
            placeholderCard(title: "Task Calendar")
            
            // Placeholder for Task completion trend
            placeholderCard(title: "Task Completion Trend")
            
            // Upcoming tasks section
            upcomingTasksSection
        }
    }
    
    // Tasks Overview Metrics
    private var tasksOverviewMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tasks Overview")
                .font(.headline)
                .padding([.horizontal])
            
            Text("Tasks statistics would appear here")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Upcoming Tasks Section
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Tasks")
                .font(.headline)
                .padding([.horizontal])
            
            if pendingTasks.isEmpty {
                Text("No upcoming tasks")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding([.horizontal])
            } else {
                ForEach(Array(pendingTasks.prefix(3)), id: \.self) { task in
                    upcomingTaskRow(task: task)
                }
                .padding([.horizontal])
            }
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
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
                    Text(formatDate(dueDate))
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
    
    // Helper method for date formatting
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Placeholder for chart sections
    private func placeholderCard(title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding([.horizontal])
            
            Text("Chart visualization would appear here")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Financial Tab Content
struct FinancialTabContent: View {
    let proposals: FetchedResults<Proposal>
    @Binding var selectedTimePeriod: String
    let accentColor: Color
    let cardBackgroundColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Financial metrics summary
            financialMetricsSummary
            
            // Revenue breakdown chart
            placeholderChart(title: "Revenue Breakdown")
            
            // Profit margin analysis
            placeholderChart(title: "Profit Margin Analysis")
            
            // Monthly revenue trend
            monthlyRevenueSection
            
            // Revenue by customer
            placeholderChart(title: "Revenue by Customer")
        }
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
                MetricCardView(
                    title: "Total Revenue",
                    value: "$\(formatValue(calculateTotalRevenue()))",
                    detail: "All time",
                    icon: "dollarsign.circle.fill",
                    iconColor: accentColor,
                    bgColor: cardBackgroundColor
                )
                
                // Total Profit
                MetricCardView(
                    title: "Total Profit",
                    value: "$\(formatValue(calculateTotalProfit()))",
                    detail: "All time",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    bgColor: cardBackgroundColor
                )
                
                // Average Margin
                MetricCardView(
                    title: "Average Margin",
                    value: "\(formatPercent(calculateAverageMargin()))%",
                    detail: "All proposals",
                    icon: "percent",
                    iconColor: .purple,
                    bgColor: cardBackgroundColor
                )
                
                // Current Quarter
                MetricCardView(
                    title: "Current Quarter",
                    value: "$\(formatValue(calculateCurrentQuarterRevenue()))",
                    detail: "Q\(getCurrentQuarter()) \(getCurrentYear())",
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
    
    // Monthly Revenue Section
    private var monthlyRevenueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Monthly Revenue")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Period", selection: $selectedTimePeriod) {
                    ForEach(["1 Month", "3 Months", "6 Months", "1 Year", "All"], id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
            }
            .padding([.horizontal])
            
            Text("Monthly revenue chart would appear here")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal, .bottom])
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Placeholder for chart sections
    private func placeholderChart(title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding([.horizontal])
            
            Text("Chart visualization would appear here")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods for Financial Calculations
    
    private func calculateTotalRevenue() -> Double {
        return proposals.filter { $0.status == "Won" }.reduce(0) { $0 + $1.totalAmount }
    }
    
    private func calculateTotalProfit() -> Double {
        return proposals.filter { $0.status == "Won" }.reduce(0) { $0 + $1.grossProfit }
    }
    
    private func calculateAverageMargin() -> Double {
        let wonProposalsWithRevenue = proposals.filter { $0.status == "Won" && $0.totalAmount > 0 }
        
        if wonProposalsWithRevenue.isEmpty {
            return 0
        }
        
        let totalMargin = wonProposalsWithRevenue.reduce(0.0) { $0 + $1.profitMargin }
        return totalMargin / Double(wonProposalsWithRevenue.count)
    }
    
    private func getCurrentQuarter() -> Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        return ((month - 1) / 3) + 1
    }
    
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
    
    private func calculateCurrentQuarterRevenue() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        // Calculate the start of the current quarter
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
    
    // Formatting helpers
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
}

// MARK: - Analytics Tab Content
struct AnalyticsTabContent: View {
    let accentColor: Color
    let cardBackgroundColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Performance trends
            placeholderChart(title: "Performance Trends")
            
            // Forecast projections
            placeholderChart(title: "Future Projections")
            
            // Comparative analysis
            placeholderSection(title: "Comparative Analysis")
            
            // Advanced metrics grid
            placeholderSection(title: "Advanced Metrics")
            
            // Data insights section
            placeholderSection(title: "Data Insights")
        }
    }
    
    // Placeholder for chart sections
    private func placeholderChart(title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding([.horizontal])
            
            Text("Advanced chart visualization would appear here")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 250)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // Placeholder for other sections
    private func placeholderSection(title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding([.horizontal])
            
            Text("This section would contain advanced analytics data")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal])
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
}
