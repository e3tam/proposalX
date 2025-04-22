// ExportButtonGroup.swift
// Floating export buttons for PDF and email

import SwiftUI
import CoreData
import PDFKit
import UIKit
import MessageUI

struct ExportButtonGroup: View {
    @ObservedObject var proposal: Proposal
    
    // PDF Export state variables
    @State private var showingPdfPreview = false
    @State private var pdfUrl: URL?
    @State private var isGeneratingPdf = false
    
    // Email state variables
    @State private var showingEmailSender = false
    @State private var emailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingEmailAlert = false
    @State private var emailAlertMessage = ""
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    emailExportButton
                    pdfExportButton
                }
                .padding(.bottom, 30)
                .padding(.trailing, 20)
            }
        }
        .sheet(isPresented: $showingPdfPreview) {
            if let url = pdfUrl {
                PDFPreviewView(url: url)
            }
        }
        .sheet(isPresented: $showingEmailSender) {
            EmailSender(
                proposal: proposal,
                toRecipients: proposal.customer?.email?.isEmpty == false ? [proposal.customer!.email!] : [],
                completion: { result in
                    self.emailResult = result
                    
                    switch result {
                    case .success(let mailResult):
                        switch mailResult {
                        case .sent:
                            emailAlertMessage = "Email sent successfully!"
                        case .saved:
                            emailAlertMessage = "Email saved as draft."
                        case .cancelled:
                            // Don't show alert for cancelled
                            return
                        case .failed:
                            emailAlertMessage = "Failed to send email."
                        @unknown default:
                            emailAlertMessage = "Unknown result."
                        }
                    case .failure(let error):
                        emailAlertMessage = "Error: \(error.localizedDescription)"
                    }
                    
                    // Only show alert for non-cancelled results
                    if case .success(let mailResult) = result, mailResult != .cancelled {
                        showingEmailAlert = true
                    }
                }
            )
        }
        .alert(isPresented: $showingEmailAlert) {
            Alert(
                title: Text("Email Result"),
                message: Text(emailAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // PDF Export Button
    var pdfExportButton: some View {
        Button(action: {
            exportToPdf()
        }) {
            HStack {
                Image(systemName: "doc.text")
                Text("Export PDF")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
        }
        .disabled(isGeneratingPdf)
        .overlay(
            isGeneratingPdf ?
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .padding(.trailing, 8)
            : nil
        )
    }
    
    // Email Export Button
    var emailExportButton: some View {
        Button(action: {
            if MFMailComposeViewController.canSendMail() {
                showingEmailSender = true
            } else {
                emailAlertMessage = "Your device is not configured to send emails. Please set up an email account in your mail app."
                showingEmailAlert = true
            }
        }) {
            HStack {
                Image(systemName: "envelope")
                Text("Send Email")
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
        }
    }
    
    // PDF Export function
    private func exportToPdf() {
        isGeneratingPdf = true
        
        // Generate PDF in background
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfData = PDFGenerator.generateProposalPDF(from: proposal) {
                let fileName = "Proposal_\(proposal.formattedNumber)_\(Date().timeIntervalSince1970).pdf"
                if let url = PDFGenerator.savePDF(pdfData, fileName: fileName) {
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        self.pdfUrl = url
                        self.isGeneratingPdf = false
                        self.showingPdfPreview = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isGeneratingPdf = false
                        // Handle error - could add alert here
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isGeneratingPdf = false
                    // Handle error - could add alert here
                }
            }
        }
    }
}

// PDF Preview View
struct PDFPreviewView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            PDFKitView(url: url)
                .navigationTitle("Proposal PDF")
                .navigationBarItems(
                    leading: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                )
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: [url])
                }
        }
    }
}

// PDFKit wrapper
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Nothing to update
    }
}

// ShareSheet view
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}