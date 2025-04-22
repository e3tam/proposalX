//
//  ContentView.swift
//  ProposalCRM
//
//  Minimal modification to support sidebar toggling
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = "Dashboard"
    
    // Use the shared singleton instance
    @ObservedObject private var navigationState = NavigationState.shared
    
    var body: some View {
        ZStack {
            // Custom segmented control for tab selection
            VStack(spacing: 0) {
                // Tab bar at top
                HStack(spacing: 0) {
                    TabButton(title: "Customers", icon: "person.3", selected: $selectedTab)
                    TabButton(title: "Products", icon: "cube.box", selected: $selectedTab)
                    TabButton(title: "Proposals", icon: "doc.text", selected: $selectedTab)
                    TabButton(title: "Tasks", icon: "checklist", selected: $selectedTab)
                    TabButton(title: "Dashboard", icon: "chart.bar", selected: $selectedTab)
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray6))
                
                // Content view based on selected tab
                if selectedTab == "Dashboard" {
                    // Show dashboard with no navigation view or sidebars
                    EnhancedDashboardView()
                        .transition(.opacity)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    // Use navigation view for other tabs
                    ZStack {
                        if selectedTab == "Customers" {
                            NavigationView { CustomerListView() }
                                .transition(.opacity)
                                .environmentObject(navigationState) // Pass the navigationState
                        } else if selectedTab == "Products" {
                            NavigationView { CustomProductListView() }
                                .transition(.opacity)
                                .environmentObject(navigationState) // Pass the navigationState
                        } else if selectedTab == "Proposals" {
                            NavigationView { ProposalListView() }
                                .transition(.opacity)
                                .environmentObject(navigationState) // Pass the navigationState
                        } else if selectedTab == "Tasks" {
                            NavigationView { TaskListView() }
                                .transition(.opacity)
                                .environmentObject(navigationState) // Pass the navigationState
                        }
                    }
                    .navigationViewStyle(DoubleColumnNavigationViewStyle())
                }
            }
        }
    }
}

// Tab Button Component (unchanged)
struct TabButton: View {
    let title: String
    let icon: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: {
            withAnimation {
                selected = title
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selected == title ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selected == title ?
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .padding(.horizontal, 8) :
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .padding(.horizontal, 8)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
