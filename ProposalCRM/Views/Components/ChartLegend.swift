import SwiftUI

struct ChartLegend: View {
    let items: [DoughnutChartItem]
    var columns: Int = 2
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 8) {
            ForEach(items) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    
                    Text(item.name)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if columns == 1 {
                        Text(Formatters.formatEuro(item.value))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}