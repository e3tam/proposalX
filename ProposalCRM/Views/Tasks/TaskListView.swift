//
//  TaskListView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


// TaskListView.swift
// Display all tasks with filtering options

import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Task.status, ascending: true),
            NSSortDescriptor(keyPath: \Task.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Task.priority, ascending: false)
        ],
        animation: .default)
    private var allTasks: FetchedResults<Task>
    
    @State private var showCompletedTasks = false
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    
    let filterOptions = ["All", "High Priority", "Today", "Overdue"]
    
    var body: some View {
        VStack {
            // Filter toggles
            HStack {
                Toggle("Show Completed", isOn: $showCompletedTasks)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Spacer()
                
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 140)
            }
            .padding(.horizontal)
            
            if filteredTasks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No tasks found")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Try changing your filter settings")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredTasks, id: \.self) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskRowView(task: task)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle("Tasks")
        .searchable(text: $searchText, prompt: "Search tasks")
    }
    
    private var filteredTasks: [Task] {
        var tasks = allTasks.filter { task in
            // Filter completed tasks based on toggle
            if !showCompletedTasks && task.status == "Completed" {
                return false
            }
            
            // Apply search if entered
            if !searchText.isEmpty {
                let titleMatch = task.title?.localizedCaseInsensitiveContains(searchText) ?? false
                let descMatch = task.desc?.localizedCaseInsensitiveContains(searchText) ?? false
                let noteMatch = task.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                let proposalMatch = task.proposal?.number?.localizedCaseInsensitiveContains(searchText) ?? false
                
                if !titleMatch && !descMatch && !noteMatch && !proposalMatch {
                    return false
                }
            }
            
            // Apply selected filter
            switch selectedFilter {
            case "High Priority":
                return task.priority == "High"
            case "Today":
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            case "Overdue":
                return task.isOverdue
            default:
                return true
            }
        }
        
        return Array(tasks)
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