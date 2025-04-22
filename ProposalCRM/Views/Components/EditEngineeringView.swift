import SwiftUI
import CoreData

struct EditEngineeringView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var engineering: Engineering
    
    // State variables properly initialized from the engineering object
    @State private var description: String
    @State private var days: String
    @State private var rate: String
    
    // Presets for quick selection
    @State private var showingDayPresets = false
    @State private var showingRatePresets = false
    
    let dayPresets: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0]
    let ratePresets: [Double] = [800.0, 1000.0, 1200.0, 1500.0, 2000.0]
    
    // Initialize with the engineering object data, ensuring values are properly set
    init(engineering: Engineering) {
        self.engineering = engineering
        
        // Safe initialization with fallbacks
        _description = State(initialValue: engineering.desc ?? "")
        _days = State(initialValue: String(format: "%.1f", engineering.days))
        _rate = State(initialValue: String(format: "%.2f", engineering.rate))
        
        // Debug print to verify initialization
        print("EditEngineeringView initialized with: \(engineering.desc ?? "no desc"), days: \(engineering.days), rate: \(engineering.rate)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Engineering Details Section
                Section(header: Text("ENGINEERING DETAILS")) {
                    // Description field with label
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter service description", text: $description)
                            .font(.body)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                    
                    // Days with presets button
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Number of days", text: $days)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            
                            Button(action: {
                                withAnimation { showingDayPresets.toggle() }
                            }) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Day presets (collapsible)
                    if showingDayPresets {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Day Options")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 60), spacing: 8)
                            ], spacing: 8) {
                                ForEach(dayPresets, id: \.self) { preset in
                                    Button(action: {
                                        days = String(format: "%.1f", preset)
                                        showingDayPresets = false
                                    }) {
                                        Text(String(format: "%.1f", preset))
                                            .font(.body)
                                            .padding(8)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Rate with presets button
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Rate (€)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Rate per day", text: $rate)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            
                            Button(action: {
                                withAnimation { showingRatePresets.toggle() }
                            }) {
                                Image(systemName: "eurosign.circle")
                                    .foregroundColor(.green)
                                    .padding(8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Rate presets (collapsible)
                    if showingRatePresets {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Standard Rates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80), spacing: 8)
                            ], spacing: 8) {
                                ForEach(ratePresets, id: \.self) { preset in
                                    Button(action: {
                                        rate = String(format: "%.2f", preset)
                                        showingRatePresets = false
                                    }) {
                                        Text(Formatters.formatEuro(preset))
                                            .font(.body)
                                            .padding(8)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Amount (calculated)
                    HStack {
                        Text("Total Amount:")
                            .font(.headline)
                        Spacer()
                        Text(Formatters.formatEuro(calculateAmount()))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // MARK: - Preview Section
                Section(header: Text("PREVIEW")) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Engineering entry preview
                        VStack(alignment: .leading, spacing: 4) {
                            Text(description)
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("\(days) days")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Image(systemName: "eurosign.circle")
                                    .foregroundColor(.green)
                                if let rateValue = Double(rate) {
                                    Text("\(Formatters.formatEuro(rateValue))/day")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Text("Total: ")
                                    .font(.subheadline)
                                Text(Formatters.formatEuro(calculateAmount()))
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Edit Engineering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                // Debug: Verify data is displayed
                print("Form displaying with: '\(description)', days: '\(days)', rate: '\(rate)'")
            }
        }
    }
    
    private func calculateAmount() -> Double {
        let daysValue = Double(days) ?? 0
        let rateValue = Double(rate) ?? 0
        return daysValue * rateValue
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && Double(days) != nil && Double(rate) != nil
    }
    
    private func saveChanges() {
        print("Saving changes for engineering: \(engineering.id?.uuidString ?? "unknown id")")
        
        // Update the engineering object with current values
        engineering.desc = description
        engineering.days = Double(days) ?? 0
        engineering.rate = Double(rate) ?? 0
        engineering.amount = calculateAmount()
        
        do {
            try viewContext.save()
            
            // Log the change for debugging
            print("Successfully updated engineering: \(description), days: \(engineering.days), rate: \(engineering.rate)")
            
            // Log the activity
            if let proposal = engineering.proposal {
                ActivityLogger.logItemRemoved(
                    proposal: proposal,
                    context: viewContext,
                    itemType: "Engineering",
                    itemName: description
                )
            }
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving engineering changes: \(error)")
            // In a real app, you would want to show an error alert to the user
        }
    }
}
