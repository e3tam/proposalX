// File: ProposalCRM/Views/Components/CustomTaxesTableView.swift

import SwiftUI
import CoreData

struct CustomTaxesTableView: View {
    @ObservedObject var proposal: Proposal
    let onDelete: (CustomTax) -> Void
    let onEdit: (CustomTax) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("Tax Name")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
                Text("Rate (%)")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 80, alignment: .center).padding(.horizontal, 5)
                Text("Amount (€)") // UPDATED Header
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 150, alignment: .trailing).padding(.horizontal, 5)
                Text("Act")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 60, alignment: .center).padding(.horizontal, 5)
            }
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))

            Divider().background(Color.gray)

            // Main table content with rows
            if proposal.taxesArray.isEmpty {
                Text("No custom taxes added yet")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(proposal.taxesArray, id: \.self) { tax in
                            HStack(spacing: 0) {
                                Text(tax.name ?? "Custom Tax")
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
                                Text(tax.formattedRate) // Use formatted rate (percentage)
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .frame(width: 80, alignment: .center).padding(.horizontal, 5)
                                Text(tax.formattedAmount) // Use formatted amount (now Euro)
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .frame(width: 150, alignment: .trailing).padding(.horizontal, 5)
                                HStack(spacing: 15) {
                                    Button(action: { onEdit(tax) }) {
                                        Image(systemName: "pencil").foregroundColor(.blue)
                                    }
                                    Button(action: { onDelete(tax) }) {
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
