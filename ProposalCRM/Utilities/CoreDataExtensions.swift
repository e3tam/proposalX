// CoreDataExtensions.swift
// Extensions for Core Data model to support attachments and drawing notes

import Foundation
import CoreData
import SwiftUI

// MARK: - Proposal Extensions for Attachments and Drawing Notes
extension Proposal {
    // Helper to check and update drawing status
    func updateDrawingNotesStatus() {
        // Update the hasDrawingNotes flag based on drawing data
        self.hasDrawingNotes = drawingData != nil && !(drawingData?.isEmpty ?? true)
    }
    
    // Attachments relationship accessor
    var attachmentsArray: [Attachment] {
        let set = attachments as? Set<Attachment> ?? []
        return set.sorted {
            $0.addedDate ?? Date() > $1.addedDate ?? Date()
        }
    }
}
