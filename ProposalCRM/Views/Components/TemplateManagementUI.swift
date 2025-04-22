//
//  TemplateListView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


import SwiftUI

// MARK: - Template List View

/// Generic list view for displaying and managing templates
struct TemplateListView<T: Identifiable & Equatable>: View {
    let title: String
    let items: [T]
    let itemLabel: (T) -> String
    let itemSubtitle: (T) -> String
    let onSelect: (T) -> Void
    let onEdit: (T) -> Void
    let onDelete: (T) -> Void
    let onAdd: () -> Void
    
    @State private var searchText = ""
    
    var filteredItems: [T] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { 
                let label = itemLabel($0).lowercased()
                let subtitle = itemSubtitle($0).lowercased()
                return label.contains(searchText.lowercased()) || 
                       subtitle.contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and add button
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onAdd) {
                    Label("Add New", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search templates", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Template items list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                    
                    Text(searchText.isEmpty ? "No templates yet" : "No matching templates")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Button(action: onAdd) {
                            Label("Create Your First Template", systemImage: "plus")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                List {
                    ForEach(filteredItems, id: \.id) { item in
                        TemplateRow(
                            label: itemLabel(item),
                            subtitle: itemSubtitle(item),
                            onSelect: { onSelect(item) },
                            onEdit: { onEdit(item) }
                        )
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive, action: { onDelete(item) }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

// Individual template row in the list
struct TemplateRow: View {
    let label: String
    let subtitle: String
    let onSelect: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onSelect) {
                    Text("Use")
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Save Template Dialog

/// Generic dialog for saving a new template
struct SaveTemplateDialog<T>: View {
    @Binding var isPresented: Bool
    let title: String
    let templateName: Binding<String>
    let onSave: () -> Void
    let content: () -> T
    
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View where T: View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            
            // Template name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Template Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter a name for this template", text: templateName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($nameFieldFocused)
            }
            .padding()
            
            // Custom content
            VStack {
                content()
            }
            .padding()
            
            // Footer with save button
            HStack {
                Spacer()
                
                Button(action: {
                    onSave()
                    isPresented = false
                }) {
                    Text("Save Template")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(templateName.wrappedValue.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(templateName.wrappedValue.isEmpty)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .frame(width: 350)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            nameFieldFocused = true
        }
    }
}

// MARK: - Engineering Templates UI Components

/// View for showing engineering templates
struct EngineeringTemplatesView: View {
    @EnvironmentObject var templateManager: TemplateManager
    @Binding var isPresented: Bool
    let onSelectTemplate: (EngineeringTemplate) -> Void
    
    @State private var editingTemplate: EngineeringTemplate?
    @State private var showingEditDialog = false
    @State private var showingSaveDialog = false
    @State private var templateName = ""
    
    // Current template values for saving or editing
    @State private var templateDescription = ""
    @State private var templateDays = "1.0"
    @State private var templateRate = "1000.0"
    
    var body: some View {
        NavigationView {
            TemplateListView(
                title: "Engineering Templates",
                items: templateManager.getSortedEngineeringTemplates(),
                itemLabel: { $0.name },
                itemSubtitle: { 
                    "\($0.description) - \(String(format: "%.1f", $0.days)) days @ \(Formatters.formatEuro($0.rate))/day"
                },
                onSelect: { template in
                    onSelectTemplate(template)
                    isPresented = false
                },
                onEdit: { template in
                    editingTemplate = template
                    templateName = template.name
                    templateDescription = template.description
                    templateDays = String(format: "%.1f", template.days)
                    templateRate = String(format: "%.2f", template.rate)
                    showingEditDialog = true
                },
                onDelete: { template in
                    // Don't delete default templates
                    if !template.isDefault {
                        templateManager.deleteEngineeringTemplate(id: template.id)
                    }
                },
                onAdd: {
                    // Reset fields
                    templateName = ""
                    templateDescription = ""
                    templateDays = "1.0"
                    templateRate = "1000.0"
                    showingSaveDialog = true
                }
            )
            .navigationTitle("Engineering Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .overlay(
                Group {
                    if showingSaveDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingSaveDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingSaveDialog,
                            title: "Save Engineering Template",
                            templateName: $templateName,
                            onSave: saveNewTemplate
                        ) {
                            // Content
                            VStack(spacing: 16) {
                                // Description field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter description", text: $templateDescription)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Days field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter days", text: $templateDays)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Rate field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Rate (€)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter rate", text: $templateRate)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                        .transition(.scale)
                    }
                    
                    if showingEditDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingEditDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingEditDialog,
                            title: "Edit Engineering Template",
                            templateName: $templateName,
                            onSave: updateTemplate
                        ) {
                            // Content - same as save dialog
                            VStack(spacing: 16) {
                                // Description field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter description", text: $templateDescription)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Days field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter days", text: $templateDays)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Rate field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Rate (€)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter rate", text: $templateRate)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                        .transition(.scale)
                    }
                }
            )
        }
    }
    
    // Save a new template
    private func saveNewTemplate() {
        let days = Double(templateDays) ?? 1.0
        let rate = Double(templateRate) ?? 1000.0
        
        let template = EngineeringTemplate(
            name: templateName,
            description: templateDescription,
            days: days,
            rate: rate
        )
        
        templateManager.addEngineeringTemplate(template)
    }
    
    // Update an existing template
    private func updateTemplate() {
        guard let template = editingTemplate else { return }
        
        let days = Double(templateDays) ?? template.days
        let rate = Double(templateRate) ?? template.rate
        
        let updatedTemplate = EngineeringTemplate(
            id: template.id,
            name: templateName,
            description: templateDescription,
            days: days,
            rate: rate,
            isDefault: template.isDefault
        )
        
        templateManager.updateEngineeringTemplate(updatedTemplate)
    }
}

// MARK: - Expense Templates UI Components

/// View for showing expense templates
struct ExpenseTemplatesView: View {
    @EnvironmentObject var templateManager: TemplateManager
    @Binding var isPresented: Bool
    let onSelectTemplate: (ExpenseTemplate) -> Void
    
    @State private var editingTemplate: ExpenseTemplate?
    @State private var showingEditDialog = false
    @State private var showingSaveDialog = false
    @State private var templateName = ""
    
    // Current template values for saving or editing
    @State private var templateDescription = ""
    @State private var templateCategory = "Travel"
    @State private var templateAmount = "100.0"
    
    let categories = ["Travel", "Shipping", "Materials", "Services", "Equipment", "Other"]
    
    var body: some View {
        NavigationView {
            TemplateListView(
                title: "Expense Templates",
                items: templateManager.getSortedExpenseTemplates(),
                itemLabel: { $0.name },
                itemSubtitle: { 
                    "\($0.category): \($0.description) - \(Formatters.formatEuro($0.amount))"
                },
                onSelect: { template in
                    onSelectTemplate(template)
                    isPresented = false
                },
                onEdit: { template in
                    editingTemplate = template
                    templateName = template.name
                    templateDescription = template.description
                    templateCategory = template.category
                    templateAmount = String(format: "%.2f", template.amount)
                    showingEditDialog = true
                },
                onDelete: { template in
                    if !template.isDefault {
                        templateManager.deleteExpenseTemplate(id: template.id)
                    }
                },
                onAdd: {
                    templateName = ""
                    templateDescription = ""
                    templateCategory = "Travel"
                    templateAmount = "100.0"
                    showingSaveDialog = true
                }
            )
            .navigationTitle("Expense Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .overlay(
                Group {
                    if showingSaveDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingSaveDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingSaveDialog,
                            title: "Save Expense Template",
                            templateName: $templateName,
                            onSave: saveNewTemplate
                        ) {
                            // Content
                            VStack(spacing: 16) {
                                // Description field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter description", text: $templateDescription)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Category field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Category")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Category", selection: $templateCategory) {
                                        ForEach(categories, id: \.self) { category in
                                            Text(category).tag(category)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                // Amount field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Amount (€)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter amount", text: $templateAmount)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                        .transition(.scale)
                    }
                    
                    if showingEditDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingEditDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingEditDialog,
                            title: "Edit Expense Template",
                            templateName: $templateName,
                            onSave: updateTemplate
                        ) {
                            // Content - same as save dialog
                            VStack(spacing: 16) {
                                // Description field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter description", text: $templateDescription)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Category field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Category")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Category", selection: $templateCategory) {
                                        ForEach(categories, id: \.self) { category in
                                            Text(category).tag(category)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                // Amount field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Amount (€)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter amount", text: $templateAmount)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                        .transition(.scale)
                    }
                }
            )
        }
    }
    
    // Save a new template
    private func saveNewTemplate() {
        let amount = Double(templateAmount) ?? 100.0
        
        let template = ExpenseTemplate(
            name: templateName,
            description: templateDescription,
            category: templateCategory,
            amount: amount
        )
        
        templateManager.addExpenseTemplate(template)
    }
    
    // Update an existing template
    private func updateTemplate() {
        guard let template = editingTemplate else { return }
        
        let amount = Double(templateAmount) ?? template.amount
        
        let updatedTemplate = ExpenseTemplate(
            id: template.id,
            name: templateName,
            description: templateDescription,
            category: templateCategory,
            amount: amount,
            isDefault: template.isDefault
        )
        
        templateManager.updateExpenseTemplate(updatedTemplate)
    }
}

// MARK: - Tax Templates UI Components

/// View for showing tax templates
struct TaxTemplatesView: View {
    @EnvironmentObject var templateManager: TemplateManager
    @Binding var isPresented: Bool
    let onSelectTemplate: (TaxTemplate) -> Void
    
    @State private var editingTemplate: TaxTemplate?
    @State private var showingEditDialog = false
    @State private var showingSaveDialog = false
    @State private var templateName = ""
    
    // Current template values for saving or editing
    @State private var templateTaxName = "VAT"
    @State private var templateRate = "19.0"
    
    var body: some View {
        NavigationView {
            TemplateListView(
                title: "Tax Templates",
                items: templateManager.getSortedTaxTemplates(),
                itemLabel: { $0.name },
                itemSubtitle: { 
                    "\($0.taxName) @ \(Formatters.formatPercent($0.rate))"
                },
                onSelect: { template in
                    onSelectTemplate(template)
                    isPresented = false
                },
                onEdit: { template in
                    editingTemplate = template
                    templateName = template.name
                    templateTaxName = template.taxName
                    templateRate = String(format: "%.1f", template.rate)
                    showingEditDialog = true
                },
                onDelete: { template in
                    if !template.isDefault {
                        templateManager.deleteTaxTemplate(id: template.id)
                    }
                },
                onAdd: {
                    templateName = ""
                    templateTaxName = "VAT"
                    templateRate = "19.0"
                    showingSaveDialog = true
                }
            )
            .navigationTitle("Tax Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .overlay(
                Group {
                    if showingSaveDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingSaveDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingSaveDialog,
                            title: "Save Tax Template",
                            templateName: $templateName,
                            onSave: saveNewTemplate
                        ) {
                            // Content
                            VStack(spacing: 16) {
                                // Tax name field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tax Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter tax name", text: $templateTaxName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Common tax names
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(["VAT", "GST", "Sales Tax", "Service Tax", "Import Tax"], id: \.self) { name in
                                            Button(action: { templateTaxName = name }) {
                                                Text(name)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(templateTaxName == name ? Color.blue : Color.gray.opacity(0.2))
                                                    .foregroundColor(templateTaxName == name ? .white : .primary)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                
                                // Rate field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rate (%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter rate", text: $templateRate)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Common rates
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([5.0, 7.0, 10.0, 15.0, 19.0, 20.0], id: \.self) { rate in
                                            Button(action: { templateRate = String(format: "%.1f", rate) }) {
                                                Text(Formatters.formatPercent(rate))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Double(templateRate) == rate ? Color.blue : Color.gray.opacity(0.2))
                                                    .foregroundColor(Double(templateRate) == rate ? .white : .primary)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .transition(.scale)
                    }
                    
                    if showingEditDialog {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingEditDialog = false
                            }
                        
                        SaveTemplateDialog(
                            isPresented: $showingEditDialog,
                            title: "Edit Tax Template",
                            templateName: $templateName,
                            onSave: updateTemplate
                        ) {
                            // Content - same as save dialog
                            VStack(spacing: 16) {
                                // Tax name field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tax Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter tax name", text: $templateTaxName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Common tax names
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(["VAT", "GST", "Sales Tax", "Service Tax", "Import Tax"], id: \.self) { name in
                                            Button(action: { templateTaxName = name }) {
                                                Text(name)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(templateTaxName == name ? Color.blue : Color.gray.opacity(0.2))
                                                    .foregroundColor(templateTaxName == name ? .white : .primary)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                
                                // Rate field
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rate (%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter rate", text: $templateRate)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Common rates
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([5.0, 7.0, 10.0, 15.0, 19.0, 20.0], id: \.self) { rate in
                                            Button(action: { templateRate = String(format: "%.1f", rate) }) {
                                                Text(Formatters.formatPercent(rate))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Double(templateRate) == rate ? Color.blue : Color.gray.opacity(0.2))
                                                    .foregroundColor(Double(templateRate) == rate ? .white : .primary)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .transition(.scale)
                    }
                }
            )
        }
    }
    
    // Save a new template
    private func saveNewTemplate() {
        let rate = Double(templateRate) ?? 19.0
        
        let template = TaxTemplate(
            name: templateName,
            taxName: templateTaxName,
            rate: rate
        )
        
        templateManager.addTaxTemplate(template)
    }
    
    // Update an existing template
    private func updateTemplate() {
        guard let template = editingTemplate else { return }
        
        let rate = Double(templateRate) ?? template.rate
        
        let updatedTemplate = TaxTemplate(
            id: template.id,
            name: templateName,
            taxName: templateTaxName,
            rate: rate,
            isDefault: template.isDefault
        )
        
        templateManager.updateTaxTemplate(updatedTemplate)
    }
}

// MARK: - Quick Save Button

/// Floating button for saving the current form as a template
struct SaveTemplateButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "bookmark.fill")
                Text("Save as Template")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(radius: 3)
        }
    }
}

// MARK: - Templates Button

/// Button to open the templates view
struct TemplatesButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                Text("Templates")
            }
        }
    }
}