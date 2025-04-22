// File: ProposalCRM/Views/Components/EngineeringTableView.swift

import SwiftUI
import CoreData

struct EngineeringTableView: View {
    @ObservedObject var proposal: Proposal
    let onDelete: (Engineering) -> Void
    let onEdit: (Engineering) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("Description")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
                Text("Days")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 80, alignment: .center).padding(.horizontal, 5)
                Text("Rate (€)") // UPDATED Header
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 100, alignment: .trailing).padding(.horizontal, 5)
                Text("Amount (€)") // UPDATED Header
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 100, alignment: .trailing).padding(.horizontal, 5)
                Text("Act")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 60, alignment: .center).padding(.horizontal, 5)
            }
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))

            Divider().background(Color.gray)

            // Main table content with rows
            if proposal.engineeringArray.isEmpty {
                Text("No engineering services added yet")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(proposal.engineeringArray, id: \.self) { engineering in
                            HStack(spacing: 0) {
                                Text(engineering.desc ?? "No Description")
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
                                Text(String(format: "%.1f", engineering.days))
                                    .font(.system(size: 14)).foregroundColor(.white) // Days format unchanged
                                    .frame(width: 80, alignment: .center).padding(.horizontal, 5)
                                Text(Formatters.formatEuro(engineering.rate)) // UPDATED Formatting
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .frame(width: 100, alignment: .trailing).padding(.horizontal, 5)
                                Text(Formatters.formatEuro(engineering.amount)) // UPDATED Formatting (uses formattedAmount)
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .frame(width: 100, alignment: .trailing).padding(.horizontal, 5)
                                HStack(spacing: 15) {
                                    Button(action: { onEdit(engineering) }) {
                                        Image(systemName: "pencil").foregroundColor(.blue)
                                    }
                                    Button(action: { onDelete(engineering) }) {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                                .frame(width: 60, alignment: .center)
                            }
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.2))

                            Divider().background(Color.gray.opacity(0.5))
                        }
                    }
                }
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
