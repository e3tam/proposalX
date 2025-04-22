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
    @ObservedObject var proposal: Proposal
    @State private var showCompletedTasks = true
    @Environment(\.managedObjectContext) private var viewContext
    
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
        .navigationTitle("Tasks for \(proposal.formattedNumber)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    NavigationLink("Add Task", destination: AddTaskView(proposal: proposal))
                }) {
                    Label("Add Task", systemImage: "plus")
                }
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
