import SwiftUI

struct NotesSection: View {
    let notes: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.secondarySystemBackground)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3))
                
                Text(notes)
                    .foregroundColor(textColor)
            }
            .padding()
        }
        .padding(.horizontal)
    }
}
