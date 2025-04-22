import SwiftUI
import CoreData

// MARK: - Main Engineering View
struct EngineeringView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var proposal: Proposal
    
    // State variables for form fields
    @State private var description = ""
    @State private var days = ""
    @State private var rate = ""
    
    // States for showing various options
    @State private var showingDayPresets = false
    @State private var showingRatePresets = false
    @State private var showingServicePresets = false
    @State private var showingTemplates = false
    @State private var showingSaveTemplateDialog = false
    
    // State for saving template
    @State private var templateName = ""
    
    // TemplateManager reference
    @StateObject private var templateManager = TemplateManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Template Options
                TemplateOptionsSection(
                    showingTemplates: $showingTemplates,
                    showingServicePresets: $showingServicePresets,
                    templateManager: templateManager,
                    description: $description,
                    days: $days,
                    rate: $rate
                )

                // MARK: - Engineering Details Section
                EngineeringDetailsSection(
                    description: $description,
                    days: $days,
                    rate: $rate,
                    showingDayPresets: $showingDayPresets,
                    showingRatePresets: $showingRatePresets,
                    templateManager: templateManager
                )
                
                // MARK: - Preview Section
                if !description.isEmpty && Double(days) != nil && Double(rate) != nil {
                    PreviewSection(
                        description: description,
                        days: days,
                        rate: rate,
                        templateName: $templateName,
                        showingSaveTemplateDialog: $showingSaveTemplateDialog
                    )
                }
            }
            .navigationTitle("Add Engineering")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addEngineering()
                    }
                    .disabled(!isFormValid)
                }
            }
            // MARK: - Sheet Presentations
            .sheet(isPresented: $showingTemplates) {
                EngineeringTemplatesView(
                    isPresented: $showingTemplates,
                    onSelectTemplate: { template in
                        // Apply template values to form
                        description = template.description
                        days = String(format: "%.1f", template.days)
                        rate = String(format: "%.2f", template.rate)
                    }
                )
                .environmentObject(templateManager)
            }
            // MARK: - Template Save Dialog
            .overlay(
                SaveTemplateDialogView(
                    showingSaveTemplateDialog: $showingSaveTemplateDialog,
                    templateName: $templateName,
                    description: description,
                    days: days,
                    rate: rate,
                    onSave: saveAsTemplate
                )
            )
        }
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && Double(days) != nil && Double(rate) != nil
    }
    
    private func addEngineering() {
        let engineering = Engineering(context: viewContext)
        engineering.id = UUID()
        engineering.desc = description
        engineering.days = Double(days) ?? 0
        engineering.rate = Double(rate) ?? 0
        engineering.amount = engineering.days * engineering.rate
        engineering.proposal = proposal
        
        do {
            try viewContext.save()
            
            // Update proposal total
            updateProposalTotal()
            
            // Log activity
            ActivityLogger.logItemAdded(
                proposal: proposal,
                context: viewContext,
                itemType: "Engineering",
                itemName: description
            )
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error adding engineering: \(error)")
        }
    }
    
    private func updateProposalTotal() {
        let productsTotal = proposal.subtotalProducts
        let engineeringTotal = proposal.subtotalEngineering
        let expensesTotal = proposal.subtotalExpenses
        let taxesTotal = proposal.subtotalTaxes
        
        proposal.totalAmount = productsTotal + engineeringTotal + expensesTotal + taxesTotal
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating proposal total: \(error)")
        }
    }
    
    // Save current engineering settings as a template
    private func saveAsTemplate() {
        let daysValue = Double(days) ?? 1.0
        let rateValue = Double(rate) ?? 1000.0
        
        let template = EngineeringTemplate(
            name: templateName,
            description: description,
            days: daysValue,
            rate: rateValue
        )
        
        templateManager.addEngineeringTemplate(template)
    }
}

// MARK: - Template Options Section
struct TemplateOptionsSection: View {
    @Binding var showingTemplates: Bool
    @Binding var showingServicePresets: Bool
    @ObservedObject var templateManager: TemplateManager
    @Binding var description: String
    @Binding var days: String
    @Binding var rate: String
    
    var body: some View {
        Section(header: Text("TEMPLATES").foregroundColor(.blue)) {
            Button(action: { showingTemplates = true }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.blue)
                    Text("Select from Saved Templates")
                        .foregroundColor(.primary)
                }
            }
            
