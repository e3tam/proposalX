//
//  PencilDrawingView.swift
//  ProposalCRM
//
//  Created by Ali Sami Gözükırmızı on 17.04.2025.
//


// PencilDrawingView.swift
// Canvas for Apple Pencil drawing in proposals

import SwiftUI
import PencilKit

struct PencilDrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawingData: Data?
    @Binding var toolPicker: PKToolPicker
    
    let onSave: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        
        // Load drawing if available
        if let drawingData = drawingData {
            do {
                let drawing = try PKDrawing(data: drawingData)
                canvasView.drawing = drawing
            } catch {
                print("Failed to load drawing: \(error)")
            }
        }
        
        // Show the tool picker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Any updates to the canvas view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilDrawingView
        
        init(_ parent: PencilDrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Save the drawing when it changes
            parent.drawingData = canvasView.drawing.dataRepresentation()
            parent.onSave()
        }
    }
}

struct DrawingToolbar: View {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var isDrawing: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                canvasView.drawing = PKDrawing()
            }) {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(BorderedButtonStyle())
            
            Spacer()
            
            Button(action: {
                isDrawing.toggle()
                if isDrawing {
                    toolPicker.setVisible(true, forFirstResponder: canvasView)
                    canvasView.becomeFirstResponder()
                } else {
                    toolPicker.setVisible(false, forFirstResponder: canvasView)
                }
            }) {
                Label(isDrawing ? "Done" : "Edit", systemImage: isDrawing ? "checkmark" : "pencil")
            }
            .buttonStyle(BorderedButtonStyle())
        }
        .padding(.horizontal)
    }
}

struct PencilNotesView: View {
    @Binding var drawingData: Data?
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var isDrawing = false
    
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Apple Pencil Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isDrawing.toggle()
                    if isDrawing {
                        toolPicker.setVisible(true, forFirstResponder: canvasView)
                        canvasView.becomeFirstResponder()
                    } else {
                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                    }
                }) {
                    Label(isDrawing ? "Done" : "Edit", systemImage: isDrawing ? "checkmark" : "pencil.tip.crop.circle")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            if drawingData == nil && !isDrawing {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "pencil.tip.crop.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Tap Edit to start drawing with Apple Pencil")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                ZStack {
                    // Drawing canvas
                    PencilDrawingView(
                        canvasView: $canvasView,
                        drawingData: $drawingData,
                        toolPicker: $toolPicker,
                        onSave: onSave
                    )
                    .frame(height: 300)
                    
                    // Toolbar overlay at the bottom when in drawing mode
                    if isDrawing {
                        VStack {
                            Spacer()
                            DrawingToolbar(
                                canvasView: $canvasView,
                                toolPicker: $toolPicker,
                                isDrawing: $isDrawing
                            )
                            .background(
                                Rectangle()
                                    .fill(Color(UIColor.systemBackground))
                                    .opacity(0.9)
                            )
                        }
                    }
                }
                .border(Color.gray.opacity(0.3), width: 1)
                .cornerRadius(8)
            }
        }
    }
}