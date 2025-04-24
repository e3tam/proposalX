import SwiftUI

struct RecentActivityDashboard: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.timestamp, ascending: false)],
        animation: .default)
    private var recentActivities: FetchedResults<Activity>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Dashboard header
            DashboardHeader()
            
            // Content based on whether there are activities
            if recentActivities.isEmpty {
                EmptyActivityState()
            } else {
                ActivityTimelineView(activities: Array(recentActivities.prefix(4)))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Component Views

// Header with title and View All link
private struct DashboardHeader: View {
    var body: some View {
        HStack {
            Text("Recent Activity")
                .font(.headline)
            
            Spacer()
            
            NavigationLink(destination: GlobalActivityView()) {
                Text("View All")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
}

// Empty state when no activities are present
private struct EmptyActivityState: View {
    var body: some View {
        Text("No recent activity")
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
    }
}

// Timeline view showing recent activities
private struct ActivityTimelineView: View {
    let activities: [Activity]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities, id: \.self) { activity in
                TimelineItem(
                    activity: activity,
                    isLast: activity == activities.last
                )
                .padding(.vertical, 8)
            }
        }
    }
}

// Individual timeline item
private struct TimelineItem: View {
    let activity: Activity
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Timeline dot and line
            TimelineDotAndLine(
                iconName: activity.typeIcon,
                iconColor: activity.typeColor,
                showLine: !isLast
            )
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.desc ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack {
                    if let proposal = activity.proposal {
                        Text(proposal.number ?? "Unknown")
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
    }
}

// Timeline visual elements (dot and connecting line)
private struct TimelineDotAndLine: View {
    let iconName: String
    let iconColor: Color
    let showLine: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Dot with icon
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 30, height: 30)
                
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14))
            }
            
            // Connecting line (if not the last item)
            if showLine {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 30)
            }
        }
    }
}

// MARK: - Preview

struct RecentActivityDashboard_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivityDashboard()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
