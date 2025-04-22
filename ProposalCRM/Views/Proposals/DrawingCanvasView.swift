//
//  DrawingCanvasView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 22.04.2025.
//


// DrawingCanvasView.swift
// View for creating and editing drawings with Apple Pencil

import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Environment(\.managedObjectContext) private var viewContext
    var proposal: Proposal
    var drawing: Data?
    
    @State private var canvasView = PKCanvasView()
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Configure canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        
        // Load any existing drawing
        if let drawing = drawing, let pkDrawing = try? PKDrawing(data: drawing) {
            canvasView.drawing = pkDrawing
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: DrawingCanvasView
        
        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Save the drawing to the proposal when it changes
            DispatchQueue.main.async {
                let drawing = canvasView.drawing
                self.parent.proposal.drawingData = drawing.dataRepresentation()
                self.parent.proposal.hasDrawingNotes = true
                
                do {
                    try self.parent.viewContext.save()
                } catch {
                    print("Error saving drawing: \(error)")
                }
            }
        }
    }
}