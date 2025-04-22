//
//  AttachmentsView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 17.04.2025.
//

// AttachmentsView.swift
// Manage file attachments for proposals

import SwiftUI
import UniformTypeIdentifiers

struct ProposalAttachment: Identifiable {
    let id = UUID()
    let name: String
    let fileType: String
    let date: Date
    var fileSize: Int64
    var url: URL?
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var iconName: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.fill"
        case "jpg", "jpeg", "png", "heic":
            return "photo.fill"
        case "doc", "docx":
            return "doc.text.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal.fill"
        default:
            return "doc.fill"
        }
    }
    
    var color: Color {
        switch fileType.lowercased() {
        case "pdf":
            return .red
        case "jpg", "jpeg", "png", "heic":
            return .blue
        case "doc", "docx":
            return .indigo
        case "xls", "xlsx":
            return .green
        case "ppt", "pptx":
            return .orange
        default:
            return .gray
        }
    }
}

struct AttachmentsView: View {
    @ObservedObject var proposal: Proposal
    @Binding var attachments: [ProposalAttachment]
    @State private var isShowingDocumentPicker = false
    @State private var selectedAttachment: ProposalAttachment?
    @State private var showingAttachmentOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Attachments")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    Label("Add", systemImage: "paperclip")
                }
            }
            
            Divider()
            
            if attachments.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No attachments yet")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(attachments) { attachment in
                            Button(action: {
                                selectedAttachment = attachment
                                showingAttachmentOptions = true
                            }) {
                                HStack {
                                    Image(systemName: attachment.iconName)
                                        .font(.title2)
                                        .foregroundColor(attachment.color)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(attachment.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            Text(attachment.formattedSize)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text("•")
                                                .foregroundColor(.secondary)
                                            
                                            Text(attachment.formattedDate)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPickerView(attachments: $attachments)
        }
        .actionSheet(isPresented: $showingAttachmentOptions, content: {
            ActionSheet(
                title: Text(selectedAttachment?.name ?? "Attachment"),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("View")) {
                        // View attachment action
                    },
                    .default(Text("Share")) {
                        // Share attachment action
                    },
                    .destructive(Text("Delete")) {
                        if let selected = selectedAttachment,
                           let index = attachments.firstIndex(where: { $0.id == selected.id }) {
                            attachments.remove(at: index)
                        }
                    },
                    .cancel()
                ]
            )
        })
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var attachments: [ProposalAttachment]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .pdf,
            .jpeg,
            .png,
            .text,
            .plainText,
            .image,
            .spreadsheet,
            .presentation
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
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                // Ensure we can access the URL
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Get file attributes
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                    let fileSize = resourceValues.fileSize ?? 0
                    let modificationDate = resourceValues.contentModificationDate ?? Date()
                    
                    // Create attachment
                    let fileName = url.lastPathComponent
                    let fileExtension = url.pathExtension
                    
                    // Copy file to app document directory for persistence
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let destinationURL = documentsDirectory.appendingPathComponent("Attachments/\(UUID().uuidString)-\(fileName)")
                    
                    // Create directory if needed
                    let attachmentsDir = documentsDirectory.appendingPathComponent("Attachments")
                    if !FileManager.default.fileExists(atPath: attachmentsDir.path) {
                        try FileManager.default.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
                    }
                    
                    // Copy the file
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    
                    // Add to attachments
                    let attachment = ProposalAttachment(
                        name: fileName,
                        fileType: fileExtension,
                        date: modificationDate,
                        fileSize: Int64(fileSize),
                        url: destinationURL
                    )
                    
                    parent.attachments.append(attachment)
                } catch {
                    print("Error processing attachment: \(error)")
                }
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
