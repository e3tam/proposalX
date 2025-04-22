// DrawingNotesSection.swift
// Section for creating and displaying drawing notes with Apple Pencil support

import SwiftUI
import PencilKit

struct DrawingNotesSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var proposal: Proposal
    @State private var showingDrawingCanvas = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Dynamic colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color(UIColor.secondarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Drawing Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingDrawingCanvas = true
                }) {
                    if proposal.hasDrawingNotes {
                        Label("Edit Drawing", systemImage: "pencil.tip")
                            .foregroundColor(.blue)
                    } else {
                        Label("Add Drawing", systemImage: "pencil.tip")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Drawing preview or placeholder
            if proposal.hasDrawingNotes {
                drawingPreviewView()
            } else {
                emptyDrawingView()
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingDrawingCanvas) {
            NavigationView {
                ImprovedDrawingCanvasView(proposal: proposal)
                    .navigationTitle("Drawing Notes")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingDrawingCanvas = false
                        },
                        trailing: Button("Save") {
                            saveDrawing()
                            showingDrawingCanvas = false
                        }
                    )
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private func emptyDrawingView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 40))
                .foregroundColor(secondaryTextColor)
            
            Text("No drawing notes yet")
                .font(.headline)
                .foregroundColor(secondaryTextColor)
            
            Text("Tap 'Add Drawing' to create notes with Apple Pencil")
                .font(.caption)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(10)
    }
    
    private func drawingPreviewView() -> some View {
        ZStack {
            // First check if we can create a drawing from the data
            if let drawingData = proposal.drawingData,
               let pkDrawing = try? PKDrawing(data: drawingData) {
                
                // Create a rendering of the drawing
                DrawingPreviewRenderer(drawing: pkDrawing)
                    .cornerRadius(10)
            } else {
                // Fallback to direct image conversion if PKDrawing creation fails
                if let drawingData = proposal.drawingData,
                   let uiImage = UIImage(data: drawingData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                } else {
                    // Error state
                    Rectangle()
                        .fill(backgroundColor)
                        .cornerRadius(10)
                    
                    Text("Error loading drawing")
                        .foregroundColor(secondaryTextColor)
                }
            }
        }
        .frame(height: 180)
    }
    
    private func saveDrawing() {
        // The actual saving is done in the DrawingCanvasView
        // This method is a placeholder for any additional save logic
        if proposal.hasDrawingNotes {
            ActivityLogger.logProposalUpdated(
                proposal: proposal,
                context: viewContext,
                fieldChanged: "Drawing Notes"
            )
        }
    }
}

// Drawing Preview Renderer to properly render PKDrawing
struct DrawingPreviewRenderer: UIViewRepresentable {
    let drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.isUserInteractionEnabled = false
        canvasView.backgroundColor = .clear
        canvasView.drawing = drawing
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
}

// Improved drawing canvas to ensure we're correctly saving drawing data
struct ImprovedDrawingCanvasView: UIViewRepresentable {
    @Environment(\.managedObjectContext) private var viewContext
    var proposal: Proposal
    
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Configure canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        
        // Load any existing drawing
        if let drawingData = proposal.drawingData,
           let pkDrawing = try? PKDrawing(data: drawingData) {
            canvasView.drawing = pkDrawing
        }
        
        // Setup tool picker
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: ImprovedDrawingCanvasView
        
        init(_ parent: ImprovedDrawingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Save the drawing to the proposal when it changes
            DispatchQueue.main.async {
                let drawing = canvasView.drawing
                
                // Create an image representation as a backup
                let bounds = drawing.bounds.isEmpty ?
                    CGRect(x: 0, y: 0, width: canvasView.bounds.width, height: canvasView.bounds.height) :
                    drawing.bounds
                
                let image = drawing.image(from: bounds, scale: UIScreen.main.scale)
                
                // Save both data representation and image if needed
                self.parent.proposal.drawingData = drawing.dataRepresentation()
                
                // If data representation fails, we'll use the image data
                if self.parent.proposal.drawingData?.isEmpty ?? true,
                   let imageData = image.pngData() {
                    self.parent.proposal.drawingData = imageData
                    print("Using image data as fallback")
                }
                
                self.parent.proposal.hasDrawingNotes = true
                
                do {
                    try self.parent.viewContext.save()
                    print("Drawing saved successfully")
                } catch {
                    print("Error saving drawing: \(error)")
                }
            }
        }
    }
}
