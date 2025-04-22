import SwiftUI

struct ChartLegend: View {
    let items: [DoughnutChartItem]
    var columns: Int = 2
    
    // Inside ChartLegend struct
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 8) {
            // Iterate directly over identifiable items
            ForEach(items) { item in // Changed this line
                HStack {
                    Circle()
                        .fill(item.color) // Relies on Fix #1
                        .frame(width: 12, height: 12)

                    Text(item.name) // Relies on Fix #1
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if columns == 1 {
                        Text(Formatters.formatEuro(item.value)) // Relies on Fix #1
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
