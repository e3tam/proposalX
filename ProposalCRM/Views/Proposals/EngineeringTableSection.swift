// EngineeringTableSection.swift
// Section for displaying engineering services in proposal detail view

import SwiftUI

struct EngineeringTableSection: View {
    let proposal: Proposal
    let onAdd: () -> Void
    let onEdit: (Engineering) -> Void
    let onDelete: (Engineering) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Engineering")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !proposal.engineeringArray.isEmpty {
                    Text("(\(proposal.engineeringArray.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            // Engineering table view
            if proposal.engineeringArray.isEmpty {
                emptyEngineeringView()
            } else {
                engineeringTableView()
            }
        }
        .padding(.horizontal)
    }
    
    private func emptyEngineeringView() -> some View {
        Text("No engineering services added yet")
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.15))
            .cornerRadius(10)
    }
    
    private func engineeringTableView() -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("Description")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                
                Text("Days")
                    .frame(width: 80, alignment: .center)
                
                Text("Rate (€)")
                    .frame(width: 120, alignment: .trailing)
                
                Text("Amount (€)")
                    .frame(width: 120, alignment: .trailing)
                
                Text("Actions")
                    .frame(width: 100, alignment: .center)
                    .padding(.trailing, 8)
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Engineering rows
            ForEach(proposal.engineeringArray, id: \.self) { engineering in
                HStack(spacing: 0) {
                    Text(engineering.desc ?? "No description")
                        .font(.system(size: 14))
                        .lineLimit(2)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    
                    Text(String(format: "%.1f", engineering.days))
                        .font(.system(size: 14))
                        .frame(width: 80, alignment: .center)
                    
                    Text(Formatters.formatEuro(engineering.rate))
                        .font(.system(size: 14))
                        .frame(width: 120, alignment: .trailing)
                    
                    Text(Formatters.formatEuro(engineering.amount))
                        .font(.system(size: 14))
                        .frame(width: 120, alignment: .trailing)
                    
                    HStack(spacing: 10) {
                        Button(action: { onEdit(engineering) }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { onDelete(engineering) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(width: 100, alignment: .center)
                    .padding(.trailing, 8)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                
                Divider().background(Color.gray.opacity(0.3))
            }
            
            // Total row
            HStack(spacing: 0) {
                Text("Total Engineering")
                    .fontWeight(.bold)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 8)
                
                Text(Formatters.formatEuro(proposal.subtotalEngineering))
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .trailing)
                
                Spacer()
                    .frame(width: 100)
                    .padding(.trailing, 8)
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
        }
        .background(Color.black.opacity(0.15))
        .cornerRadius(10)
    }
}