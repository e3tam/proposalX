// AttachmentsSection.swift - FIXED VERSION with QuickLook Preview Fix
// Section for displaying and managing attachments in proposal detail view

import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import CoreData

struct AttachmentsSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var proposal: Proposal
    @State private var isShowingDocumentPicker = false
    @State private var isShowingPreview = false
    @State private var previewItem: PreviewItem?
    @State private var attachmentToDelete: Attachment?
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Force refresh state
    @State private var refreshId = UUID()
    
    // Dynamic colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.1) : Color(UIColor.tertiarySystemBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color(UIColor.secondarySystemBackground)
    }
    
    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.systemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    // Real-time fetched results for attachments
    @FetchRequest private var attachments: FetchedResults<Attachment>
    
    // Initialize with specific proposal filter
    init(proposal: Proposal) {
        self.proposal = proposal
        
        // Create a fetch request filtered to this proposal's attachments
        let request: NSFetchRequest<Attachment> = Attachment.fetchRequest()
        request.predicate = NSPredicate(format: "proposal == %@", proposal)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Attachment.addedDate, ascending: false)]
        
        // Initialize the fetch request with this proposal-specific request
        _attachments = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Attachments")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                if !attachments.isEmpty {
                    Text("(\(attachments.count))")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    Label("Add", systemImage: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            // Attachments table view
            if attachments.isEmpty {
                emptyAttachmentsView()
            } else {
                attachmentsTableView()
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $isShowingDocumentPicker) {
            EnhancedDocumentPicker(proposal: proposal)
                .onDisappear {
                    // Force a refresh when document picker is dismissed
                    refreshId = UUID()
                }
        }
        .sheet(isPresented: $isShowingPreview) {
            if let previewItem = previewItem {
                ImprovedQuickLookPreview(item: previewItem)
            }
        }
        .alert("Delete Attachment?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let attachment = attachmentToDelete {
                    deleteAttachment(attachment)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this attachment?")
        }
        .id(refreshId) // Force refresh when ID changes
    }
    
    private func emptyAttachmentsView() -> some View {
        Text("No attachments added yet")
            .foregroundColor(secondaryTextColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
    }
    
    private func attachmentsTableView() -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("File Name")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                
                Text("Type")
                    .frame(width: 80, alignment: .center)
                
                Text("Size")
                    .frame(width: 80, alignment: .trailing)
                
                Text("Date Added")
                    .frame(width: 120, alignment: .trailing)
                
                Text("Actions")
                    .frame(width: 100, alignment: .center)
                    .padding(.trailing, 8)
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(primaryTextColor)
            .padding(.vertical, 8)
            .background(headerBackgroundColor)
            
            // Attachment rows with direct FetchedResults access
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(attachments, id: \.self) { attachment in
                        AttachmentRowView(
                            attachment: attachment,
                            colorScheme: colorScheme,
                            rowBackgroundColor: rowBackgroundColor,
                            primaryTextColor: primaryTextColor,
                            onOpen: {
                                openAttachment(attachment)
                            },
                            onDelete: {
                                attachmentToDelete = attachment
                                showDeleteConfirmation = true
                            }
                        )
                        
                        Divider().background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                    }
                }
            }
        }
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func openAttachment(_ attachment: Attachment) {
        // First try to create a preview item from the file URL
        if let fileURLString = attachment.fileURL, let fileURL = URL(string: fileURLString) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("Opening file from URL: \(fileURL.path)")
                let item = PreviewItem(url: fileURL, title: attachment.fileName ?? "File")
                self.previewItem = item
                self.isShowingPreview = true
                return
            }
        }
        
        // If file URL doesn't work, try using the file data
        if let fileData = attachment.fileData, let fileName = attachment.fileName {
            print("Creating temporary file for preview from data")
            let fileExtension = (attachment.fileType?.isEmpty ?? true) ? "dat" : attachment.fileType!
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "\(UUID().uuidString).\(fileExtension)"
            )
            
            do {
                try fileData.write(to: tempURL)
                print("Temporary file created at: \(tempURL.path)")
                let item = PreviewItem(url: tempURL, title: fileName)
                self.previewItem = item
                self.isShowingPreview = true
            } catch {
                print("Error creating temporary file: \(error)")
            }
        }
    }
    
    private func deleteAttachment(_ attachment: Attachment) {
        // Remove the file if it's stored locally
        if let url = attachment.fileURL, let fileURL = URL(string: url) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Delete from Core Data
        viewContext.delete(attachment)
        do {
            try viewContext.save()
            // Log activity
            ActivityLogger.logItemAdded(
                proposal: proposal,
                context: viewContext,
                itemType: "Attachment Removed",
                itemName: attachment.fileName ?? "Attachment"
            )
            
            // Force UI refresh
            refreshId = UUID()
        } catch {
            print("Error deleting attachment: \(error)")
        }
    }
}

