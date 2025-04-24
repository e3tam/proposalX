// File: ProposalCRM/Utilities/PDFGenerator.swift
// Gelişmiş Türkçe PDF Oluşturma Sınıfı - Enhanced Turkish PDF Generator Class

import Foundation
import UIKit
import CoreData
import PDFKit

class PDFGenerator {
    // Ana fonksiyon - teklif verisinden PDF oluşturur
    // Main function to generate a PDF from a proposal
    static func generateProposalPDF(from proposal: Proposal) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "ProposalCRM Uygulaması",
            kCGPDFContextAuthor: "Oluşturulma Tarihi: \(formatDate(Date()))",
            kCGPDFContextTitle: "Teklif \(Formatters.formatProposalNumber(proposal))"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.27 * 72.0 // A4 genişliği (punto)
        let pageHeight = 11.69 * 72.0 // A4 yüksekliği (punto)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 40 // Kenar boşluğu

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { (context) in
            var currentPageY: CGFloat = margin // Sayfanın üst kenarından başla
            var pageNumber = 1 // Sayfa numarası

            // İlk sayfayı başlat
            context.beginPage()

            // --- Başlık ve Müşteri Bilgileri ---
            drawHeaderAndCustomerInfo(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)

            // --- Geçerlilik ve Ödeme Koşulları Bölümü (Yeni Eklendi) ---
            drawTermsSection(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)

            // --- Ürünler Tablosu (Geliştirilmiş) ---
            drawProductsTable(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)

            // --- Mühendislik Tablosu ---
            if !proposal.engineeringArray.isEmpty {
                drawEngineeringTable(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
                pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            }

            // --- Giderler Tablosu ---
            if !proposal.expensesArray.isEmpty {
                drawExpensesTable(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
                pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            }

            // --- Vergiler Tablosu ---
            if !proposal.taxesArray.isEmpty {
                drawCustomTaxesTable(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
                pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            }

            // --- Finansal Özet (Geliştirilmiş) ---
            let financialSummaryHeight: CGFloat = 350 // Geliştirilmiş özet için daha fazla alan
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: financialSummaryHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            drawEnhancedFinancialSummary(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)

            // --- Kategori Analizi (Yeni Eklendi) ---
            drawCategoryAnalysis(context: context, proposal: proposal, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)

            // --- Notlar ---
            if let notes = proposal.notes, !notes.isEmpty {
                 let notesFont = standardFont(size: 10)
                 let notesAttributes = textAttributes(font: notesFont)
                 let textHeight = calculateTextHeight(text: notes, width: pageRect.width - 2 * margin - 10, attributes: notesAttributes)
                 let requiredNotesHeight = textHeight + 60

                 pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: requiredNotesHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
                 drawNotes(context: context, notes: notes, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            }

            // --- Yasal Uyarılar (Yeni Eklendi) ---
            drawLegalDisclaimer(context: context, yPosition: &currentPageY, pageRect: pageRect, margin: margin)
            pageNumber = checkPageBreak(context: context, yPosition: &currentPageY, requiredHeight: 1, pageRect: pageRect, margin: margin, currentPage: pageNumber)

            // --- Altbilgi ---
            drawFooter(context: context.cgContext, pageRect: pageRect, margin: margin, pageNumber: pageNumber, proposal: proposal)
        }
        return data
    }

    // MARK: - Yardımcı Fonksiyonlar (Helper Functions)
    private static func drawText(_ text: String, in rect: CGRect, withAttributes attributes: [NSAttributedString.Key: Any], alignment: NSTextAlignment = .left) {
        let paragraphStyle = NSMutableParagraphStyle(); paragraphStyle.alignment = alignment
        var finalAttributes = attributes; finalAttributes[.paragraphStyle] = paragraphStyle
        (text as NSString).draw(in: rect, withAttributes: finalAttributes)
    }
    
    private static func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor = .darkGray, lineWidth: CGFloat = 0.5) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState(); defer { context.restoreGState() }
        context.setStrokeColor(color.cgColor); context.setLineWidth(lineWidth)
        context.move(to: start); context.addLine(to: end); context.strokePath()
    }
    
    private static func checkPageBreak(context: UIGraphicsPDFRendererContext, yPosition: inout CGFloat, requiredHeight: CGFloat, pageRect: CGRect, margin: CGFloat, currentPage: Int) -> Int {
        var nextPage = currentPage
        if yPosition + requiredHeight > pageRect.height - margin {
            drawFooter(context: context.cgContext, pageRect: pageRect, margin: margin, pageNumber: currentPage, proposal: nil)
            context.beginPage(); yPosition = margin; nextPage += 1
        }
        return nextPage
    }
    
    private static func standardFont(size: CGFloat = 10, weight: UIFont.Weight = .regular) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    private static func textAttributes(font: UIFont, color: UIColor = .black, alignment: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle(); paragraphStyle.alignment = alignment
        return [.font: font, .foregroundColor: color, .paragraphStyle: paragraphStyle]
    }
    
    private static func calculateTextHeight(text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return ceil(boundingBox.height)
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR") // Türkçe tarih formatı
        return formatter.string(from: date)
    }

    // MARK: - Ana Bölüm Çizim Fonksiyonları (Main Section Drawing Functions)

    // Başlık ve Müşteri Bilgileri Bölümü
    private static func drawHeaderAndCustomerInfo(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let detailFont = standardFont(size: 11)
        let headerFont = standardFont(size: 14, weight: .semibold)
        let titleFont = standardFont(size: 24, weight: .bold)
        let detailAttributes = textAttributes(font: detailFont)
        let headerAttributes = textAttributes(font: headerFont)
        let titleAttributes = textAttributes(font: titleFont)
        let proposalTitleAttributes = textAttributes(font: standardFont(size: 20, weight: .semibold))

        // Şirket Adı/Logo (Sol Üst)
        let companyName = "Firma Adınız" // Gerçek veriyle değiştirin
        let companyNameHeight = calculateTextHeight(text: companyName, width: pageRect.width / 2 - margin, attributes: titleAttributes)
        drawText(companyName, in: CGRect(x: margin, y: yPosition, width: pageRect.width / 2 - margin, height: companyNameHeight), withAttributes: titleAttributes)

        // Firma Adresi (Logo Altında)
        let companyAddress = "Adres: Atatürk Cad. No:123, 34000 İstanbul, Türkiye"
        let companyAddressHeight = calculateTextHeight(text: companyAddress, width: pageRect.width / 2 - margin, attributes: detailAttributes)
        drawText(companyAddress, in: CGRect(x: margin, y: yPosition + companyNameHeight + 5, width: pageRect.width / 2 - margin, height: companyAddressHeight), withAttributes: detailAttributes)

        // İletişim (Adres Altında)
        let companyContact = "Tel: +90 212 123 4567 | E-posta: info@firmaadınız.com"
        let companyContactHeight = calculateTextHeight(text: companyContact, width: pageRect.width / 2 - margin, attributes: detailAttributes)
        drawText(companyContact, in: CGRect(x: margin, y: yPosition + companyNameHeight + companyAddressHeight + 10, width: pageRect.width / 2 - margin, height: companyContactHeight), withAttributes: detailAttributes)

        // Teklif Detayları (Sağ)
        let rightAlignX = pageRect.width / 2
        let rightColumnWidth = pageRect.width / 2 - margin

        // Teklif numarası
        let proposalNumber = "Teklif No: \(Formatters.formatProposalNumber(proposal))"
        let propNumHeight = calculateTextHeight(text: proposalNumber, width: rightColumnWidth, attributes: detailAttributes)
        drawText(proposalNumber, in: CGRect(x: rightAlignX, y: yPosition, width: rightColumnWidth, height: propNumHeight), withAttributes: detailAttributes, alignment: .right)
        var currentRightY = yPosition + propNumHeight + 4

        // Teklif tarihi
        let dateString = "Tarih: \(formatDate(proposal.creationDate ?? Date()))"
        let dateHeight = calculateTextHeight(text: dateString, width: rightColumnWidth, attributes: detailAttributes)
        drawText(dateString, in: CGRect(x: rightAlignX, y: currentRightY, width: rightColumnWidth, height: dateHeight), withAttributes: detailAttributes, alignment: .right)
        currentRightY += dateHeight + 4

        // Teklif durumu
        let statusString = "Durum: \(translateStatus(proposal.formattedStatus))"
        let statusHeight = calculateTextHeight(text: statusString, width: rightColumnWidth, attributes: detailAttributes)
        drawText(statusString, in: CGRect(x: rightAlignX, y: currentRightY, width: rightColumnWidth, height: statusHeight), withAttributes: detailAttributes, alignment: .right)
        currentRightY += statusHeight + 4

        // Referans kodu (yeni eklendi)
        let referenceString = "Referans: REF-\(String(format: "%06d", abs(proposal.id?.hashValue ?? 0) % 1000000))"
        let referenceHeight = calculateTextHeight(text: referenceString, width: rightColumnWidth, attributes: detailAttributes)
        drawText(referenceString, in: CGRect(x: rightAlignX, y: currentRightY, width: rightColumnWidth, height: referenceHeight), withAttributes: detailAttributes, alignment: .right)

        // En uzun tarafın altına geç
        let leftContentHeight = yPosition + companyNameHeight + companyAddressHeight + companyContactHeight + 10
        yPosition = max(leftContentHeight, currentRightY + referenceHeight) + 25

        // Teklif Başlığı (Ortada)
        let proposalTitle = "TEKLİF"
        let proposalTitleHeight = calculateTextHeight(text: proposalTitle, width: pageRect.width - 2*margin, attributes: proposalTitleAttributes)
        drawText(proposalTitle, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: proposalTitleHeight), withAttributes: proposalTitleAttributes, alignment: .center)
        yPosition += proposalTitleHeight + 25

        // Müşteri Bilgileri Bölümü
        let customerTitle = "Müşteri Bilgileri"
        let customerTitleHeight = calculateTextHeight(text: customerTitle, width: pageRect.width - 2*margin, attributes: headerAttributes)
        drawText(customerTitle, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: customerTitleHeight), withAttributes: headerAttributes)
        yPosition += customerTitleHeight + 5
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: pageRect.width - margin, y: yPosition))
        yPosition += 10

        // Müşteri detayları
        if let customer = proposal.customer {
            let customerNameString = "Firma: \(customer.formattedName)"
            let customerNameHeight = calculateTextHeight(text: customerNameString, width: pageRect.width - 2*margin, attributes: detailAttributes)
            drawText(customerNameString, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: customerNameHeight), withAttributes: detailAttributes)
            yPosition += customerNameHeight + 5

            if let contactName = customer.contactName, !contactName.isEmpty {
                let contactString = "İlgili Kişi: \(contactName)"
                let contactHeight = calculateTextHeight(text: contactString, width: pageRect.width - 2*margin, attributes: detailAttributes)
                drawText(contactString, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: contactHeight), withAttributes: detailAttributes)
                yPosition += contactHeight + 5
            }
            
            if let email = customer.email, !email.isEmpty {
                let emailString = "E-posta: \(email)"
                let emailHeight = calculateTextHeight(text: emailString, width: pageRect.width - 2*margin, attributes: detailAttributes)
                drawText(emailString, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: emailHeight), withAttributes: detailAttributes)
                yPosition += emailHeight + 5
            }
            
            if let phone = customer.phone, !phone.isEmpty {
                let phoneString = "Telefon: \(phone)"
                let phoneHeight = calculateTextHeight(text: phoneString, width: pageRect.width - 2*margin, attributes: detailAttributes)
                drawText(phoneString, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: phoneHeight), withAttributes: detailAttributes)
                yPosition += phoneHeight + 5
            }
            
            if let address = customer.address, !address.isEmpty {
                let addressString = "Adres: \(address)"
                let addressHeight = calculateTextHeight(text: addressString, width: pageRect.width - 2*margin, attributes: detailAttributes)
                drawText(addressString, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: addressHeight), withAttributes: detailAttributes)
                yPosition += addressHeight + 5
            }
            
            // Vergi numarası (Not: Müşteri modeline vergi no eklemek için CoreData modelinizi güncellemeniz gerekir)
            let taxIDString = "Vergi No: Belirtilmemiş"
            let taxIDHeight = calculateTextHeight(text: taxIDString, width: pageRect.width - 2*margin, attributes: detailAttributes)
            drawText(taxIDString, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: taxIDHeight), withAttributes: detailAttributes)
            yPosition += taxIDHeight + 5
        } else {
            let noCustomerHeight = calculateTextHeight(text: "Müşteri Atanmamış", width: 200, attributes: detailAttributes)
            drawText("Müşteri Atanmamış", in: CGRect(x: margin, y: yPosition, width: 200, height: noCustomerHeight), withAttributes: detailAttributes)
            yPosition += noCustomerHeight + 5
        }

        yPosition += 25 // Sonraki bölüm için boşluk
    }

    // Geçerlilik ve Ödeme Koşulları Bölümü (Yeni Eklendi)
    private static func drawTermsSection(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let contentFont = standardFont(size: 10)
        let headerAttributes = textAttributes(font: sectionFont)
        let contentAttributes = textAttributes(font: contentFont)
        
        // Bölüm başlığı
        let sectionTitle = "Teklif Koşulları"
        let titleHeight = calculateTextHeight(text: sectionTitle, width: tableWidth, attributes: headerAttributes)
        drawText(sectionTitle, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: headerAttributes)
        yPosition += titleHeight + 10
        
        // İçerik kutusu oluştur
        let termsHeight: CGFloat = 120
        let termsRect = CGRect(x: margin, y: yPosition, width: tableWidth, height: termsHeight)
        let boxBackgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        UIGraphicsGetCurrentContext()?.setFillColor(boxBackgroundColor.cgColor)
        UIGraphicsGetCurrentContext()?.fill(termsRect)
        
        // Teklif geçerlilik tarihi (bugünden 30 gün sonra)
        let validUntilDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let validUntil = "Geçerlilik Tarihi: \(formatDate(validUntilDate))"
        let validUntilHeight = calculateTextHeight(text: validUntil, width: tableWidth - 20, attributes: contentAttributes)
        drawText(validUntil, in: CGRect(x: margin + 10, y: yPosition + 10, width: tableWidth - 20, height: validUntilHeight), withAttributes: contentAttributes)
        
        // Ödeme koşulları
        let paymentTerms = "Ödeme Koşulları: %50 sipariş onayında, %50 teslimat öncesi"
        let paymentTermsHeight = calculateTextHeight(text: paymentTerms, width: tableWidth - 20, attributes: contentAttributes)
        drawText(paymentTerms, in: CGRect(x: margin + 10, y: yPosition + 20 + validUntilHeight, width: tableWidth - 20, height: paymentTermsHeight), withAttributes: contentAttributes)
        
        // Teslimat süresi
        let deliveryTime = "Teslimat Süresi: Sipariş onayından itibaren 2-3 hafta"
        let deliveryTimeHeight = calculateTextHeight(text: deliveryTime, width: tableWidth - 20, attributes: contentAttributes)
        drawText(deliveryTime, in: CGRect(x: margin + 10, y: yPosition + 30 + validUntilHeight + paymentTermsHeight, width: tableWidth - 20, height: deliveryTimeHeight), withAttributes: contentAttributes)
        
        // Para birimi
        let currency = "Para Birimi: Euro (€)"
        let currencyHeight = calculateTextHeight(text: currency, width: tableWidth - 20, attributes: contentAttributes)
        drawText(currency, in: CGRect(x: margin + 10, y: yPosition + 40 + validUntilHeight + paymentTermsHeight + deliveryTimeHeight, width: tableWidth - 20, height: currencyHeight), withAttributes: contentAttributes)
        
        // Garanti süresi
        let warranty = "Garanti: Tüm ürünler için 12 ay standart üretici garantisi"
        let warrantyHeight = calculateTextHeight(text: warranty, width: tableWidth - 20, attributes: contentAttributes)
        drawText(warranty, in: CGRect(x: margin + 10, y: yPosition + 50 + validUntilHeight + paymentTermsHeight + deliveryTimeHeight + currencyHeight, width: tableWidth - 20, height: warrantyHeight), withAttributes: contentAttributes)
        
        // Kutu etrafına çerçeve çiz
        drawLine(from: termsRect.origin, to: CGPoint(x: termsRect.maxX, y: termsRect.minY))
        drawLine(from: CGPoint(x: termsRect.minX, y: termsRect.maxY), to: CGPoint(x: termsRect.maxX, y: termsRect.maxY))
        drawLine(from: termsRect.origin, to: CGPoint(x: termsRect.minX, y: termsRect.maxY))
        drawLine(from: CGPoint(x: termsRect.maxX, y: termsRect.minY), to: CGPoint(x: termsRect.maxX, y: termsRect.maxY))
        
        yPosition += termsHeight + 20 // Sonraki bölüm için boşluk
    }

    // Ürünler Tablosu (Geliştirilmiş)
    private static func drawProductsTable(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let headerFont = standardFont(size: 8, weight: .bold)
        let rowFont = standardFont(size: 8)
        let headerAttributes = textAttributes(font: headerFont, color: .black)
        let rowAttributes = textAttributes(font: rowFont, color: .darkGray)
        let rowRightAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .right)
        let rowCenterAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .center)
        let profitAttributes = textAttributes(font: rowFont, color: .systemGreen, alignment: .right)
        let lossAttributes = textAttributes(font: rowFont, color: .systemRed, alignment: .right)

        var pageNumber = 1 // Yerel sayfa numarası, checkPageBreak tarafından güncellenir

        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 50, pageRect: pageRect, margin: margin, currentPage: pageNumber)

        // Tablo başlığı
        let productsTitle = "Ürünler"
        let titleHeight = calculateTextHeight(text: productsTitle, width: tableWidth, attributes: textAttributes(font: sectionFont))
        drawText(productsTitle, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10

        // Ürün sayısı bilgisi ekleniyor
        let itemCount = "Toplam \(proposal.itemsArray.count) ürün"
        let itemCountHeight = calculateTextHeight(text: itemCount, width: tableWidth, attributes: textAttributes(font: rowFont))
        drawText(itemCount, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: itemCountHeight), withAttributes: textAttributes(font: rowFont))
        yPosition += itemCountHeight + 10

        // Sütun genişliklerini tanımla - Daha detaylı sütunlar için
        let colWidths: [CGFloat] = [
            tableWidth * 0.05,  // Sıra No
            tableWidth * 0.10,  // Ürün Kodu
            tableWidth * 0.20,  // Ürün Adı
            tableWidth * 0.08,  // Kategori
            tableWidth * 0.05,  // Miktar
            tableWidth * 0.09,  // Birim Maliyet
            tableWidth * 0.09,  // Liste Fiyatı
            tableWidth * 0.06,  // Çarpan
            tableWidth * 0.05,  // İndirim
            tableWidth * 0.09,  // Toplam Fiyat
            tableWidth * 0.07,  // Kâr Marjı
            tableWidth * 0.07   // KDV Dahil
        ]
        
        let colTitles = [
            "Sıra", "Ürün Kodu", "Ürün Adı", "Kategori", "Miktar", "Birim Maliyet",
            "Liste Fiyatı", "Çarpan", "İnd. %", "Toplam", "Kâr %", "KDV Dahil"
        ]
        
        let colAlignments: [NSTextAlignment] = [
            .center, .left, .left, .left, .center, .right,
            .right, .center, .center, .right, .right, .right
        ]

        // Tablo başlığını çiz
        let headerHeight: CGFloat = 18
        var xPosition = margin
        for i in 0..<colTitles.count {
            let title = colTitles[i]
            let width = colWidths[i]
            let alignment = colAlignments[i]
            let attributes = textAttributes(font: headerFont, alignment: alignment)
            // Dikey hizalama için metin dikdörtgenini ayarla
            let textRect = CGRect(
                x: xPosition + 2,
                y: yPosition + (headerHeight - headerFont.lineHeight) / 2,
                width: width - 4,
                height: headerFont.lineHeight
            )
            drawText(title, in: textRect, withAttributes: attributes, alignment: alignment)
            // Dikey ayırıcı çiz
            if i < colTitles.count - 1 {
                drawLine(
                    from: CGPoint(x: xPosition + width, y: yPosition),
                    to: CGPoint(x: xPosition + width, y: yPosition + headerHeight)
                )
            }
            xPosition += width
        }
        
        // Tablo çerçevesini çiz
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition)) // Üst kenar
        drawLine(from: CGPoint(x: margin, y: yPosition + headerHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight)) // Alt kenar
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + headerHeight)) // Sol kenar
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight)) // Sağ kenar

        yPosition += headerHeight

        // Ürün satırlarını çiz
        for (index, item) in proposal.itemsArray.enumerated() {
            let productNameText = item.productName
            let nameHeight = calculateTextHeight(text: productNameText, width: colWidths[2] - 4, attributes: rowAttributes)
            let rowHeight = max(nameHeight + 6, 18) // Minimum satır yüksekliği
            
            pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: rowHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            
            xPosition = margin
            let currentY = yPosition // checkPageBreak tarafından güncellenen Y konumu
            
            // Değerleri hazırla
            let values = [
                String(index + 1), // Sıra numarası
                item.productCode,
                productNameText,
                item.product?.category ?? "-",
                String(format: "%.0f", item.quantity),
                item.formattedUnitPartnerPrice,      // Birim maliyet (Euro formatlı)
                item.formattedUnitListPrice,         // Liste fiyatı (Euro formatlı)
                item.formattedMultiplier,            // Çarpan
                Formatters.formatPercent(item.discount), // İndirim yüzdesi
                item.formattedExtendedCustomerPrice, // Toplam fiyat (Euro formatlı)
                Formatters.formatPercent(item.profitMargin), // Kâr marjı yüzdesi
                Formatters.formatEuro(item.amount * 1.18) // KDV dahil toplam
            ]
            
            // Hücreleri ve dikey kenarlıkları çiz
            for i in 0..<values.count {
                let value = values[i]
                let width = colWidths[i]
                let alignment = colAlignments[i]
                
                // Hücre için doğru özellikleri seç
                var attributes: [NSAttributedString.Key: Any]
                if i == 10 { // Kâr marjı için renklendirme
                    let profit = item.calculatedProfit
                    attributes = profit >= 0 ? profitAttributes : lossAttributes
                } else {
                    switch alignment {
                    case .center:
                        attributes = rowCenterAlignAttributes
                    case .right:
                        attributes = rowRightAlignAttributes
                    default:
                        attributes = rowAttributes
                    }
                }
                
                // Metin dikdörtgenini dikey hizalama için ayarla
                let textRect = CGRect(
                    x: xPosition + 2,
                    y: currentY + (rowHeight - rowFont.lineHeight) / 2,
                    width: width - 4,
                    height: rowFont.lineHeight
                )
                drawText(value, in: textRect, withAttributes: attributes, alignment: alignment)
                
                // Dikey ayırıcı çiz
                if i < values.count - 1 {
                    drawLine(
                        from: CGPoint(x: xPosition + width, y: currentY),
                        to: CGPoint(x: xPosition + width, y: currentY + rowHeight)
                    )
                }
                xPosition += width
            }
            
            // Yatay ayırıcı çiz
            drawLine(
                from: CGPoint(x: margin, y: currentY + rowHeight),
                to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight)
            )
            // Yan kenarlıkları çiz
            drawLine(
                from: CGPoint(x: margin, y: currentY),
                to: CGPoint(x: margin, y: currentY + rowHeight)
            )
            drawLine(
                from: CGPoint(x: margin + tableWidth, y: currentY),
                to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight)
            )
            
            yPosition += rowHeight
        }

        // Ürünler ara toplamı
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 20, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        let subtotalRowHeight: CGFloat = 18
        let subtotalFont = standardFont(size: 9, weight: .bold)
        let subtotalAttributes = textAttributes(font: subtotalFont)
        let subtotalValueAttributes = textAttributes(font: subtotalFont, alignment: .right)
        
        // Son birkaç sütunun genişliğini hesapla
        let preValueColWidths = colWidths.prefix(8).reduce(0, +) // İlk 8 sütun (son 4 hariç)
        let valueWidth = colWidths.suffix(4).reduce(0, +) // Son 4 sütun (toplam, kâr, kdv dahil)
        
        let subtotalLabelRect = CGRect(
            x: margin + 2,
            y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2,
            width: preValueColWidths - 4,
            height: subtotalFont.lineHeight
        )
        let subtotalValueRect = CGRect(
            x: margin + preValueColWidths + 2,
            y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2,
            width: valueWidth - 4,
            height: subtotalFont.lineHeight
        )
        
        drawText("Ürünler Ara Toplamı:", in: subtotalLabelRect, withAttributes: subtotalAttributes)
        drawText(Formatters.formatEuro(proposal.subtotalProducts), in: subtotalValueRect, withAttributes: subtotalValueAttributes, alignment: .right)
        
        // Subtotal çizgilerini çiz
        drawLine(
            from: CGPoint(x: margin, y: yPosition + subtotalRowHeight),
            to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight)
        ) // Alt kenar
        drawLine(
            from: CGPoint(x: margin, y: yPosition),
            to: CGPoint(x: margin, y: yPosition + subtotalRowHeight)
        ) // Sol kenar
        drawLine(
            from: CGPoint(x: margin + tableWidth, y: yPosition),
            to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight)
        ) // Sağ kenar
        
        // KDV dahil toplam satırı (eklendi)
        yPosition += subtotalRowHeight
        let vatRowHeight: CGFloat = 18
        let vatFont = standardFont(size: 9)
        let vatAttributes = textAttributes(font: vatFont)
        let vatValueAttributes = textAttributes(font: vatFont, alignment: .right)
        
        let vatLabelRect = CGRect(
            x: margin + 2,
            y: yPosition + (vatRowHeight - vatFont.lineHeight) / 2,
            width: preValueColWidths - 4,
            height: vatFont.lineHeight
        )
        let vatValueRect = CGRect(
            x: margin + preValueColWidths + 2,
            y: yPosition + (vatRowHeight - vatFont.lineHeight) / 2,
            width: valueWidth - 4,
            height: vatFont.lineHeight
        )
        
        let vatAmount = proposal.subtotalProducts * 0.18 // %18 KDV
        drawText("KDV (%18):", in: vatLabelRect, withAttributes: vatAttributes)
        drawText(Formatters.formatEuro(vatAmount), in: vatValueRect, withAttributes: vatValueAttributes, alignment: .right)
        
        // KDV satırı çizgilerini çiz
        drawLine(
            from: CGPoint(x: margin, y: yPosition + vatRowHeight),
            to: CGPoint(x: margin + tableWidth, y: yPosition + vatRowHeight)
        ) // Alt kenar
        drawLine(
            from: CGPoint(x: margin, y: yPosition),
            to: CGPoint(x: margin, y: yPosition + vatRowHeight)
        ) // Sol kenar
        drawLine(
            from: CGPoint(x: margin + tableWidth, y: yPosition),
            to: CGPoint(x: margin + tableWidth, y: yPosition + vatRowHeight)
        ) // Sağ kenar
        
        // KDV dahil toplam
        yPosition += vatRowHeight
        let totalWithVatRowHeight: CGFloat = 20
        let totalWithVatFont = standardFont(size: 10, weight: .bold)
        let totalWithVatAttributes = textAttributes(font: totalWithVatFont)
        let totalWithVatValueAttributes = textAttributes(font: totalWithVatFont, alignment: .right)
        
        let totalWithVatLabelRect = CGRect(
            x: margin + 2,
            y: yPosition + (totalWithVatRowHeight - totalWithVatFont.lineHeight) / 2,
            width: preValueColWidths - 4,
            height: totalWithVatFont.lineHeight
        )
        let totalWithVatValueRect = CGRect(
            x: margin + preValueColWidths + 2,
            y: yPosition + (totalWithVatRowHeight - totalWithVatFont.lineHeight) / 2,
            width: valueWidth - 4,
            height: totalWithVatFont.lineHeight
        )
        
        let totalWithVat = proposal.subtotalProducts + vatAmount
        drawText("KDV Dahil Toplam:", in: totalWithVatLabelRect, withAttributes: totalWithVatAttributes)
        drawText(Formatters.formatEuro(totalWithVat), in: totalWithVatValueRect, withAttributes: totalWithVatValueAttributes, alignment: .right)
        
        // KDV dahil toplam satırı çizgilerini çiz
        drawLine(
            from: CGPoint(x: margin, y: yPosition + totalWithVatRowHeight),
            to: CGPoint(x: margin + tableWidth, y: yPosition + totalWithVatRowHeight)
        ) // Alt kenar
        drawLine(
            from: CGPoint(x: margin, y: yPosition),
            to: CGPoint(x: margin, y: yPosition + totalWithVatRowHeight)
        ) // Sol kenar
        drawLine(
            from: CGPoint(x: margin + tableWidth, y: yPosition),
            to: CGPoint(x: margin + tableWidth, y: yPosition + totalWithVatRowHeight)
        ) // Sağ kenar
        
        yPosition += totalWithVatRowHeight + 20 // Sonraki bölüm için boşluk
    }

    // Mühendislik Tablosu
    private static func drawEngineeringTable(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let headerFont = standardFont(size: 9, weight: .bold)
        let rowFont = standardFont(size: 9)
        let headerAttributes = textAttributes(font: headerFont)
        let rowAttributes = textAttributes(font: rowFont, color: .darkGray)
        let rowRightAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .right)
        let rowCenterAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .center)

        var pageNumber = 1 // Yerel sayfa numarası

        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 50, pageRect: pageRect, margin: margin, currentPage: pageNumber)

        let title = "Mühendislik Hizmetleri"
        let titleHeight = calculateTextHeight(text: title, width: tableWidth, attributes: textAttributes(font: sectionFont))
        drawText(title, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10

        // Uzman detayları (Yeni eklendi)
        let engineerInfo = "Uzman: Muh. Ahmet Yılmaz | Sertifika: ISO 9001, CE | Deneyim: 12 yıl"
        let engineerInfoHeight = calculateTextHeight(text: engineerInfo, width: tableWidth, attributes: textAttributes(font: rowFont))
        drawText(engineerInfo, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: engineerInfoHeight), withAttributes: textAttributes(font: rowFont))
        yPosition += engineerInfoHeight + 10

        // Sütun genişlikleri ve başlıkları
        let colWidths: [CGFloat] = [tableWidth * 0.50, tableWidth * 0.15, tableWidth * 0.15, tableWidth * 0.20]
        let colTitles = ["Açıklama", "Gün", "Günlük Ücret (€)", "Tutar (€)"]
        let colAlignments: [NSTextAlignment] = [.left, .center, .right, .right]

        // Başlık çizimi
        let headerHeight: CGFloat = 18
        var xPosition = margin
        for i in 0..<colTitles.count {
            let title = colTitles[i]
            let width = colWidths[i]
            let alignment = colAlignments[i]
            let textRect = CGRect(x: xPosition + 2, y: yPosition + (headerHeight - headerFont.lineHeight) / 2, width: width - 4, height: headerFont.lineHeight)
            drawText(title, in: textRect, withAttributes: textAttributes(font: headerFont, alignment: alignment), alignment: alignment)
            if i < colTitles.count - 1 {
                drawLine(from: CGPoint(x: xPosition + width, y: yPosition), to: CGPoint(x: xPosition + width, y: yPosition + headerHeight))
            }
            xPosition += width
        }
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition))
        drawLine(from: CGPoint(x: margin, y: yPosition + headerHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        yPosition += headerHeight

        // Satırları çiz
        for engineering in proposal.engineeringArray {
            let descText = engineering.desc ?? ""
            let descHeight = calculateTextHeight(text: descText, width: colWidths[0] - 4, attributes: rowAttributes)
            let rowHeight = max(descHeight + 6, 18)

            pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: rowHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            xPosition = margin
            let currentY = yPosition // Güncellenmiş Y konumu
            let values = [
                descText,
                String(format: "%.1f", engineering.days),
                Formatters.formatEuro(engineering.rate),
                Formatters.formatEuro(engineering.amount)
            ]
            for i in 0..<values.count {
                let value = values[i]
                let width = colWidths[i]
                let alignment = colAlignments[i]
                let attributes: [NSAttributedString.Key: Any]
                switch alignment {
                case .center: attributes = rowCenterAlignAttributes
                case .right: attributes = rowRightAlignAttributes
                default: attributes = rowAttributes
                }
                let textRect = CGRect(x: xPosition + 2, y: currentY + (rowHeight - rowFont.lineHeight) / 2, width: width - 4, height: rowFont.lineHeight)
                drawText(value, in: textRect, withAttributes: attributes, alignment: alignment)
                if i < values.count - 1 {
                    drawLine(from: CGPoint(x: xPosition + width, y: currentY), to: CGPoint(x: xPosition + width, y: currentY + rowHeight))
                }
                xPosition += width
            }
            drawLine(from: CGPoint(x: margin, y: currentY + rowHeight), to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight))
            drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: margin, y: currentY + rowHeight))
            drawLine(from: CGPoint(x: margin + tableWidth, y: currentY), to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight))
            yPosition += rowHeight
        }

        // Ara toplam
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 20, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        let subtotalRowHeight: CGFloat = 18
        let subtotalFont = standardFont(size: 9, weight: .bold)
        let subtotalAttributes = textAttributes(font: subtotalFont)
        let subtotalValueAttributes = textAttributes(font: subtotalFont, alignment: .right)
        let labelWidth = colWidths[0] + colWidths[1] + colWidths[2] // Tutar sütunundan önceki genişlik
        let valueWidth = colWidths[3] // Tutar sütunu genişliği

        let subtotalLabelRect = CGRect(x: margin + 2, y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2, width: labelWidth - 4, height: subtotalFont.lineHeight)
        let subtotalValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2, width: valueWidth - 4, height: subtotalFont.lineHeight)

        drawText("Mühendislik Ara Toplamı:", in: subtotalLabelRect, withAttributes: subtotalAttributes)
        drawText(Formatters.formatEuro(proposal.subtotalEngineering), in: subtotalValueRect, withAttributes: subtotalValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + subtotalRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + subtotalRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight))
        
        // KDV satırı (eklendi)
        yPosition += subtotalRowHeight
        let vatRowHeight: CGFloat = 18
        let vatFont = standardFont(size: 9)
        let vatAttributes = textAttributes(font: vatFont)
        let vatValueAttributes = textAttributes(font: vatFont, alignment: .right)
        
        let vatAmount = proposal.subtotalEngineering * 0.18 // %18 KDV
        
        let vatLabelRect = CGRect(x: margin + 2, y: yPosition + (vatRowHeight - vatFont.lineHeight) / 2, width: labelWidth - 4, height: vatFont.lineHeight)
        let vatValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (vatRowHeight - vatFont.lineHeight) / 2, width: valueWidth - 4, height: vatFont.lineHeight)
        
        drawText("KDV (%18):", in: vatLabelRect, withAttributes: vatAttributes)
        drawText(Formatters.formatEuro(vatAmount), in: vatValueRect, withAttributes: vatValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + vatRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + vatRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + vatRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + vatRowHeight))
        
        // KDV dahil toplam (eklendi)
        yPosition += vatRowHeight
        let totalWithVatRowHeight: CGFloat = 20
        let totalWithVatFont = standardFont(size: 10, weight: .bold)
        let totalWithVatAttributes = textAttributes(font: totalWithVatFont)
        let totalWithVatValueAttributes = textAttributes(font: totalWithVatFont, alignment: .right)
        
        let totalWithVat = proposal.subtotalEngineering + vatAmount
        
        let totalWithVatLabelRect = CGRect(x: margin + 2, y: yPosition + (totalWithVatRowHeight - totalWithVatFont.lineHeight) / 2, width: labelWidth - 4, height: totalWithVatFont.lineHeight)
        let totalWithVatValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (totalWithVatRowHeight - totalWithVatFont.lineHeight) / 2, width: valueWidth - 4, height: totalWithVatFont.lineHeight)
        
        drawText("KDV Dahil Toplam:", in: totalWithVatLabelRect, withAttributes: totalWithVatAttributes)
        drawText(Formatters.formatEuro(totalWithVat), in: totalWithVatValueRect, withAttributes: totalWithVatValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + totalWithVatRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + totalWithVatRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + totalWithVatRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + totalWithVatRowHeight))
        
        yPosition += totalWithVatRowHeight + 20
    }

    // Giderler Tablosu
    private static func drawExpensesTable(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        // Diğer tablolara benzer yapıda olmakla birlikte, gider tutarları ve KDV bilgileriyle genişletilmiş bir tablo
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let headerFont = standardFont(size: 9, weight: .bold)
        let rowFont = standardFont(size: 9)
        let headerAttributes = textAttributes(font: headerFont)
        let rowAttributes = textAttributes(font: rowFont, color: .darkGray)
        let rowRightAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .right)
        let rowCenterAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .center)

        var pageNumber = 1 // Yerel sayfa numarası

        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 50, pageRect: pageRect, margin: margin, currentPage: pageNumber)

        let title = "Giderler"
        let titleHeight = calculateTextHeight(text: title, width: tableWidth, attributes: textAttributes(font: sectionFont))
        drawText(title, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10

        // Giderlerle ilgili not
        let expenseNote = "Not: Aşağıdaki giderler projeyle ilgili doğrudan maliyetleri temsil eder ve müşteriye yansıtılır."
        let expenseNoteHeight = calculateTextHeight(text: expenseNote, width: tableWidth, attributes: textAttributes(font: rowFont))
        drawText(expenseNote, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: expenseNoteHeight), withAttributes: textAttributes(font: rowFont))
        yPosition += expenseNoteHeight + 10

        // Sütun genişlikleri ve başlıkları
        let colWidths: [CGFloat] = [tableWidth * 0.10, tableWidth * 0.50, tableWidth * 0.20, tableWidth * 0.20]
        let colTitles = ["Kod", "Açıklama", "KDV Oranı", "Tutar (€)"]
        let colAlignments: [NSTextAlignment] = [.center, .left, .center, .right]

        // Başlık çizimi
        let headerHeight: CGFloat = 18
        var xPosition = margin
        for i in 0..<colTitles.count {
            let title = colTitles[i]
            let width = colWidths[i]
            let alignment = colAlignments[i]
            let textRect = CGRect(x: xPosition + 2, y: yPosition + (headerHeight - headerFont.lineHeight) / 2, width: width - 4, height: headerFont.lineHeight)
            drawText(title, in: textRect, withAttributes: textAttributes(font: headerFont, alignment: alignment), alignment: alignment)
            if i < colTitles.count - 1 {
                drawLine(from: CGPoint(x: xPosition + width, y: yPosition), to: CGPoint(x: xPosition + width, y: yPosition + headerHeight))
            }
            xPosition += width
        }
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition))
        drawLine(from: CGPoint(x: margin, y: yPosition + headerHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        yPosition += headerHeight

        // Satırları çiz
        for (index, expense) in proposal.expensesArray.enumerated() {
            let descText = expense.desc ?? ""
            let descHeight = calculateTextHeight(text: descText, width: colWidths[1] - 4, attributes: rowAttributes)
            let rowHeight = max(descHeight + 6, 18)

            pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: rowHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            xPosition = margin
            let currentY = yPosition
            
            // Kod değeri oluştur (EXP + sıra numarası)
            let expenseCode = "EXP\(String(format: "%03d", index + 1))"
            
            // Gider türüne göre KDV oranı (gerçek uygulamada veri modelinizden gelebilir)
            let vatRate = (descText.lowercased().contains("seyahat") || descText.lowercased().contains("konaklama")) ? "%8" : "%18"
            
            let values = [
                expenseCode, // Kod
                descText,    // Açıklama
                vatRate,     // KDV oranı
                Formatters.formatEuro(expense.amount) // Tutar
            ]
            
            for i in 0..<values.count {
                let value = values[i]
                let width = colWidths[i]
                let alignment = colAlignments[i]
                let attributes: [NSAttributedString.Key: Any]
                switch alignment {
                case .center: attributes = rowCenterAlignAttributes
                case .right: attributes = rowRightAlignAttributes
                default: attributes = rowAttributes
                }
                let textRect = CGRect(x: xPosition + 2, y: currentY + (rowHeight - rowFont.lineHeight) / 2, width: width - 4, height: rowFont.lineHeight)
                drawText(value, in: textRect, withAttributes: attributes, alignment: alignment)
                if i < values.count - 1 {
                    drawLine(from: CGPoint(x: xPosition + width, y: currentY), to: CGPoint(x: xPosition + width, y: currentY + rowHeight))
                }
                xPosition += width
            }
            drawLine(from: CGPoint(x: margin, y: currentY + rowHeight), to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight))
            drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: margin, y: currentY + rowHeight))
            drawLine(from: CGPoint(x: margin + tableWidth, y: currentY), to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight))
            yPosition += rowHeight
        }

        // Ara toplam
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 20, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        let subtotalRowHeight: CGFloat = 18
        let subtotalFont = standardFont(size: 9, weight: .bold)
        let subtotalAttributes = textAttributes(font: subtotalFont)
        let subtotalValueAttributes = textAttributes(font: subtotalFont, alignment: .right)
        
        // Açıklama ve tutar sütunlarının toplam genişliği hesaplanıyor
        let labelWidth = colWidths[0] + colWidths[1] + colWidths[2] // İlk üç sütun
        let valueWidth = colWidths[3] // Son sütun (Tutar)

        let subtotalLabelRect = CGRect(x: margin + 2, y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2, width: labelWidth - 4, height: subtotalFont.lineHeight)
        let subtotalValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2, width: valueWidth - 4, height: subtotalFont.lineHeight)

        drawText("Giderler Ara Toplamı:", in: subtotalLabelRect, withAttributes: subtotalAttributes)
        drawText(Formatters.formatEuro(proposal.subtotalExpenses), in: subtotalValueRect, withAttributes: subtotalValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + subtotalRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + subtotalRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight))
        
        // Ortalama KDV hesabı (eklendi)
        yPosition += subtotalRowHeight
        let vatRowHeight: CGFloat = 18
        let vatFont = standardFont(size: 9)
        let vatAttributes = textAttributes(font: vatFont)
        let vatValueAttributes = textAttributes(font: vatFont, alignment: .right)
        
        // Varsayılan olarak %18 KDV kullanıyoruz, gerçek uygulamada daha karmaşık hesaplamalar yapılabilir
        let vatAmount = proposal.subtotalExpenses * 0.18
        
        let vatLabelRect = CGRect(x: margin + 2, y: yPosition + (vatRowHeight - vatFont.lineHeight) / 2, width: labelWidth - 4, height: vatFont.lineHeight)
        let vatValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (vatRowHeight - vatFont.lineHeight) / 2, width: valueWidth - 4, height: vatFont.lineHeight)
        
        drawText("KDV (Ortalama %18):", in: vatLabelRect, withAttributes: vatAttributes)
        drawText(Formatters.formatEuro(vatAmount), in: vatValueRect, withAttributes: vatValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + vatRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + vatRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + vatRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + vatRowHeight))
        
        // KDV dahil toplam
        yPosition += vatRowHeight
        let totalWithVatRowHeight: CGFloat = 20
        let totalWithVatFont = standardFont(size: 10, weight: .bold)
        let totalWithVatAttributes = textAttributes(font: totalWithVatFont)
        let totalWithVatValueAttributes = textAttributes(font: totalWithVatFont, alignment: .right)
        
        let totalWithVat = proposal.subtotalExpenses + vatAmount
        
        let totalWithVatLabelRect = CGRect(x: margin + 2, y: yPosition + (totalWithVatRowHeight - totalWithVatFont.lineHeight) / 2, width: labelWidth - 4, height: totalWithVatFont.lineHeight)
        let totalWithVatValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (totalWithVatRowHeight - totalWithVatFont.lineHeight) / 2, width: valueWidth - 4, height: totalWithVatFont.lineHeight)
        
        drawText("KDV Dahil Toplam:", in: totalWithVatLabelRect, withAttributes: totalWithVatAttributes)
        drawText(Formatters.formatEuro(totalWithVat), in: totalWithVatValueRect, withAttributes: totalWithVatValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + totalWithVatRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + totalWithVatRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + totalWithVatRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + totalWithVatRowHeight))
        
        yPosition += totalWithVatRowHeight + 20
    }

    // Vergiler Tablosu
    private static func drawCustomTaxesTable(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let headerFont = standardFont(size: 9, weight: .bold)
        let rowFont = standardFont(size: 9)
        let headerAttributes = textAttributes(font: headerFont)
        let rowAttributes = textAttributes(font: rowFont, color: .darkGray)
        let rowCenterAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .center)
        let rowRightAlignAttributes = textAttributes(font: rowFont, color: .darkGray, alignment: .right)

        var pageNumber = 1 // Yerel sayfa numarası

        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 50, pageRect: pageRect, margin: margin, currentPage: pageNumber)

        let title = "Özel Vergiler"
        let titleHeight = calculateTextHeight(text: title, width: tableWidth, attributes: textAttributes(font: sectionFont))
        drawText(title, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10

        // Vergi notu
        let taxNote = "Not: Aşağıdaki özel vergiler, teklif fiyatına dahil edilmiştir ve ülke/bölge gereksinimlerine göre değişebilir."
        let taxNoteHeight = calculateTextHeight(text: taxNote, width: tableWidth, attributes: textAttributes(font: rowFont))
        drawText(taxNote, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: taxNoteHeight), withAttributes: textAttributes(font: rowFont))
        yPosition += taxNoteHeight + 10

        // Sütun genişlikleri ve başlıkları
        let colWidths: [CGFloat] = [tableWidth * 0.50, tableWidth * 0.15, tableWidth * 0.35]
        let colTitles = ["Vergi Adı", "Oran (%)", "Tutar (€)"]
        let colAlignments: [NSTextAlignment] = [.left, .center, .right]

        // Başlık çizimi
        let headerHeight: CGFloat = 18
        var xPosition = margin
        for i in 0..<colTitles.count {
            let title = colTitles[i]
            let width = colWidths[i]
            let alignment = colAlignments[i]
            let textRect = CGRect(x: xPosition + 2, y: yPosition + (headerHeight - headerFont.lineHeight) / 2, width: width - 4, height: headerFont.lineHeight)
            drawText(title, in: textRect, withAttributes: textAttributes(font: headerFont, alignment: alignment), alignment: alignment)
            if i < colTitles.count - 1 {
                drawLine(from: CGPoint(x: xPosition + width, y: yPosition), to: CGPoint(x: xPosition + width, y: yPosition + headerHeight))
            }
            xPosition += width
        }
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition))
        drawLine(from: CGPoint(x: margin, y: yPosition + headerHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        yPosition += headerHeight

        // Satırları çiz
        for tax in proposal.taxesArray {
            let nameText = tax.name ?? ""
            
            // Türkçe vergi adı çevirisi
            var translatedTaxName = nameText
            if nameText.lowercased() == "vat" { translatedTaxName = "KDV" }
            else if nameText.lowercased() == "sales tax" { translatedTaxName = "Satış Vergisi" }
            else if nameText.lowercased() == "service tax" { translatedTaxName = "Hizmet Vergisi" }
            else if nameText.lowercased() == "import tax" { translatedTaxName = "İthalat Vergisi" }
            
            let nameHeight = calculateTextHeight(text: translatedTaxName, width: colWidths[0] - 4, attributes: rowAttributes)
            let rowHeight = max(nameHeight + 6, 18)

            pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: rowHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            xPosition = margin
            let currentY = yPosition
            let values = [
                translatedTaxName,
                Formatters.formatPercent(tax.rate),
                Formatters.formatEuro(tax.amount)
            ]
            for i in 0..<values.count {
                let value = values[i]
                let width = colWidths[i]
                let alignment = colAlignments[i]
                let attributes: [NSAttributedString.Key : Any]
                 switch alignment {
                 case .center: attributes = rowCenterAlignAttributes
                 case .right: attributes = rowRightAlignAttributes
                 default: attributes = rowAttributes
                 }
                let textRect = CGRect(x: xPosition + 2, y: currentY + (rowHeight - rowFont.lineHeight) / 2, width: width - 4, height: rowFont.lineHeight)
                drawText(value, in: textRect, withAttributes: attributes, alignment: alignment)
                if i < values.count - 1 {
                    drawLine(from: CGPoint(x: xPosition + width, y: currentY), to: CGPoint(x: xPosition + width, y: currentY + rowHeight))
                }
                xPosition += width
            }
            drawLine(from: CGPoint(x: margin, y: currentY + rowHeight), to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight))
            drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: margin, y: currentY + rowHeight))
            drawLine(from: CGPoint(x: margin + tableWidth, y: currentY), to: CGPoint(x: margin + tableWidth, y: currentY + rowHeight))
            yPosition += rowHeight
        }

        // Ara toplam
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 20, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        let subtotalRowHeight: CGFloat = 18
        let subtotalFont = standardFont(size: 9, weight: .bold)
        let subtotalAttributes = textAttributes(font: subtotalFont)
        let subtotalValueAttributes = textAttributes(font: subtotalFont, alignment: .right)
        let labelWidth = colWidths[0] + colWidths[1] // İlk iki sütun genişliği
        let valueWidth = colWidths[2] // Son sütun genişliği

        let subtotalLabelRect = CGRect(x: margin + 2, y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2, width: labelWidth - 4, height: subtotalFont.lineHeight)
        let subtotalValueRect = CGRect(x: margin + labelWidth + 2, y: yPosition + (subtotalRowHeight - subtotalFont.lineHeight) / 2, width: valueWidth - 4, height: subtotalFont.lineHeight)

        drawText("Vergiler Ara Toplamı:", in: subtotalLabelRect, withAttributes: subtotalAttributes)
        drawText(Formatters.formatEuro(proposal.subtotalTaxes), in: subtotalValueRect, withAttributes: subtotalValueAttributes, alignment: .right)
        drawLine(from: CGPoint(x: margin, y: yPosition + subtotalRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + subtotalRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + subtotalRowHeight))

        yPosition += subtotalRowHeight + 20
    }
    
    // Geliştirilmiş Finansal Özet
    private static func drawEnhancedFinancialSummary(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let subHeaderFont = standardFont(size: 11, weight: .semibold)
        let rowFont = standardFont(size: 10)
        let rowBoldFont = standardFont(size: 10, weight: .bold)
        let rowSubtleFont = standardFont(size: 9, weight: .regular)

        let subHeaderAttributes = textAttributes(font: subHeaderFont)
        let rowAttributes = textAttributes(font: rowFont)
        let rowBoldAttributes = textAttributes(font: rowBoldFont)
        let rowSubtleAttributes = textAttributes(font: rowSubtleFont, color: .darkGray)
        let rowRightAlignAttributes = textAttributes(font: rowFont, alignment: .right)
        let rowSubtleRightAlignAttributes = textAttributes(font: rowSubtleFont, color: .darkGray, alignment: .right)
        let rowBoldRightAlignAttributes = textAttributes(font: rowBoldFont, alignment: .right)
        let profitAttributes = textAttributes(font: rowBoldFont, color: .systemGreen, alignment: .right)
        let lossAttributes = textAttributes(font: rowBoldFont, color: .systemRed, alignment: .right)

        let requiredHeight: CGFloat = 350 // Tahmini yükseklik

        var pageNumber = 1 // Yerel sayfa numarası takipçisi

        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: requiredHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)

        let summaryTitle = "Finansal Özet"
        let titleHeight = calculateTextHeight(text: summaryTitle, width: tableWidth, attributes: textAttributes(font: sectionFont))
        drawText(summaryTitle, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10

        let summaryBoxWidth = tableWidth * 0.80 // Daha geniş özet kutusu
        let startX = margin + (tableWidth - summaryBoxWidth) / 2 // Ortalanmış kutu
        let labelWidth = summaryBoxWidth * 0.65
        let valueWidth = summaryBoxWidth * 0.35
        let rowHeight: CGFloat = 18
        let subRowHeight: CGFloat = 16 // Daha küçük alt satırlar
        let subHeaderHeight: CGFloat = 24 // Alt başlıklar için yükseklik
        
        // Toplam kutu yüksekliği hesaplanıyor
        let boxHeight: CGFloat = 380 // Genişletilmiş finansal özet için daha fazla alan
        
        let boxRect = CGRect(x: startX, y: yPosition, width: summaryBoxWidth, height: boxHeight)
        
        // Özet kutusunun dış kenarlarını çiz
        drawLine(from: boxRect.origin, to: CGPoint(x: boxRect.maxX, y: boxRect.minY)) // Üst
        drawLine(from: CGPoint(x: boxRect.minX, y: boxRect.maxY), to: CGPoint(x: boxRect.maxX, y: boxRect.maxY)) // Alt
        drawLine(from: boxRect.origin, to: CGPoint(x: boxRect.minX, y: boxRect.maxY)) // Sol
        drawLine(from: CGPoint(x: boxRect.maxX, y: boxRect.minY), to: CGPoint(x: boxRect.maxX, y: boxRect.maxY)) // Sağ

        var currentYInsideBox = yPosition // Kutu içindeki Y konumu

        // Satır çizimi yardımcı fonksiyonu
        func drawSummaryRow(label: String, value: String, height: CGFloat, labelAttr: [NSAttributedString.Key: Any], valueAttr: [NSAttributedString.Key: Any]) {
            let labelRect = CGRect(
                x: startX + 5,
                y: currentYInsideBox + (height - labelAttr.font.lineHeight) / 2,
                width: labelWidth - 10,
                height: labelAttr.font.lineHeight
            )
            let valueRect = CGRect(
                x: startX + labelWidth,
                y: currentYInsideBox + (height - valueAttr.font.lineHeight) / 2,
                width: valueWidth - 10,
                height: valueAttr.font.lineHeight
            )
            drawText(label, in: labelRect, withAttributes: labelAttr)
            drawText(value, in: valueRect, withAttributes: valueAttr, alignment: .right)
            currentYInsideBox += height
            // Satırlar arasına ince çizgi çiz
            if currentYInsideBox < boxRect.maxY {
                drawLine(from: CGPoint(x: startX, y: currentYInsideBox), to: CGPoint(x: startX + summaryBoxWidth, y: currentYInsideBox), color: .lightGray)
            }
        }

        // Alt başlık çizimi yardımcı fonksiyonu
        func drawSubHeader(title: String) {
            let headerRect = CGRect(x: startX, y: currentYInsideBox, width: summaryBoxWidth, height: subHeaderHeight)
            // Alt başlık için hafif arka plan rengi
            UIGraphicsGetCurrentContext()?.setFillColor(UIColor.lightGray.withAlphaComponent(0.15).cgColor)
            UIGraphicsGetCurrentContext()?.fill(headerRect)
            drawText(title, in: headerRect.insetBy(dx: 5, dy: (subHeaderHeight - subHeaderAttributes.font.lineHeight)/2), withAttributes: subHeaderAttributes)
            currentYInsideBox += subHeaderHeight
            // Alt başlık sonrası ince çizgi
            if currentYInsideBox < boxRect.maxY {
                drawLine(from: CGPoint(x: startX, y: currentYInsideBox), to: CGPoint(x: startX + summaryBoxWidth, y: currentYInsideBox), color: .lightGray)
            }
        }

        // --- GELİR BİLEŞENLERİ BÖLÜMü ---
        drawSubHeader(title: "1. Gelir Bileşenleri")
        drawSummaryRow(
            label: "Ürünler Ara Toplamı:",
            value: Formatters.formatEuro(proposal.subtotalProducts),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: rowRightAlignAttributes
        )
        drawSummaryRow(
            label: "Mühendislik Ara Toplamı:",
            value: Formatters.formatEuro(proposal.subtotalEngineering),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: rowRightAlignAttributes
        )
        drawSummaryRow(
            label: "Giderler (Faturalandırılabilir):",
            value: Formatters.formatEuro(proposal.subtotalExpenses),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: rowRightAlignAttributes
        )
        drawSummaryRow(
            label: "Özel Vergiler Ara Toplamı:",
            value: Formatters.formatEuro(proposal.subtotalTaxes),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: rowRightAlignAttributes
        )

        // --- ARA TOPLAM ---
        drawLine(
            from: CGPoint(x: startX, y: currentYInsideBox),
            to: CGPoint(x: startX + summaryBoxWidth, y: currentYInsideBox),
            color: .darkGray,
            lineWidth: 1.0
        ) // Ara toplam öncesi kalın çizgi
        drawSummaryRow(
            label: "ARA TOPLAM:",
            value: Formatters.formatEuro(proposal.totalAmount),
            height: rowHeight,
            labelAttr: rowBoldAttributes,
            valueAttr: rowBoldRightAlignAttributes
        )
        
        // --- KDV HESAPLAMASI ---
        let vatRate = 0.18 // %18 KDV oranı
        let vatAmount = proposal.totalAmount * vatRate
        drawSummaryRow(
            label: "KDV (%18):",
            value: Formatters.formatEuro(vatAmount),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: rowRightAlignAttributes
        )
        
        // --- GENEL TOPLAM (KDV DAHİL) ---
        let totalWithVat = proposal.totalAmount + vatAmount
        drawLine(
            from: CGPoint(x: startX, y: currentYInsideBox),
            to: CGPoint(x: startX + summaryBoxWidth, y: currentYInsideBox),
            color: .darkGray,
            lineWidth: 1.0
        ) // Genel toplam öncesi kalın çizgi
        drawSummaryRow(
            label: "GENEL TOPLAM (KDV DAHİL):",
            value: Formatters.formatEuro(totalWithVat),
            height: rowHeight,
            labelAttr: rowBoldAttributes,
            valueAttr: rowBoldRightAlignAttributes
        )
        drawLine(
            from: CGPoint(x: startX, y: currentYInsideBox),
            to: CGPoint(x: startX + summaryBoxWidth, y: currentYInsideBox),
            color: .darkGray,
            lineWidth: 1.0
        ) // Genel toplam sonrası kalın çizgi

        // --- MALİYET KALEMLERI ---
        drawSubHeader(title: "2. Maliyet Kalemleri")
        
        // Ürün maliyetleri detayları
        let productCosts = proposal.itemsArray.reduce(0.0) { $0 + ($1.product?.partnerPrice ?? 0) * $1.quantity }
        drawSummaryRow(
            label: "  Ürün Maliyetleri:",
            value: Formatters.formatEuro(productCosts),
            height: subRowHeight,
            labelAttr: rowSubtleAttributes,
            valueAttr: rowSubtleRightAlignAttributes
        )
        
        // Giderler detaylı kırılım
        // Nakliye giderleri (varsayılan olarak nakliye/kargo/taşıma kelimelerini içeren giderler)
        let shippingExpenses = proposal.expensesArray.filter {
            expense in
            let desc = expense.desc?.lowercased() ?? ""
            return desc.contains("nakliye") || desc.contains("kargo") || desc.contains("taşıma") || desc.contains("seyahat")
        }.reduce(0.0) { $0 + $1.amount }
        
        if shippingExpenses > 0 {
            drawSummaryRow(
                label: "  Nakliye ve Lojistik Giderleri:",
                value: Formatters.formatEuro(shippingExpenses),
                height: subRowHeight,
                labelAttr: rowSubtleAttributes,
                valueAttr: rowSubtleRightAlignAttributes
            )
        }
        
        // Sigorta giderleri
        let insuranceExpenses = proposal.expensesArray.filter {
            expense in
            let desc = expense.desc?.lowercased() ?? ""
            return desc.contains("sigorta") || desc.contains("teminat")
        }.reduce(0.0) { $0 + $1.amount }
        
        if insuranceExpenses > 0 {
            drawSummaryRow(
                label: "  Sigorta ve Teminat Giderleri:",
                value: Formatters.formatEuro(insuranceExpenses),
                height: subRowHeight,
                labelAttr: rowSubtleAttributes,
                valueAttr: rowSubtleRightAlignAttributes
            )
        }
        
        // Diğer giderler (yukarıdaki kategorilere girmeyen)
        let otherExpenses = proposal.expensesArray.filter {
            expense in
            let desc = expense.desc?.lowercased() ?? ""
            return !desc.contains("nakliye") && !desc.contains("kargo") && !desc.contains("taşıma") &&
                   !desc.contains("sigorta") && !desc.contains("teminat") && !desc.contains("seyahat")
        }.reduce(0.0) { $0 + $1.amount }
        
        if otherExpenses > 0 {
            drawSummaryRow(
                label: "  Diğer Operasyonel Giderler:",
                value: Formatters.formatEuro(otherExpenses),
                height: subRowHeight,
                labelAttr: rowSubtleAttributes,
                valueAttr: rowSubtleRightAlignAttributes
            )
        }
        
        // Toplam giderler
        let totalExpensesCost = proposal.subtotalExpenses
        
        // Toplam maliyet
        let totalCosts = productCosts + totalExpensesCost
        drawSummaryRow(
            label: "Toplam Maliyetler:",
            value: Formatters.formatEuro(totalCosts),
            height: rowHeight,
            labelAttr: rowBoldAttributes,
            valueAttr: rowBoldRightAlignAttributes
        )
        drawSummaryRow(
            label: "Toplam Maliyetler:",
            value: Formatters.formatEuro(totalCosts),
            height: rowHeight,
            labelAttr: rowBoldAttributes,
            valueAttr: rowBoldRightAlignAttributes
        )
        drawLine(
            from: CGPoint(x: startX, y: currentYInsideBox),
            to: CGPoint(x: startX + summaryBoxWidth, y: currentYInsideBox),
            color: .darkGray,
            lineWidth: 1.0
        ) // Toplam maliyetler sonrası kalın çizgi

        // --- KÂR ÖZETI ---
        drawSubHeader(title: "3. Kâr Analizi")
        
        // Ürünlerden gelen brüt kâr
        let productProfit = proposal.itemsArray.reduce(0.0) {
            $0 + ($1.amount - (($1.product?.partnerPrice ?? 0) * $1.quantity))
        }
        drawSummaryRow(
            label: "Ürün Kârı:",
            value: Formatters.formatEuro(productProfit),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: productProfit >= 0 ? rowRightAlignAttributes : lossAttributes
        )
        
        // Mühendislik hizmetlerinden gelen kâr (tamamen kâr olarak kabul edilir)
        let engineeringProfit = proposal.subtotalEngineering
        drawSummaryRow(
            label: "Mühendislik Kârı:",
            value: Formatters.formatEuro(engineeringProfit),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: engineeringProfit >= 0 ? rowRightAlignAttributes : lossAttributes
        )
        
        // Toplam brüt kâr
        let profit = proposal.totalAmount - totalCosts
        drawSummaryRow(
            label: "Toplam Brüt Kâr:",
            value: Formatters.formatEuro(profit),
            height: rowHeight,
            labelAttr: rowBoldAttributes,
            valueAttr: profit >= 0 ? profitAttributes : lossAttributes
        )
        
        // Kâr marjı
        let margin = proposal.totalAmount > 0 ? (profit / proposal.totalAmount) * 100 : 0
        drawSummaryRow(
            label: "Kâr Marjı:",
            value: Formatters.formatPercent(margin),
            height: rowHeight,
            labelAttr: rowBoldAttributes,
            valueAttr: profit >= 0 ? profitAttributes : lossAttributes
        )
        
        // Yatırım getirisi
        let roi = totalCosts > 0 ? (profit / totalCosts) * 100 : 0
        drawSummaryRow(
            label: "Yatırım Getirisi (ROI):",
            value: Formatters.formatPercent(roi),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: roi >= 0 ? rowRightAlignAttributes : lossAttributes
        )
        
        // Hedef kâr marjı
        let targetMargin = 50.0 // Hedef %50 kâr marjı
        let marginalDifference = margin - targetMargin
        drawSummaryRow(
            label: "Hedeften Sapma (Hedef: %50):",
            value: Formatters.formatPercent(marginalDifference),
            height: rowHeight,
            labelAttr: rowAttributes,
            valueAttr: marginalDifference >= 0 ? profitAttributes : lossAttributes
        )

        // Özet kutusu altına genel açıklama
        yPosition = boxRect.maxY + 20 // Özet kutusu altına boşluk ekleniyor
        
        // Finansal özet notu
        let financialNote = "Not: Yukarıdaki finansal analiz geçerli teklif tarihi itibarıyla hesaplanmıştır. Döviz kurları, malzeme fiyatları ve diğer faktörler zaman içinde değişiklik gösterebilir."
        let financialNoteRect = CGRect(x: margin, y: yPosition, width: tableWidth, height: 30)
        drawText(financialNote, in: financialNoteRect, withAttributes: textAttributes(font: rowSubtleFont))
        
        yPosition += 40 // Sonraki bölüm için boşluk
    }
    
    // Kategori Analizi (Yeni)
    private static func drawCategoryAnalysis(context: UIGraphicsPDFRendererContext, proposal: Proposal, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let tableWidth = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let headerFont = standardFont(size: 9, weight: .bold)
        let rowFont = standardFont(size: 9)
        
        var pageNumber = 1 // Yerel sayfa numarası
        
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: 200, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        
        // Bölüm başlığı
        let title = "Ürün Kategori Analizi"
        let titleHeight = calculateTextHeight(text: title, width: tableWidth, attributes: textAttributes(font: sectionFont))
        drawText(title, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10
        
        // Kategori verilerini topla
        var categories: [String: (count: Int, total: Double, cost: Double)] = [:]
        for item in proposal.itemsArray {
            let category = item.product?.category ?? "Diğer"
            let amount = item.amount
            let cost = (item.product?.partnerPrice ?? 0) * item.quantity
            
            if let existing = categories[category] {
                categories[category] = (
                    count: existing.count + 1,
                    total: existing.total + amount,
                    cost: existing.cost + cost
                )
            } else {
                categories[category] = (count: 1, total: amount, cost: cost)
            }
        }
        
        // Kategorileri toplam tutara göre sırala
        let sortedCategories = categories.sorted { $0.value.total > $1.value.total }
        
        // Kategori yoksa bilgi mesajı göster
        if sortedCategories.isEmpty {
            let noDataText = "Kategori verisi bulunamadı."
            let noDataTextHeight = calculateTextHeight(text: noDataText, width: tableWidth, attributes: textAttributes(font: rowFont))
            drawText(noDataText, in: CGRect(x: margin, y: yPosition, width: tableWidth, height: noDataTextHeight), withAttributes: textAttributes(font: rowFont))
            yPosition += noDataTextHeight + 20
            return
        }
        
        // Sütun başlıkları ve genişlikleri
        let colWidths: [CGFloat] = [tableWidth * 0.25, tableWidth * 0.15, tableWidth * 0.20, tableWidth * 0.20, tableWidth * 0.20]
        let colTitles = ["Kategori", "Ürün Sayısı", "Gelir (€)", "Kâr (€)", "Kâr Marjı (%)"]
        let colAlignments: [NSTextAlignment] = [.left, .center, .right, .right, .right]
        
        // Başlıkları çiz
        let headerHeight: CGFloat = 18
        var xPosition = margin
        for i in 0..<colTitles.count {
            let title = colTitles[i]
            let width = colWidths[i]
            let alignment = colAlignments[i]
            let textRect = CGRect(x: xPosition + 2, y: yPosition + (headerHeight - headerFont.lineHeight) / 2, width: width - 4, height: headerFont.lineHeight)
            drawText(title, in: textRect, withAttributes: textAttributes(font: headerFont, alignment: alignment), alignment: alignment)
            if i < colTitles.count - 1 {
                drawLine(from: CGPoint(x: xPosition + width, y: yPosition), to: CGPoint(x: xPosition + width, y: yPosition + headerHeight))
            }
            xPosition += width
        }
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition))
        drawLine(from: CGPoint(x: margin, y: yPosition + headerHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + headerHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + headerHeight))
        yPosition += headerHeight
        
        // Veri satırlarını çiz
        for (category, data) in sortedCategories {
            let rowHeight: CGFloat = 18
            pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: rowHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
            
            let profit = data.total - data.cost
            let margin = data.total > 0 ? (profit / data.total) * 100 : 0
            
            // Kategori adının Türkçesi
            var translatedCategory = category
            if category.lowercased() == "cameras" { translatedCategory = "Kameralar" }
            else if category.lowercased() == "lenses" { translatedCategory = "Lensler" }
            else if category.lowercased() == "other" || category.lowercased() == "uncategorized" { translatedCategory = "Diğer" }
            
            xPosition = margin
            let values = [
                translatedCategory,
                String(data.count),
                Formatters.formatEuro(data.total),
                Formatters.formatEuro(profit),
                Formatters.formatPercent(margin)
            ]
            
            for i in 0..<values.count {
                let value = values[i]
                let width = colWidths[i]
                let alignment = colAlignments[i]
                let textRect = CGRect(x: xPosition + 2, y: yPosition + (rowHeight - rowFont.lineHeight) / 2, width: width - 4, height: rowFont.lineHeight)
                
                // Kâr için renk ayarı
                var textColor = UIColor.darkGray
                if i == 3 { // Kâr sütunu
                    textColor = profit >= 0 ? UIColor.systemGreen : UIColor.systemRed
                } else if i == 4 { // Kâr marjı sütunu
                    textColor = margin >= 0 ? UIColor.systemGreen : UIColor.systemRed
                }
                
                let attributes = textAttributes(font: rowFont, color: textColor, alignment: alignment)
                drawText(value, in: textRect, withAttributes: attributes, alignment: alignment)
                
                if i < values.count - 1 {
                    drawLine(from: CGPoint(x: xPosition + width, y: yPosition), to: CGPoint(x: xPosition + width, y: yPosition + rowHeight))
                }
                xPosition += width
            }
            
            drawLine(from: CGPoint(x: margin, y: yPosition + rowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + rowHeight))
            drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + rowHeight))
            drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + rowHeight))
            
            yPosition += rowHeight
        }
        
        // Toplam satırı
        let totalRowHeight: CGFloat = 20
        let totalFont = standardFont(size: 9, weight: .bold)
        let totalAttributes = textAttributes(font: totalFont)
        let totalValueAttributes = textAttributes(font: totalFont, alignment: .right)
        
        // Toplamları hesapla
        let totalCount = sortedCategories.reduce(0) { $0 + $1.value.count }
        let totalRevenue = sortedCategories.reduce(0.0) { $0 + $1.value.total }
        let totalCost = sortedCategories.reduce(0.0) { $0 + $1.value.cost }
        let totalProfit = totalRevenue - totalCost
        let totalMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0
        
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: totalRowHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        
        xPosition = margin
        let totalValues = [
            "TOPLAM",
            String(totalCount),
            Formatters.formatEuro(totalRevenue),
            Formatters.formatEuro(totalProfit),
            Formatters.formatPercent(totalMargin)
        ]
        
        for i in 0..<totalValues.count {
            let value = totalValues[i]
            let width = colWidths[i]
            let alignment = colAlignments[i]
            let textRect = CGRect(x: xPosition + 2, y: yPosition + (totalRowHeight - totalFont.lineHeight) / 2, width: width - 4, height: totalFont.lineHeight)
            
            var attributes = textAttributes(font: totalFont, alignment: alignment)
            if i == 3 { // Kâr sütunu rengi
                attributes = textAttributes(font: totalFont, color: totalProfit >= 0 ? .systemGreen : .systemRed, alignment: alignment)
            } else if i == 4 { // Kâr marjı sütunu rengi
                attributes = textAttributes(font: totalFont, color: totalMargin >= 0 ? .systemGreen : .systemRed, alignment: alignment)
            }
            
            drawText(value, in: textRect, withAttributes: attributes, alignment: alignment)
            
            if i < totalValues.count - 1 {
                drawLine(from: CGPoint(x: xPosition + width, y: yPosition), to: CGPoint(x: xPosition + width, y: yPosition + totalRowHeight))
            }
            xPosition += width
        }
        
        drawLine(from: CGPoint(x: margin, y: yPosition + totalRowHeight), to: CGPoint(x: margin + tableWidth, y: yPosition + totalRowHeight))
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: margin, y: yPosition + totalRowHeight))
        drawLine(from: CGPoint(x: margin + tableWidth, y: yPosition), to: CGPoint(x: margin + tableWidth, y: yPosition + totalRowHeight))
        
        yPosition += totalRowHeight + 20
    }

    // Notlar
    private static func drawNotes(context: UIGraphicsPDFRendererContext, notes: String, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let width = pageRect.width - (margin * 2)
        let sectionFont = standardFont(size: 14, weight: .semibold)
        let notesFont = standardFont(size: 10)
        let notesAttributes = textAttributes(font: notesFont)

        // Gerekli metin yüksekliğini hesapla
        let textHeight = calculateTextHeight(text: notes, width: width - 10, attributes: notesAttributes)
        let requiredHeight = textHeight + 60

        var pageNumber = 1 // Yerel sayfa numarası

        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: requiredHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)

        let notesTitle = "Notlar"
        let titleHeight = calculateTextHeight(text: notesTitle, width: width, attributes: textAttributes(font: sectionFont))
        drawText(notesTitle, in: CGRect(x: margin, y: yPosition, width: width, height: titleHeight), withAttributes: textAttributes(font: sectionFont))
        yPosition += titleHeight + 10

        // Not içeriğini basit bir kutu içinde çiz
        let notesTextRect = CGRect(x: margin + 5, y: yPosition + 5, width: width - 10, height: textHeight)
        drawText(notes, in: notesTextRect, withAttributes: notesAttributes)

        // Notların etrafına çerçeve çiz
        let notesBoxRect = CGRect(x: margin, y: yPosition, width: width, height: textHeight + 10)
        drawLine(from: notesBoxRect.origin, to: CGPoint(x: notesBoxRect.maxX, y: notesBoxRect.minY))
        drawLine(from: CGPoint(x: notesBoxRect.minX, y: notesBoxRect.maxY), to: CGPoint(x: notesBoxRect.maxX, y: notesBoxRect.maxY))
        drawLine(from: notesBoxRect.origin, to: CGPoint(x: notesBoxRect.minX, y: notesBoxRect.maxY))
        drawLine(from: CGPoint(x: notesBoxRect.maxX, y: notesBoxRect.minY), to: CGPoint(x: notesBoxRect.maxX, y: notesBoxRect.maxY))

        yPosition += notesBoxRect.height + 20 // Notlardan sonra boşluk
    }
    
    // Yasal Uyarı (Yeni Eklendi)
    private static func drawLegalDisclaimer(context: UIGraphicsPDFRendererContext, yPosition: inout CGFloat, pageRect: CGRect, margin: CGFloat) {
        let width = pageRect.width - (margin * 2)
        let disclaimerFont = standardFont(size: 8)
        let disclaimerAttributes = textAttributes(font: disclaimerFont, color: .darkGray)
        
        let disclaimer = "Yasal Uyarı: Bu teklif belgesi gizlidir ve yalnızca bilgi amaçlıdır. Teklif belgesi, alıcı tarafından onaylanmadıkça bağlayıcı değildir. Bu belgede yer alan fiyatlar, tedarikte yaşanabilecek değişiklikler, döviz kurları ve diğer faktörlere bağlı olarak değişiklik gösterebilir. Tüm vergiler, yerel vergi mevzuatına tabidir. Bu teklif 30 gün süreyle geçerlidir. Ürünlerimiz standart garanti koşullarıyla sunulmaktadır. Teklifimizle ilgili sorularınız için lütfen iletişime geçiniz."
        
        let disclaimerHeight = calculateTextHeight(text: disclaimer, width: width, attributes: disclaimerAttributes)
        let requiredHeight = disclaimerHeight + 20
        
        var pageNumber = 1
        pageNumber = checkPageBreak(context: context, yPosition: &yPosition, requiredHeight: requiredHeight, pageRect: pageRect, margin: margin, currentPage: pageNumber)
        
        // Hafif gri arka plan
        let boxRect = CGRect(x: margin, y: yPosition, width: width, height: disclaimerHeight + 10)
        UIGraphicsGetCurrentContext()?.setFillColor(UIColor.lightGray.withAlphaComponent(0.1).cgColor)
        UIGraphicsGetCurrentContext()?.fill(boxRect)
        
        // Yasal uyarı metni
        drawText(disclaimer, in: CGRect(x: margin + 5, y: yPosition + 5, width: width - 10, height: disclaimerHeight), withAttributes: disclaimerAttributes)
        
        // Kutu çerçevesi
        drawLine(from: boxRect.origin, to: CGPoint(x: boxRect.maxX, y: boxRect.minY))
        drawLine(from: CGPoint(x: boxRect.minX, y: boxRect.maxY), to: CGPoint(x: boxRect.maxX, y: boxRect.maxY))
        drawLine(from: boxRect.origin, to: CGPoint(x: boxRect.minX, y: boxRect.maxY))
        drawLine(from: CGPoint(x: boxRect.maxX, y: boxRect.minY), to: CGPoint(x: boxRect.maxX, y: boxRect.maxY))
        
        yPosition += boxRect.height + 20
    }

    // Altbilgi
    private static func drawFooter(context: CGContext, pageRect: CGRect, margin: CGFloat, pageNumber: Int, proposal: Proposal?) {
        let footerFont = standardFont(size: 8)
        let footerAttributes = textAttributes(font: footerFont, color: .gray, alignment: .center)
        
        // Şirket bilgileri ve sayfa numarası içeren altbilgi
        let pageText = "Sayfa \(pageNumber)"
                let footerText = "Referans: \(proposal != nil ? Formatters.formatProposalNumber(proposal!) : "") | Tarih: \(formatDate(Date())) | \(pageText) | Firma Adınız © \(Calendar.current.component(.year, from: Date()))"
                
        let footerHeight = calculateTextHeight(text: footerText, width: pageRect.width - 2 * margin, attributes: footerAttributes)
        let footerY = pageRect.height - margin + 10
        
        drawText(footerText, in: CGRect(x: margin, y: footerY, width: pageRect.width - 2 * margin, height: footerHeight), withAttributes: footerAttributes, alignment: .center)
    }
    
    // MARK: - Yardımcı Metotlar (Helper Methods)
    
    // Durum çevirisi (İngilizce -> Türkçe)
    private static func translateStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "draft": return "Taslak"
        case "pending": return "Beklemede"
        case "sent": return "Gönderildi"
        case "won": return "Kazanıldı"
        case "lost": return "Kaybedildi"
        case "expired": return "Süresi Doldu"
        default: return status
        }
    }

    // PDF kaydetme
    static func savePDF(_ pdfData: Data, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = documentsDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: url)
            print("PDF kaydedildi: \(url.path)")
            return url
        } catch {
            print("PDF kaydetme hatası: \(error)")
            return nil
        }
    }
}

// UIFont için uzantı
extension UIFont {
    var attributes: [NSAttributedString.Key: Any] {
        return [.font: self]
    }
}

// NSAttributedString özellikleri için uzantı
extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    var font: UIFont {
        return self[.font] as? UIFont ?? UIFont.systemFont(ofSize: 10) // Varsayılan değer
    }
}
