//
//  ProposalAnalyticsChartView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


import SwiftUI
import Charts

struct ProposalAnalyticsChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Proposal.creationDate, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<Proposal>
    
    @State private var selectedTimePeriod = "3 Months"
    let timePeriods = ["1 Month", "3 Months", "6 Months", "1 Year", "All Time"]
    
    @State private var selectedChartType = "Value"
    let chartTypes = ["Value", "Count", "Pipeline", "Trend"]
    
    @State private var highlightedStatus: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart header with controls
            HStack {
                Text("Proposal Analytics")
                    .font(.headline)
                
                Spacer()
                
                Picker("Chart Type", selection: $selectedChartType) {
                    ForEach(chartTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
            }
            
            HStack {
                Text("Show data for:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Time Period", selection: $selectedTimePeriod) {
                    ForEach(timePeriods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Text("\(filteredProposals.count) proposals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Different chart views based on selection
            Group {
                switch selectedChartType {
                case "Value":
                    proposalValueChart
                case "Count":
                    proposalCountChart
                case "Pipeline":
                    proposalPipelineChart
                case "Trend":
                    proposalTrendChart
                default:
                    proposalValueChart
                }
            }
            .frame(height: 250)
            
            // Legend
            HStack(spacing: 16) {
                ForEach(statusList, id: \.self) { status in
                    Button(action: {
                        withAnimation {
                            if highlightedStatus == status {
                                highlightedStatus = nil
                            } else {
                                highlightedStatus = status
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor(for: status))
                                .frame(width: 16, height: 16)
                            
                            Text(status)
                                .font(.caption)
                                .foregroundColor(highlightedStatus == status ? .primary : .secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(highlightedStatus == status ? Color(UIColor.tertiarySystemBackground) : Color.clear)
                        .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                // Total value
                VStack(alignment: .trailing) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(Int(totalProposalValue))")
                        .font(.headline)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Chart Views
    
    private var proposalValueChart: some View {
        Chart {
            ForEach(statusList, id: \.self) { status in
                BarMark(
                    x: .value("Status", status),
                    y: .value("Value", proposalValueByStatus[status] ?? 0)
                )
                .foregroundStyle(statusColor(for: status))
                .opacity(highlightedStatus == nil || highlightedStatus == status ? 1 : 0.3)
                .annotation(position: .top) {
                    if proposalValueByStatus[status] ?? 0 > 0 {
                        Text("$\(Int(proposalValueByStatus[status] ?? 0))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var proposalCountChart: some View {
        Chart {
            ForEach(statusList, id: \.self) { status in
                BarMark(
                    x: .value("Status", status),
                    y: .value("Count", proposalCountByStatus[status] ?? 0)
                )
                .foregroundStyle(statusColor(for: status))
                .opacity(highlightedStatus == nil || highlightedStatus == status ? 1 : 0.3)
                .annotation(position: .top) {
                    if proposalCountByStatus[status] ?? 0 > 0 {
                        Text("\(proposalCountByStatus[status] ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var proposalPipelineChart: some View {
        Chart {
            ForEach(pipelineStages, id: \.stage) { data in
                BarMark(
                    x: .value("Stage", data.stage),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [statusColor(for: data.stage).opacity(0.7), statusColor(for: data.stage)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .opacity(highlightedStatus == nil || highlightedStatus == data.stage ? 1 : 0.3)
                .annotation(position: .top) {
                    VStack(spacing: 2) {
                        Text("$\(Int(data.value))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(data.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Add conversion rate lines
            if pipelineStages.count > 1 {
                ForEach(0..<pipelineStages.count-1, id: \.self) { index in
                    let startStage = pipelineStages[index]
                    let endStage = pipelineStages[index+1]
                    let conversionRate = calculateConversionRate(from: startStage.stage, to: endStage.stage)
                    
                    LineMark(
                        x: .value("Stage", startStage.stage),
                        y: .value("Value", startStage.value * 0.8)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.white.opacity(0.6))
                    
                    LineMark(
                        x: .value("Stage", endStage.stage),
                        y: .value("Value", startStage.value * 0.8)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.white.opacity(0.6))
                    
                    PointMark(
                        x: .value("Stage", midpointBetween(startStage.stage, endStage.stage)),
                        y: .value("Value", startStage.value * 0.8)
                    )
                    .annotation(position: .top) {
                        Text("\(Int(conversionRate))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
    
    private var proposalTrendChart: some View {
        Chart {
            ForEach(monthlyProposalData, id: \.month) { data in
                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .blue.opacity(0.5)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Value", data.value)
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Month", data.month),
                    y: .value("Value", data.value)
                )
                .symbolSize(60)
                .foregroundStyle(.blue)
            }
            
            // Average line
            RuleMark(
                y: .value("Average", averageMonthlyValue)
            )
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .foregroundStyle(.green)
            .annotation(position: .trailing) {
                Text("Avg: $\(Int(averageMonthlyValue))")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
    
    private func midpointBetween(_ stage1: String, _ stage2: String) -> String {
        // This is a visual hack to position annotations between bars
        return stage1 + "→" + stage2
    }
    
    private func calculateConversionRate(from startStage: String, to endStage: String) -> Double {
        let startCount = Double(proposalCountByStatus[startStage] ?? 0)
        let endCount = Double(proposalCountByStatus[endStage] ?? 0)
        
        if startCount == 0 {
            return 0
        }
        
        return (endCount / startCount) * 100
    }
    
    // MARK: - Computed Properties
    
    private var filteredProposals: [Proposal] {
        let cutoffDate: Date?
        
        switch selectedTimePeriod {
        case "1 Month":
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        case "3 Months":
            cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        case "6 Months":
            cutoffDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())
        case "1 Year":
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        default:
            cutoffDate = nil
        }
        
        if let cutoff = cutoffDate {
            return proposals.filter { proposal in
                guard let creationDate = proposal.creationDate else { return false }
                return creationDate >= cutoff
            }
        } else {
            return Array(proposals)
        }
    }
    
    private var statusList: [String] {
        ["Draft", "Pending", "Sent", "Won", "Lost"]
    }
    
    private var proposalCountByStatus: [String: Int] {
        var counts: [String: Int] = [:]
        
        for proposal in filteredProposals {
            if let status = proposal.status {
                counts[status, default: 0] += 1
            }
        }
        
        return counts
    }
    
    private var proposalValueByStatus: [String: Double] {
        var values: [String: Double] = [:]
        
        for proposal in filteredProposals {
            if let status = proposal.status {
                values[status, default: 0] += proposal.totalAmount
            }
        }
        
        return values
    }
    
    private var totalProposalValue: Double {
        filteredProposals.reduce(0) { $0 + $1.totalAmount }
    }
    
    // MARK: - Pipeline Data
    
    private struct PipelineStage {
        let stage: String
        let value: Double
        let count: Int
    }
    
    private var pipelineStages: [PipelineStage] {
        // Only include active pipeline stages
        let stages = ["Draft", "Pending", "Sent", "Won"]
        
        return stages.map { stage in
            PipelineStage(
                stage: stage,
                value: proposalValueByStatus[stage] ?? 0,
                count: proposalCountByStatus[stage] ?? 0
            )
        }
    }
    
    // MARK: - Monthly Trend Data
    
    private struct MonthlyData {
        let month: String
        let value: Double
    }
    
    private var monthlyProposalData: [MonthlyData] {
        // Generate monthly data based on selected time period
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyData] = []
        
        // Determine number of months to display
        let monthsToShow: Int
        switch selectedTimePeriod {
        case "1 Month": monthsToShow = 3  // Show 3 months even if filter is 1 month
        case "3 Months": monthsToShow = 6
        case "6 Months": monthsToShow = 6
        case "1 Year": monthsToShow = 12
        default: monthsToShow = 12
        }
        
        // Generate data for each month
        for i in 0..<monthsToShow {
            if let date = calendar.date(byAdding: .month, value: -(monthsToShow - 1 - i), to: now) {
                let month = monthString(from: date)
                let value = valueForMonth(date)
                
                result.append(MonthlyData(month: month, value: value))
            }
        }
        
        return result
    }
    
    private var averageMonthlyValue: Double {
        if monthlyProposalData.isEmpty {
            return 0
        }
        
        let total = monthlyProposalData.reduce(0) { $0 + $1.value }
        return total / Double(monthlyProposalData.count)
    }
    
    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func valueForMonth(_ month: Date) -> Double {
        let calendar = Calendar.current
        
        // Sum proposal values for the given month
        return filteredProposals.reduce(0) { total, proposal in
            guard let creationDate = proposal.creationDate else { return total }
            
            if calendar.isDate(creationDate, equalTo: month, toGranularity: .month) {
                return total + proposal.totalAmount
            } else {
                return total
            }
        }
    }
}

struct ProposalAnalyticsChartView_Previews: PreviewProvider {
    static var previews: some View {
        ProposalAnalyticsChartView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}