            // Quick service templates button
            Button(action: {
                withAnimation { showingServicePresets.toggle() }
            }) {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundColor(.blue)
                    Text("Quick Service Templates")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showingServicePresets ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick service templates list (collapsible)
            if showingServicePresets {
                ServicePresetsView(
                    templateManager: templateManager,
                    onSelect: { template in
                        description = template.description
                        days = String(format: "%.1f", template.days)
                        rate = String(format: "%.2f", template.rate)
                        showingServicePresets = false
                    }
                )
            }
        }
    }
}

// MARK: - Service Presets View
struct ServicePresetsView: View {
    @ObservedObject var templateManager: TemplateManager
    let onSelect: (EngineeringTemplate) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(templateManager.getSortedEngineeringTemplates().filter(\.isDefault), id: \.id) { template in
                    Button(action: {
                        onSelect(template)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(template.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            HStack {
                                Text("\(String(format: "%.1f", template.days)) days")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Text(Formatters.formatEuro(template.rate) + "/day")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 250)
    }
}

// MARK: - Engineering Details Section
struct EngineeringDetailsSection: View {
    @Binding var description: String
    @Binding var days: String
    @Binding var rate: String
    @Binding var showingDayPresets: Bool
    @Binding var showingRatePresets: Bool
    @ObservedObject var templateManager: TemplateManager
    
    // Preset options
    let dayPresets: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0]
    let ratePresets: [Double] = [800.0, 1000.0, 1200.0, 1500.0, 2000.0]
    
    var body: some View {
        Section(header: Text("ENGINEERING SERVICE")) {
            // Description field
            DescriptionFieldView(description: $description)
            
            // Days selection with presets
            DaysSelectionView(
                days: $days,
                showingDayPresets: $showingDayPresets,
                dayPresets: dayPresets
            )
            
            // Rate with presets
            RateSelectionView(
                rate: $rate,
                showingRatePresets: $showingRatePresets,
                ratePresets: ratePresets,
                templateManager: templateManager
            )
            
            // Amount (calculated)
            if let daysValue = Double(days), let rateValue = Double(rate) {
                let amount = daysValue * rateValue
                HStack {
                    Text("Total Amount")
                        .font(.headline)
                    Spacer()
                    Text(Formatters.formatEuro(amount))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Description Field View
struct DescriptionFieldView: View {
    @Binding var description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Enter a description", text: $description)
                .font(.body)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Days Selection View
struct DaysSelectionView: View {
    @Binding var days: String
    @Binding var showingDayPresets: Bool
    let dayPresets: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Days")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Days", text: $days)
                    .keyboardType(.decimalPad)
                    .font(.body)
                    .padding(10)
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
        
        // Day presets appear conditionally
        if showingDayPresets {
            DayPresetsGridView(
                dayPresets: dayPresets,
                days: $days,
                showingDayPresets: $showingDayPresets
            )
        }
    }
}

// MARK: - Day Presets Grid View
struct DayPresetsGridView: View {
    let dayPresets: [Double]
    @Binding var days: String
    @Binding var showingDayPresets: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Day Selections")
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
                
                Button(action: {
                    // Custom option - keeps the panel open
                }) {
                    Text("Custom")
                        .font(.body)
                        .padding(8)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rate Selection View
struct RateSelectionView: View {
    @Binding var rate: String
    @Binding var showingRatePresets: Bool
    let ratePresets: [Double]
    @ObservedObject var templateManager: TemplateManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Daily Rate (€)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Rate", text: $rate)
                    .keyboardType(.decimalPad)
                    .font(.body)
                    .padding(10)
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
        
        // Rate presets appear conditionally
        if showingRatePresets {
            RatePresetsGridView(
                ratePresets: ratePresets,
                templateManager: templateManager,
                rate: $rate,
                showingRatePresets: $showingRatePresets
            )
        }
    }
}

// MARK: - Rate Presets Grid View
struct RatePresetsGridView: View {
    let ratePresets: [Double]
    @ObservedObject var templateManager: TemplateManager
    @Binding var rate: String
    @Binding var showingRatePresets: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Standard Rates")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Standard rates grid
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
            
            // Custom rates grid (from user templates)
            if !templateManager.getSortedRateTemplates().isEmpty {
                Text("Saved Rates")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(templateManager.getSortedRateTemplates(), id: \.id) { template in
                        Button(action: {
                            rate = String(format: "%.2f", template.rate)
                            showingRatePresets = false
                        }) {
                            VStack(spacing: 2) {
                                Text(Formatters.formatEuro(template.rate))
                                    .font(.body)
                                Text(template.name)
                                    .font(.caption)
                            }
                            .padding(8)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview Section
struct PreviewSection: View {
    let description: String
    let days: String
    let rate: String
    @Binding var templateName: String
    @Binding var showingSaveTemplateDialog: Bool
    
    var body: some View {
        Section(header:
            HStack {
                Text("PREVIEW")
                Spacer()
                SaveTemplateButton {
                    // Initialize with current values
                    templateName = description
                    showingSaveTemplateDialog = true
                }
            }
        ) {
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
                    
                    if let daysValue = Double(days), let rateValue = Double(rate) {
                        let amount = daysValue * rateValue
                        HStack {
                            Spacer()
                            Text("Total: ")
                                .font(.subheadline)
                            Text(Formatters.formatEuro(amount))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Save Template Dialog View
struct SaveTemplateDialogView: View {
    @Binding var showingSaveTemplateDialog: Bool
    @Binding var templateName: String
    let description: String
    let days: String
    let rate: String
    let onSave: () -> Void
    
    var body: some View {
        Group {
            if showingSaveTemplateDialog {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingSaveTemplateDialog = false
                    }
                
                SaveTemplateDialog(
                    isPresented: $showingSaveTemplateDialog,
                    title: "Save as Template",
                    templateName: $templateName,
                    onSave: onSave
                ) {
                    // Dialog content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Save the current engineering service as a template for future use:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Description: ")
                                    .fontWeight(.semibold)
                                Text(description)
                            }
                            .foregroundColor(.primary)
                            
                            HStack {
                                Text("Days: ")
                                    .fontWeight(.semibold)
                                Text(days)
                            }
                            .foregroundColor(.primary)
                            
                            HStack {
                                Text("Rate: ")
                                    .fontWeight(.semibold)
                                Text(Formatters.formatEuro(Double(rate) ?? 0))
                            }
                            .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Save as default option
                        Toggle("Save as default template", isOn: .constant(false))
                            .font(.subheadline)
                    }
                }
                .transition(.scale)
            }
        }
    }
}

// MARK: - Save Template Button
struct SaveTemplateButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.down")
                    .font(.caption)
                Text("Save Template")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

// MARK: - Save Template Dialog
struct SaveTemplateDialog<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    @Binding var templateName: String
    let onSave: () -> Void
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Dialog header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            // Dialog content
            content()
            
            // Template name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Template Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter template name", text: $templateName)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Dialog actions
            HStack {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    onSave()
                    isPresented = false
                }) {
                    Text("Save Template")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(templateName.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
    }
}

// MARK: - Template Manager
class TemplateManager: ObservableObject {
    static let shared = TemplateManager()
    
    @Published private var engineeringTemplates: [EngineeringTemplate] = []
    @Published private var rateTemplates: [RateTemplate] = []
    
    // Sample data - should be loaded from UserDefaults in a real app
    init() {
        // Default engineering templates
        engineeringTemplates = [
            EngineeringTemplate(name: "Basic Installation", description: "Standard installation service", days: 1.0, rate: 1000, isDefault: true),
            EngineeringTemplate(name: "Advanced Setup", description: "Complex system configuration", days: 2.0, rate: 1200, isDefault: true),
            EngineeringTemplate(name: "Training Session", description: "User training for new system", days: 1.5, rate: 900, isDefault: true),
            EngineeringTemplate(name: "System Integration", description: "Integrate with existing infrastructure", days: 3.0, rate: 1100, isDefault: true)
        ]
        
        // Default rate templates
        rateTemplates = [
            RateTemplate(name: "Junior Engineer", rate: 800),
            RateTemplate(name: "Senior Engineer", rate: 1200),
            RateTemplate(name: "Expert Consultant", rate: 1500)
        ]
    }
    
    func getSortedEngineeringTemplates() -> [EngineeringTemplate] {
        return engineeringTemplates.sorted { $0.name < $1.name }
    }
    
    func getSortedRateTemplates() -> [RateTemplate] {
        return rateTemplates.sorted { $0.rate < $1.rate }
    }
    
    func addEngineeringTemplate(_ template: EngineeringTemplate) {
        engineeringTemplates.append(template)
        // In a real app, save to UserDefaults or other storage
    }
    
    func addRateTemplate(_ template: RateTemplate) {
        rateTemplates.append(template)
        // In a real app, save to UserDefaults or other storage
    }
}

// MARK: - Template Models
struct EngineeringTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let days: Double
    let rate: Double
    var isDefault: Bool = false
}

struct RateTemplate: Identifiable {
    let id = UUID()
    let name: String
    let rate: Double
}

// MARK: - Preview Provider
struct EngineeringView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let proposal = Proposal(context: context)
        proposal.id = UUID()
        proposal.number = "PROP-2023-001"
        
        return EngineeringView(proposal: proposal)
            .environment(\.managedObjectContext, context)
    }
}
