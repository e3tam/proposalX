//
//  ActivityRowView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 19.04.2025.
//


//
// ActivityRowView.swift
// Row component for displaying an activity
//

import SwiftUI

struct ActivityRowView: View {
    @ObservedObject var activity: Activity
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Activity header
            HStack {
                Image(systemName: activity.typeIcon)
                    .foregroundColor(activity.typeColor)
                    .font(.system(size: 18))
                
                Text(activity.type ?? "Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(activity.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    showDetails.toggle()
                }
            }
            
            // Activity description
            Text(activity.description ?? "")
                .font(.subheadline)
                .foregroundColor(.white)
            

            // Details section if available and expanded
            if let details = activity.details, !details.isEmpty, showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(details)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.top, 8)
                .transition(.slide)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
    }
}