// Custom preview item that properly conforms to QLPreviewItem
// Custom preview item that properly conforms to QLPreviewItem
class PreviewItem: NSObject, QLPreviewItem {
    // Changed to optional URL to match the protocol requirement
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL, title: String) {
        self.previewItemURL = url
        self.previewItemTitle = title
        super.init()
    }
}

// Improved QuickLook Preview controller with proper item handling
struct ImprovedQuickLookPreview: UIViewControllerRepresentable {
    var item: PreviewItem
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // Reload when item changes
        uiViewController.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: ImprovedQuickLookPreview
        
        init(_ parent: ImprovedQuickLookPreview) {
            self.parent = parent
            super.init()
            
            // Debug the file - safely unwrap the optional URL
            if let url = parent.item.previewItemURL {
                print("Preview URL: \(url.path)")
                print("File exists: \(FileManager.default.fileExists(atPath: url.path))")
            } else {
                print("No preview URL available")
            }
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.item
        }
        
        // Handle errors
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            print("Preview controller dismissed")
        }
    }
}

// Separate component for attachment row to improve performance
struct AttachmentRowView: View {
    let attachment: Attachment
    let colorScheme: ColorScheme
    let rowBackgroundColor: Color
    let primaryTextColor: Color
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // File icon and name
            HStack {
                Image(systemName: iconForFileType(attachment.fileType ?? ""))
                    .foregroundColor(colorForFileType(attachment.fileType ?? ""))
                Text(attachment.fileName ?? "Unknown")
                    .font(.system(size: 14))
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
            
            // File type
            Text(attachment.fileType?.uppercased() ?? "")
                .font(.system(size: 12))
                .frame(width: 80, alignment: .center)
            
            // File size
            Text(formatFileSize(attachment.fileSize))
                .font(.system(size: 14))
                .frame(width: 80, alignment: .trailing)
            
            // Date added
            Text(formatDate(attachment.addedDate))
                .font(.system(size: 12))
                .frame(width: 120, alignment: .trailing)
            
            // Actions
            HStack(spacing: 10) {
                Button(action: onOpen) {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 100, alignment: .center)
            .padding(.trailing, 8)
        }
        .foregroundColor(primaryTextColor)
        .padding(.vertical, 8)
        .background(rowBackgroundColor)
    }
    
    // Helper functions
    private func iconForFileType(_ fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.fill"
        case "doc", "docx":
            return "doc.text.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal.fill"
        case "jpg", "jpeg", "png", "gif":
            return "photo.fill"
        case "zip", "rar":
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }
    
    private func colorForFileType(_ fileType: String) -> Color {
        switch fileType.lowercased() {
        case "pdf":
            return .red
        case "doc", "docx":
            return .blue
        case "xls", "xlsx":
            return .green
        case "ppt", "pptx":
            return .orange
        case "jpg", "jpeg", "png", "gif":
            return .purple
        case "zip", "rar":
            return .gray
        default:
            return .blue
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Enhanced Document Picker with improved debugging and logging
struct EnhancedDocumentPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    var proposal: Proposal
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .pdf,
            .image,
            .text,
            .spreadsheet,
            .presentation,
            .zip,
            .archive
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: EnhancedDocumentPicker
        
        init(_ parent: EnhancedDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("Document picker selected \(urls.count) files")
            
            for url in urls {
                // Security check
                guard url.startAccessingSecurityScopedResource() else {
                    print("Access denied to file: \(url.lastPathComponent)")
                    continue
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                do {
                    print("Processing file: \(url.lastPathComponent)")
                    
                    // Get file attributes
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = fileAttributes[.size] as? Int64 ?? 0
                    print("File size: \(fileSize) bytes")
                    
                    // Create a permanent copy of the file in the app's documents directory
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    
                    // Create a unique filename to avoid conflicts
                    let uniqueFileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
                    let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)
                    print("Saving to: \(destinationURL.path)")
                    
                    // Copy the file
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    print("File copied successfully")
                    
                    // Create the attachment in Core Data
                    let attachment = Attachment(context: self.parent.viewContext)
                    attachment.id = UUID()
                    attachment.fileName = url.lastPathComponent
                    attachment.fileType = url.pathExtension
                    attachment.fileURL = destinationURL.absoluteString
                    attachment.fileSize = fileSize
                    attachment.addedDate = Date()
                    attachment.proposal = self.parent.proposal
                    
                    print("Created attachment entity - fileName: \(String(describing: attachment.fileName)), fileType: \(String(describing: attachment.fileType))")
                    
                    // Save the context
                    try self.parent.viewContext.save()
                    print("Context saved successfully")
                    
                    // Log activity
                    ActivityLogger.logItemAdded(
                        proposal: self.parent.proposal,
                        context: self.parent.viewContext,
                        itemType: "Attachment",
                        itemName: url.lastPathComponent
                    )
                    
                    print("Activity logged")
                } catch {
                    print("Error processing file: \(error)")
                }
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
