// AttachmentModel.swift
// Model definition for Attachment entity in Core Data

import Foundation
import CoreData

// This extension should be added to define the Core Data model programmatically
// The actual entity would need to be added to the xcdatamodeld file

extension Attachment {
    // Convenience initializer for creating attachments
    static func create(in context: NSManagedObjectContext,
                      fileName: String,
                      fileType: String,
                      fileURL: String?,
                      fileData: Data?,
                      fileSize: Int64,
                      proposal: Proposal) -> Attachment {
        let attachment = Attachment(context: context)
        attachment.id = UUID()
        attachment.fileName = fileName
        attachment.fileType = fileType
        attachment.fileURL = fileURL
        attachment.fileData = fileData
        attachment.fileSize = fileSize
        attachment.addedDate = Date()
        attachment.proposal = proposal
        return attachment
    }
    
    // Formatted file name with icon
    var formattedFileName: String {
        return fileName ?? "Unknown File"
    }
    
    // Formatted date
    var formattedDate: String {
        guard let date = addedDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Formatted file size
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    // Get file URL if available
    var url: URL? {
        guard let urlString = fileURL else { return nil }
        return URL(string: urlString)
    }
    
    // Check if file exists
    var fileExists: Bool {
        guard let url = url else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
