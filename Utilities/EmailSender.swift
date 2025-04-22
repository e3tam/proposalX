// EmailSender.swift
// Provides email sending functionality for proposal details with Turkish translations

import SwiftUI
import MessageUI

struct EmailSender: UIViewControllerRepresentable {
    let proposal: Proposal
    let toRecipients: [String]
    var completion: (Result<MFMailComposeResult, Error>) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        if !MFMailComposeViewController.canSendMail() {
            print("Cannot send email - device not configured for email")
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        // Set up email
        let subject = "Teklif \(proposal.formattedNumber) - \(proposal.customerName)"
        mailComposer.setSubject(subject)
        mailComposer.setToRecipients(toRecipients)
        
        // Generate email body with comprehensive proposal details
        let emailBody = generateEmailBody()
        mailComposer.setMessageBody(emailBody, isHTML: true)
        
        // Attempt to attach PDF if available
        if let pdfData = PDFGenerator.generateProposalPDF(from: proposal) {
            let fileName = "Teklif_\(proposal.formattedNumber).pdf"
            mailComposer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: fileName)
        }
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: EmailSender
        
        init(_ parent: EmailSender) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.completion(.failure(error))
            } else {
                parent.completion(.success(result))
            }
            controller.dismiss(animated: true)
        }
    }
    
    private func generateEmailBody() -> String {
        // Create a detailed HTML email with all proposal information
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: Arial, sans-serif; color: #333; line-height: 1.6; }
                .container { max-width: 800px; margin: 0 auto; padding: 20px; }
                h1 { color: #2c3e50; font-size: 24px; }
                h2 { color: #3498db; font-size: 18px; margin-top: 20px; border-bottom: 1px solid #eee; padding-bottom: 8px; }
                .section { background-color: #f9f9f9; border-radius: 8px; padding: 15px; margin-bottom: 20px; }
                table { width: 100%; border-collapse: collapse; margin: 15px 0; }
                th { background-color: #f2f2f2; text-align: left; padding: 8px; border: 1px solid #ddd; }
                td { padding: 8px; border: 1px solid #ddd; }
                .total { font-weight: bold; background-color: #eaf2f8; }
                .subtotal { background-color: #f8f9fa; }
                .profit-positive { color: green; }
                .profit-negative { color: red; }
                .notes { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #3498db; margin-top: 15px; }
                .breakdown { background-color: #fff8e1; padding: 10px; border-radius: 4px; margin-top: 10px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Teklif (Proposal) \(proposal.formattedNumber)</h1>
                
                <div class="section">
                    <h2>Müşteri Bilgileri (Customer Information)</h2>
                    <table>
                        <tr>
                            <th width="30%">Müşteri (Customer)</th>
                            <td>\(proposal.customerName)</td>
                        </tr>
        """
        
        // Add customer details if available
        if let customer = proposal.customer {
            if let contactName = customer.contactName, !contactName.isEmpty {
                html += """
                    <tr>
                        <th>İlgili Kişi (Contact)</th>
                        <td>\(contactName)</td>
                    </tr>
                """
            }
            
            if let email = customer.email, !email.isEmpty {
                html += """
                    <tr>
                        <th>E-posta (Email)</th>
                        <td><a href="mailto:\(email)">\(email)</a></td>
                    </tr>
                """
            }
            
            if let phone = customer.phone, !phone.isEmpty {
                html += """
                    <tr>
                        <th>Telefon (Phone)</th>
                        <td>\(phone)</td>
                    </tr>
                """
            }
            
            if let address = customer.address, !address.isEmpty {
                html += """
                    <tr>
                        <th>Adres (Address)</th>
                        <td>\(address)</td>
                    </tr>
                """
            }
        }
        
        // Proposal details
        html += """
                </table>
                </div>
                
                <div class="section">
                    <h2>Teklif Detayları (Proposal Details)</h2>
                    <table>
                        <tr>
                            <th width="30%">Teklif Numarası (Proposal Number)</th>
                            <td>\(proposal.formattedNumber)</td>
                        </tr>
                        <tr>
                            <th>Tarih (Date)</th>
                            <td>\(proposal.formattedDate)</td>
                        </tr>
                        <tr>
                            <th>Durum (Status)</th>
                            <td>\(proposal.formattedStatus)</td>
                        </tr>
                    </table>
                </div>
        """
        
        // Products with ALL headers
        if !proposal.itemsArray.isEmpty {
            html += """
                <div class="section">
                    <h2>Ürünler (Products)</h2>
                    <table>
                        <tr>
                            <th>Kod (Code)</th>
                            <th>Ürün (Product)</th>
                            <th>Miktar (Qty)</th>
                            <th>Liste Fiyatı (List Price)</th>
                            <th>Birim Fiyat (Unit Price)</th>
                            <th>İndirim (Discount)</th>
                            <th>Çarpan (Multiplier)</th>
                            <th>Tutar (Amount)</th>
                        </tr>
            """
            
            for item in proposal.itemsArray {
                let multiplier = (item.unitPrice / max(item.product?.listPrice ?? 1, 0.01))
                html += """
                    <tr>
                        <td>\(item.product?.code ?? "")</td>
                        <td>\(item.productName)</td>
                        <td>\(Int(item.quantity))</td>
                        <td>\(Formatters.formatEuro(item.product?.listPrice ?? 0))</td>
                        <td>\(Formatters.formatEuro(item.unitPrice))</td>
                        <td>\(Formatters.formatPercent(item.discount))</td>
                        <td>\(String(format: "%.2f", multiplier))x</td>
                        <td>\(Formatters.formatEuro(item.amount))</td>
                    </tr>
                """
            }
            
            html += """
                    <tr class="subtotal">
                        <td colspan="7" align="right"><strong>Ara Toplam (Subtotal)</strong></td>
                        <td><strong>\(Formatters.formatEuro(proposal.subtotalProducts))</strong></td>
                    </tr>
                </table>
                </div>
            """
        }
        
        // Engineering
        if !proposal.engineeringArray.isEmpty {
            html += """
                <div class="section">
                    <h2>Mühendislik Hizmetleri (Engineering Services)</h2>
                    <table>
                        <tr>
                            <th>Açıklama (Description)</th>
                            <th>Gün (Days)</th>
                            <th>Oran (Rate)</th>
                            <th>Tutar (Amount)</th>
                        </tr>
            """
            
            for engineering in proposal.engineeringArray {
                html += """
                    <tr>
                        <td>\(engineering.desc ?? "")</td>
                        <td>\(String(format: "%.1f", engineering.days))</td>
                        <td>\(Formatters.formatEuro(engineering.rate))</td>
                        <td>\(Formatters.formatEuro(engineering.amount))</td>
                    </tr>
                """
            }
            
            html += """
                    <tr class="subtotal">
                        <td colspan="3" align="right"><strong>Mühendislik Ara Toplamı (Engineering Subtotal)</strong></td>
                        <td><strong>\(Formatters.formatEuro(proposal.subtotalEngineering))</strong></td>
                    </tr>
                </table>
                </div>
            """
        }
        
        // Expenses
        if !proposal.expensesArray.isEmpty {
            html += """
                <div class="section">
                    <h2>Giderler (Expenses)</h2>
                    <table>
                        <tr>
                            <th>Açıklama (Description)</th>
                            <th>Tutar (Amount)</th>
                        </tr>
            """
            
            for expense in proposal.expensesArray {
                html += """
                    <tr>
                        <td>\(expense.desc ?? "")</td>
                        <td>\(Formatters.formatEuro(expense.amount))</td>
                    </tr>
                """
            }
            
            html += """
                    <tr class="subtotal">
                        <td align="right"><strong>Giderler Ara Toplamı (Expenses Subtotal)</strong></td>
                        <td><strong>\(Formatters.formatEuro(proposal.subtotalExpenses))</strong></td>
                    </tr>
                </table>
                </div>
            """
        }
        
        // Custom Taxes
        if !proposal.taxesArray.isEmpty {
            html += """
                <div class="section">
                    <h2>Özel Vergiler (Custom Taxes)</h2>
                    <table>
                        <tr>
                            <th>Vergi Adı (Tax Name)</th>
                            <th>Oran (Rate)</th>
                            <th>Tutar (Amount)</th>
                        </tr>
            """
            
            for tax in proposal.taxesArray {
                html += """
                    <tr>
                        <td>\(tax.name ?? "")</td>
                        <td>\(Formatters.formatPercent(tax.rate))</td>
                        <td>\(Formatters.formatEuro(tax.amount))</td>
                    </tr>
                """
            }
            
            html += """
                    <tr class="subtotal">
                        <td colspan="2" align="right"><strong>Vergiler Ara Toplamı (Taxes Subtotal)</strong></td>
                        <td><strong>\(Formatters.formatEuro(proposal.subtotalTaxes))</strong></td>
                    </tr>
                </table>
                </div>
            """
        }
        
        // Financial Summary
        let partnerCost = calculatePartnerCost(proposal)
        let grossProfit = proposal.totalAmount - partnerCost
        let profitMargin = proposal.totalAmount > 0 ? (grossProfit / proposal.totalAmount) * 100 : 0
        let profitClass = grossProfit >= 0 ? "profit-positive" : "profit-negative"
        
        html += """
            <div class="section">
                <h2>Finansal Özet (Financial Summary)</h2>
                <table>
                    <tr>
                        <th width="30%">Ara Toplamlar (Subtotals)</th>
                        <th width="30%">Maliyet Detayları (Cost Details)</th>
                        <th width="40%">Kâr Analizi (Profit Analysis)</th>
                    </tr>
                    <tr>
                        <td>
                            <strong>Ürünler (Products):</strong> \(Formatters.formatEuro(proposal.subtotalProducts))<br>
                            <strong>Mühendislik (Engineering):</strong> \(Formatters.formatEuro(proposal.subtotalEngineering))<br>
                            <strong>Giderler (Expenses):</strong> \(Formatters.formatEuro(proposal.subtotalExpenses))<br>
                            <strong>Vergiler (Taxes):</strong> \(Formatters.formatEuro(proposal.subtotalTaxes))
                        </td>
                        <td>
        """
        
        // Detailed cost breakdown section
        let productsCost = proposal.itemsArray.reduce(0.0) { total, item in
            return total + ((item.product?.partnerPrice ?? 0) * item.quantity)
        }
        
        html += """
                            <strong>Ürün Maliyeti (Product Cost):</strong> \(Formatters.formatEuro(productsCost))<br>
                            <strong>Gider Maliyeti (Expenses Cost):</strong> \(Formatters.formatEuro(proposal.subtotalExpenses))<br>
                            <div class="breakdown">
                                <em>Ürün Detayları (Product Details):</em><br>
        """
        
        // Add product cost details
        for item in proposal.itemsArray {
            let partnerPrice = item.product?.partnerPrice ?? 0
            let cost = partnerPrice * item.quantity
            let unitMargin = item.unitPrice - partnerPrice
            let itemProfit = item.amount - cost
            let itemMargin = item.amount > 0 ? (itemProfit / item.amount) * 100 : 0
            
            html += """
                    \(item.productName): \(Int(item.quantity)) × \(Formatters.formatEuro(partnerPrice)) = \(Formatters.formatEuro(cost))<br>
                    <small>Birim Marj (Unit Margin): \(Formatters.formatEuro(unitMargin)) | 
                    Kâr (Profit): \(Formatters.formatEuro(itemProfit)) | 
                    Marj (Margin): \(Formatters.formatPercent(itemMargin))</small><br>
            """
        }
        
        html += """
                            </div>
                        </td>
                        <td>
                            <strong>Toplam Gelir (Total Revenue):</strong> \(Formatters.formatEuro(proposal.totalAmount))<br>
                            <strong>Toplam Maliyet (Total Cost):</strong> \(Formatters.formatEuro(partnerCost))<br>
                            <strong class="\(profitClass)">Brüt Kâr (Gross Profit):</strong> <span class="\(profitClass)">\(Formatters.formatEuro(grossProfit))</span><br>
                            <strong class="\(profitClass)">Kâr Marjı (Profit Margin):</strong> <span class="\(profitClass)">\(Formatters.formatPercent(profitMargin))</span>
                        </td>
                    </tr>
                </table>
                
                <table style="margin-top: 20px">
                    <tr class="total">
                        <th width="70%">GENEL TOPLAM (TOTAL AMOUNT)</th>
                        <th width="30%">\(Formatters.formatEuro(proposal.totalAmount))</th>
                    </tr>
                </table>
            </div>
        """
        
        // Notes
        if let notes = proposal.notes, !notes.isEmpty {
            html += """
                <div class="section">
                    <h2>Notlar (Notes)</h2>
                    <div class="notes">
                        \(notes.replacingOccurrences(of: "\n", with: "<br>"))
                    </div>
                </div>
            """
        }
        
        // Footer
        html += """
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Bu teklif ProposalCRM tarafından oluşturulmuştur. (This proposal was generated by ProposalCRM)<br>
                    Sorularınız için lütfen bizimle iletişime geçin. (For any questions, please contact us)
                </p>
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    // Calculate partner cost for the proposal
    private func calculatePartnerCost(_ proposal: Proposal) -> Double {
        var totalCost = 0.0
        
        // Sum partner cost for all products
        for item in proposal.itemsArray {
            let partnerPrice = item.product?.partnerPrice ?? 0
            totalCost += partnerPrice * item.quantity
        }
        
        // Add expenses
        totalCost += proposal.subtotalExpenses
        
        return totalCost
    }
}

// Extension to check if mail can be sent
extension View {
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
}
