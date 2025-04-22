// SectionWithAddButton.swift
// Reusable section component with add button

import SwiftUI

struct SectionWithAddButton<Content: View>: View {
    let title: String
    let count: Int
    let onAdd: () -> Void
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                }
            }
            
            Divider()
            
            if count == 0 {
                HStack {
                    Spacer()
                    Text("No \(title.lowercased()) added yet")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical)
            } else {
                content()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
