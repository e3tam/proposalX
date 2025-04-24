//
//  TaskListViewForProposal.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// TaskListViewForProposal.swift
// Display all tasks for a specific proposal

import SwiftUI

struct TaskListViewForProposal: View {
    // Changed from @ObservedObject to regular property
    var proposal: Proposal
    @State private var showCompletedTasks = true
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddTask = false
    
    var body: some View {
        VStack {
            // Filter toggle
            Toggle("Show Completed Tasks", isOn: $showCompletedTasks)
                .padding()
            
            List {
                ForEach(filteredTasks, id: \.self) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task)
                    }
                }
                .onDelete(perform: deleteTasks)
            }
        }
        // Use direct property access with fallback instead of computed property
        .navigationTitle("Tasks for \(proposal.number ?? "Proposal")")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddTask = true
                }) {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        // Use a sheet to present the AddTaskView
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                AddTaskView(proposal: proposal)
                    .navigationTitle("Add Task")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddTask = false
                        }
                    )
            }
        }
    }
    
    private var filteredTasks: [Task] {
        return proposal.tasksArray.filter { task in
            showCompletedTasks || task.status != "Completed"
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredTasks[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting task: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
