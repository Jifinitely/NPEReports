import AVFoundation
import PDFKit
import SwiftUI

struct PDFGenerator {
    static func generatePDF(report: NPEReport, signature: UIImage?) -> Data? {
        let companyInfo = CompanyInfo.load()
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let finalSignature = signature ?? report.signatureData.flatMap(UIImage.init(data:))
        let pages = buildPages(for: report)
        let totalPages = pages.count
        let documentInfo: [AnyHashable: Any] = [
            kCGPDFContextCreator as String: "NPEReport",
            kCGPDFContextAuthor as String: companyInfo.name,
            kCGPDFContextTitle as String: report.exportFileName
        ]
        let pdfData = NSMutableData()
        var needsContextClose = false

        UIGraphicsBeginPDFContextToData(pdfData, pageRect, documentInfo)
        needsContextClose = true
        defer {
            if needsContextClose {
                UIGraphicsEndPDFContext()
            }
        }

        for (pageIndex, page) in pages.enumerated() {
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }

            switch page.pageType {
            case .results:
                drawResultsPage(
                    in: context,
                    report: report,
                    page: page,
                    companyInfo: companyInfo,
                    signature: page.showsCertification ? finalSignature : nil,
                    pageNumber: pageIndex + 1,
                    totalPages: totalPages
                )
            case .attachments:
                drawAttachmentsPage(
                    in: context,
                    report: report,
                    page: page,
                    companyInfo: companyInfo,
                    pageNumber: pageIndex + 1,
                    totalPages: totalPages
                )
            }
        }

        UIGraphicsEndPDFContext()
        needsContextClose = false

        let finalData = pdfData as Data
        guard !finalData.isEmpty else { return nil }

        return finalData
    }

    private static func buildPages(for report: NPEReport) -> [PDFPageContent] {
        var pages = buildResultPages(for: report.testResults)
        let attachmentChunks = report.attachments.chunked(into: Layout.attachmentsPerPage)

        for (index, chunk) in attachmentChunks.enumerated() {
            pages.append(
                PDFPageContent(
                    pageType: .attachments,
                    circuits: [],
                    attachments: chunk,
                    showsCertification: false,
                    attachmentStartIndex: index * Layout.attachmentsPerPage
                )
            )
        }

        return pages
    }

    private static func buildResultPages(for results: [TestResult]) -> [PDFPageContent] {
        let standardRowsPerPage = max(resultsRowsPerPageForStandardPage(), 1)
        let finalRowsPerPage = max(resultsRowsPerPageForFinalPage(), 0)

        var pages = [PDFPageContent]()
        var currentIndex = 0
        var finalPageRows = results.count
        var standardPageCount = 0

        while finalPageRows > finalRowsPerPage {
            standardPageCount += 1
            finalPageRows = max(0, finalPageRows - standardRowsPerPage)
        }

        var standardRowsRemaining = max(results.count - finalPageRows, 0)
        for _ in 0..<standardPageCount {
            let rowsForPage = min(standardRowsPerPage, standardRowsRemaining)
            let pageRows = Array(results[currentIndex..<currentIndex + rowsForPage])
            pages.append(
                PDFPageContent(
                    pageType: .results,
                    circuits: pageRows,
                    attachments: [],
                    showsCertification: false,
                    attachmentStartIndex: 0
                )
            )
            currentIndex += rowsForPage
            standardRowsRemaining -= rowsForPage
        }

        let finalRows = finalPageRows > 0 ? Array(results[currentIndex..<currentIndex + finalPageRows]) : []
        pages.append(
            PDFPageContent(
                pageType: .results,
                circuits: finalRows,
                attachments: [],
                showsCertification: true,
                attachmentStartIndex: 0
            )
        )

        return pages
    }

    private static func resultsRowsPerPageForStandardPage() -> Int {
        let availableHeight = Layout.bottomLimit - resultsTableTopY() - Layout.headerRowHeight
        return max(Int(floor(availableHeight / Layout.rowHeight)), 1)
    }

    private static func resultsRowsPerPageForFinalPage() -> Int {
        let availableHeight = Layout.bottomLimit
            - resultsTableTopY()
            - Layout.headerRowHeight
            - Layout.resultsTableToCertificationSpacing
            - Layout.certificationBlockHeight
        return max(Int(floor(availableHeight / Layout.rowHeight)), 0)
    }

    private static func resultsTableTopY() -> CGFloat {
        measuredPageHeaderBottomY(pageTitle: "Electrical Test Report") + 12 + Layout.jobDetailsHeight + 10
    }

    private static func measuredPageHeaderBottomY(pageTitle: String) -> CGFloat {
        let headerFont = UIFont(name: "Helvetica-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
        let pageTitleSize = (pageTitle as NSString).size(withAttributes: [.font: headerFont])
        let bannerRect = CGRect(
            x: (Layout.pageWidth - pageTitleSize.width - 44) / 2,
            y: 100,
            width: pageTitleSize.width + 44,
            height: pageTitleSize.height + 10
        )
        return bannerRect.maxY + 4
    }

    private static func drawResultsPage(
        in context: CGContext,
        report: NPEReport,
        page: PDFPageContent,
        companyInfo: CompanyInfo,
        signature: UIImage?,
        pageNumber: Int,
        totalPages: Int
    ) {
        let headerBottomY = drawPageHeader(
            in: context,
            companyInfo: companyInfo,
            report: report,
            pageNumber: pageNumber,
            totalPages: totalPages,
            pageTitle: "Electrical Test Report"
        )

        let detailsBottomY = drawJobDetails(in: context, report: report, topY: headerBottomY + 12)
        let tableTopY = detailsBottomY + 10
        let tableBottomY = drawResultsTable(in: context, rows: page.circuits, topY: tableTopY)

        if page.showsCertification {
            drawCertificationFooter(
                in: context,
                report: report,
                signature: signature,
                topY: min(tableBottomY + Layout.resultsTableToCertificationSpacing, Layout.bottomLimit - Layout.certificationBlockHeight)
            )
        }

        let footerY: CGFloat
        if page.showsCertification {
            footerY = Layout.footerTextY - 8
        } else if pageNumber < totalPages {
            drawContinuationFooter(in: context, leftMargin: Layout.marginLeft, tableBottomY: tableBottomY)
            footerY = tableBottomY + 28
        } else {
            footerY = Layout.footerTextY - 8
        }

        drawPageFooter(in: context, report: report, pageNumber: pageNumber, totalPages: totalPages, footerY: footerY)
    }

    private static func drawAttachmentsPage(
        in context: CGContext,
        report: NPEReport,
        page: PDFPageContent,
        companyInfo: CompanyInfo,
        pageNumber: Int,
        totalPages: Int
    ) {
        _ = drawPageHeader(
            in: context,
            companyInfo: companyInfo,
            report: report,
            pageNumber: pageNumber,
            totalPages: totalPages,
            pageTitle: "Site Photos",
            showsReportNumber: false
        )

        let sitePhotosTitleY: CGFloat = 95
        let photosReportNoY: CGFloat = 123
        let attachmentsTitleY: CGFloat = 153
        let attachmentsStatusY: CGFloat = 176
        let firstPhotoY: CGFloat = 220

        drawSitePhotosHeader(
            in: context,
            report: report,
            sitePhotosTitleY: sitePhotosTitleY,
            photosReportNoY: photosReportNoY,
            attachmentsTitleY: attachmentsTitleY,
            attachmentsStatusY: attachmentsStatusY
        )

        let cardRects = attachmentCardRects(startingAt: firstPhotoY, count: page.attachments.count)

        for (index, attachment) in page.attachments.enumerated() where index < cardRects.count {
            drawAttachmentCard(
                in: context,
                attachment: attachment,
                rect: cardRects[index],
                attachmentIndex: page.attachmentStartIndex + index + 1,
                totalAttachments: report.attachments.count
            )
        }

        drawPageFooter(in: context, report: report, pageNumber: pageNumber, totalPages: totalPages, footerY: Layout.footerTextY - 8)
    }

    @discardableResult
    private static func drawPageHeader(
        in context: CGContext,
        companyInfo: CompanyInfo,
        report: NPEReport,
        pageNumber: Int,
        totalPages: Int,
        pageTitle: String,
        showsReportNumber: Bool = true
    ) -> CGFloat {
        let black = UIColor.black
        let yellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let white = UIColor.white

        let headerFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let smallBoldFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
        let pageWidth = Layout.pageWidth
        let margin = Layout.margin
        let companyNameFont = UIFont.systemFont(ofSize: 9, weight: .bold)
        let companyInfoFont = UIFont.systemFont(ofSize: 7.4, weight: .medium)
        let companyLegalFont = UIFont.systemFont(ofSize: 7.0, weight: .regular)

        let logoWidth: CGFloat = 130
        let logoHeight: CGFloat = 65
        let logoX = pageWidth - margin - logoWidth
        let logoY: CGFloat = 25
        let logoRect = CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight)
        let logoBadgeRect = logoRect.insetBy(dx: -4, dy: -2)
        let logoPath = UIBezierPath(roundedRect: logoBadgeRect, cornerRadius: 16)
        white.setFill()
        logoPath.fill()
        if let logo = UIImage(named: "NPContractingLogo") {
            drawAspectFitImage(logo, in: logoRect)
        } else {
            drawFallbackLogo(in: context, rect: logoRect)
        }

        let contentMaxWidth = pageWidth - logoWidth - (margin * 2)
        let companyX: CGFloat = Layout.marginLeft
        let companyY: CGFloat = 14
        let lineSpacing: CGFloat = 9
        let companyLines: [(text: String, font: UIFont)] = [
            (companyInfo.name, companyNameFont),
            (companyInfo.addressLine1, companyInfoFont),
            (companyInfo.addressLine2, companyInfoFont),
            ("Telephone: \(companyInfo.phone)", companyInfoFont),
            ("Email: \(companyInfo.email)", companyInfoFont),
            ("ABN: \(companyInfo.abn)", companyLegalFont),
            ("Electrical Contractor Licence \(companyInfo.contractorLicence)", companyLegalFont)
        ]

        var currentY = companyY
        for line in companyLines {
            let cleanText = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanText.isEmpty {
                drawBoundedText(
                    cleanText,
                    in: CGRect(x: companyX, y: currentY, width: contentMaxWidth, height: lineSpacing),
                    font: line.font,
                    color: black,
                    lineBreakMode: .byClipping,
                    maxLines: 1,
                    minimumScaleFactor: 0.85
                )
                currentY += lineSpacing
            }
        }

        if let globalMarkImage = UIImage(named: "globalmark-footer-transparent") {
            let maxLogoWidth: CGFloat = 115
            let maxLogoHeight: CGFloat = 34

            let imageRatio = globalMarkImage.size.width / globalMarkImage.size.height

            var logoWidth = maxLogoWidth
            var logoHeight = logoWidth / imageRatio

            if logoHeight > maxLogoHeight {
                logoHeight = maxLogoHeight
                logoWidth = logoHeight * imageRatio
            }

            let logoX = companyX
            let logoY = currentY + 4

            let logoRect = CGRect(
                x: logoX,
                y: logoY,
                width: logoWidth,
                height: logoHeight
            )

            globalMarkImage.draw(in: logoRect)
        }

        let pageTitleSize = (pageTitle as NSString).size(withAttributes: [.font: headerFont])
        let bannerRect = CGRect(
            x: (Layout.pageWidth - pageTitleSize.width - 44) / 2,
            y: 100,
            width: pageTitleSize.width + 44,
            height: pageTitleSize.height + 10
        )
        yellow.setFill()
        context.fill(bannerRect)
        pageTitle.draw(
            at: CGPoint(
                x: bannerRect.midX - pageTitleSize.width / 2,
                y: bannerRect.midY - pageTitleSize.height / 2
            ),
            withAttributes: [.font: headerFont, .foregroundColor: black]
        )

        let lineY = bannerRect.maxY + 4
        context.setStrokeColor(black.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: Layout.marginLeft, y: lineY))
        context.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginRight, y: lineY))
        context.strokePath()

        if showsReportNumber {
            let reportNumberText = "Report No: \(report.reportNumber)"
            reportNumberText.draw(
                at: CGPoint(x: Layout.pageWidth - 210, y: lineY + 8),
                withAttributes: [.font: smallBoldFont, .foregroundColor: black]
            )
        }

        return lineY
    }

    private static func drawFallbackLogo(in context: CGContext, rect: CGRect) {
        let brandYellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let accentYellow = UIColor(red: 1.0, green: 0.74, blue: 0.08, alpha: 1.0)
        let textFont = UIFont.systemFont(ofSize: 34, weight: .black)
        let textRect = CGRect(x: rect.minX + 8, y: rect.minY + 12, width: rect.width * 0.54, height: 40)
        drawBoundedText("N&P", in: textRect, font: textFont, color: .black, lineBreakMode: .byClipping, maxLines: 1)

        let chevronWidth: CGFloat = 26
        let chevronHeight: CGFloat = 36
        let startX = rect.maxX - 3 * (chevronWidth + 4) + 2
        let startY = rect.midY - chevronHeight / 2

        for index in 0..<3 {
            let color = index == 0 ? accentYellow : brandYellow
            let chevronRect = CGRect(
                x: startX + CGFloat(index) * (chevronWidth + 4),
                y: startY,
                width: chevronWidth,
                height: chevronHeight
            )
            let path = UIBezierPath()
            path.move(to: CGPoint(x: chevronRect.minX, y: chevronRect.minY))
            path.addLine(to: CGPoint(x: chevronRect.maxX, y: chevronRect.midY))
            path.addLine(to: CGPoint(x: chevronRect.minX, y: chevronRect.maxY))
            path.addLine(to: CGPoint(x: chevronRect.minX + chevronRect.width * 0.42, y: chevronRect.maxY))
            path.addLine(to: CGPoint(x: chevronRect.maxX, y: chevronRect.midY))
            path.addLine(to: CGPoint(x: chevronRect.minX + chevronRect.width * 0.42, y: chevronRect.minY))
            path.close()
            color.setFill()
            path.fill()
        }
    }

    @discardableResult
    private static func drawJobDetails(in context: CGContext, report: NPEReport, topY: CGFloat) -> CGFloat {
        let bodyFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
        let monoFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let black = UIColor.black
        let leftFields = [
            ("Customer:", report.customer),
            ("Switchboard Location:", report.switchboardLocation),
            ("Building Number:", report.buildingNumber)
        ]
        let rightFields = [
            ("Chassis ID:", report.chassisID),
            ("Job Number:", report.jobNumber),
            ("Site Address:", report.siteAddress)
        ]

        for index in 0..<leftFields.count {
            let y = topY + CGFloat(index * 26)
            drawField(
                title: leftFields[index].0,
                value: leftFields[index].1,
                origin: CGPoint(x: Layout.marginLeft, y: y),
                valueWidth: 220,
                labelWidth: leftFields[index].0 == "Switchboard Location:" ? 130 : 110,
                labelFont: bodyFont,
                valueFont: monoFont,
                color: black
            )
            drawField(
                title: rightFields[index].0,
                value: rightFields[index].1,
                origin: CGPoint(x: Layout.pageWidth / 2 + 20, y: y),
                valueWidth: 210,
                labelFont: bodyFont,
                valueFont: monoFont,
                color: black
            )
        }

        let summaryTopY = topY + CGFloat(leftFields.count * 26) + 2
        return drawSummaryStrip(in: context, report: report, topY: summaryTopY)
    }

    @discardableResult
    private static func drawResultsTable(in context: CGContext, rows: [TestResult], topY: CGFloat) -> CGFloat {
        let yellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let black = UIColor.black
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let headerFont = UIFont.systemFont(ofSize: 7.4, weight: .semibold)
        let cellFont = UIFont.systemFont(ofSize: 7.6, weight: .regular)
        let rowCount = rows.count

        let tableBackgroundRect = CGRect(
            x: Layout.tableX - 8,
            y: topY - 8,
            width: Layout.tableWidth + 16,
            height: Layout.headerRowHeight + (CGFloat(rowCount) * Layout.rowHeight) + 18
        )

        lightGray.setFill()
        context.fill(tableBackgroundRect)

        var x = Layout.tableX
        for (index, title) in Layout.columnTitles.enumerated() {
            let rect = CGRect(x: x, y: topY, width: Layout.columnWidths[index], height: Layout.headerRowHeight)
            yellow.setFill()
            context.fill(rect)
            context.setStrokeColor(yellow.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)
            drawBoundedText(
                title,
                in: rect.insetBy(dx: 3, dy: 3),
                font: headerFont,
                color: black,
                alignment: .center,
                lineBreakMode: .byWordWrapping,
                maxLines: 3,
                minimumScaleFactor: 0.6,
                allowsTightening: true
            )
            x += Layout.columnWidths[index]
        }

        for rowIndex in 0..<rowCount {
            let y = topY + Layout.headerRowHeight + (CGFloat(rowIndex) * Layout.rowHeight)
            var columnX = Layout.tableX
            for (columnIndex, width) in Layout.columnWidths.enumerated() {
                let cellRect = CGRect(x: columnX, y: y, width: width, height: Layout.rowHeight)
                context.setStrokeColor(black.cgColor)
                context.setLineWidth(1)
                context.stroke(cellRect)

                let values = rowValues(rows[rowIndex])
                if columnIndex < values.count {
                    if columnIndex == Layout.faultLoopColumnIndex {
                        drawFaultLoopCell(for: rows[rowIndex], in: cellRect.insetBy(dx: 3, dy: 2), color: black)
                    } else if columnIndex == Layout.rcdColumnIndex {
                        drawRCDCell(for: rows[rowIndex], in: cellRect.insetBy(dx: 3, dy: 3), color: black)
                    } else {
                        drawBoundedText(
                            values[columnIndex],
                            in: cellRect.insetBy(dx: 4, dy: 4),
                            font: cellFont,
                            color: black,
                            alignment: .left,
                            lineBreakMode: .byWordWrapping,
                            maxLines: 2,
                            minimumScaleFactor: 0.65,
                            allowsTightening: true
                        )
                    }
                }

                columnX += width
            }
        }

        return topY + Layout.headerRowHeight + (CGFloat(rowCount) * Layout.rowHeight)
    }

    private static func drawFaultLoopCell(for result: TestResult, in rect: CGRect, color: UIColor) {
        if result.isMainIsolator {
            let recordOnlyText = compactMainIsolatorFaultLoopText(for: result)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.lineSpacing = -1.5

            let attributedText = NSAttributedString(
                string: recordOnlyText,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 4.9, weight: .regular),
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle,
                    .kern: -0.1
                ]
            )

            attributedText.draw(
                with: rect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            return
        }

        let measuredFont = UIFont.systemFont(ofSize: 7.2, weight: .semibold)
        let contextFont = UIFont.systemFont(ofSize: 5.4, weight: .regular)
        let exportContext = FaultLoopExportContextBuilder.build(for: result)
        let measuredText = exportContext.isR1R2
            ? measuredR1R2Label(for: exportContext.measuredValue)
            : exactMeasuredValue(exportContext.measuredValue)
        let contextLines: [String]

        if exportContext.isR1R2 {
            let maxR1R2Text = exportContext.maxAllowedValue.map { value in
                if value >= 1 {
                    return String(format: "%.2fΩ", value)
                }

                return String(format: "%.3fΩ", value)
            }

            var lines = [
                "Method: \(contextValue(exportContext.method, fallback: TestResult.defaultTestMethod))",
                "\(exportContext.tableLabel)  \(exportContext.resultTitle)",
                "A:\(conductorSizeLabel(exportContext.activeConductorSize)) E:\(conductorSizeLabel(exportContext.earthConductorSize))"
            ]
            if let maxR1R2Text {
                lines[2] += " M:\(maxR1R2Text)"
            }
            contextLines = lines
        } else {
            var lineThree = "V:\(contextValue(exportContext.voltage, fallback: TestResult.defaultSystemVoltage)) T:\(contextValue(exportContext.disconnectionTime, fallback: TestResult.defaultDisconnectionTime))"
            if let maxAllowedValue = exportContext.maxAllowedValue {
                let maxText = maxAllowedValue >= 1
                    ? String(format: "%.2fΩ", maxAllowedValue)
                    : String(format: "%.3fΩ", maxAllowedValue)
                lineThree += " M:\(maxText)"
            }
            contextLines = [
                "Method: \(contextValue(exportContext.method, fallback: TestResult.defaultTestMethod))",
                "\(exportContext.tableLabel)  \(exportContext.resultTitle)",
                lineThree
            ]
        }

        let contextText = contextLines.joined(separator: "\n")
        let measuredRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 8)
        let contextRect = CGRect(x: rect.minX, y: rect.minY + 8, width: rect.width, height: rect.height - 8)

        if !measuredText.isEmpty {
            drawBoundedText(
                measuredText,
                in: measuredRect,
                font: measuredFont,
                color: color,
                alignment: .left,
                lineBreakMode: .byTruncatingTail,
                maxLines: 1,
                minimumScaleFactor: 0.8
            )
        }

        drawBoundedText(
            contextText,
            in: contextRect,
            font: contextFont,
            color: color,
            alignment: .left,
            lineBreakMode: .byWordWrapping,
            maxLines: 4,
            minimumScaleFactor: 0.7,
            allowsTightening: true
        )
    }

    private static func drawRCDCell(for result: TestResult, in rect: CGRect, color: UIColor) {
        let rcdParagraph = NSMutableParagraphStyle()
        rcdParagraph.alignment = .center
        rcdParagraph.lineBreakMode = .byClipping
        rcdParagraph.lineSpacing = -1.0

        let rcdAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 5.5),
            .paragraphStyle: rcdParagraph,
            .foregroundColor: color
        ]

        let insetRcdRect = rect.insetBy(dx: 1, dy: 2)

        NSAttributedString(
            string: rcdCellText(for: result),
            attributes: rcdAttributes
        ).draw(in: insetRcdRect)
    }

    private static func drawCertificationFooter(
        in context: CGContext,
        report: NPEReport,
        signature: UIImage?,
        topY: CGFloat
    ) {
        let black = UIColor.black
        let bodyFont = UIFont.systemFont(ofSize: 8.8, weight: .regular)
        let monoFont = UIFont.systemFont(ofSize: 8.8, weight: .regular)
        let certText = "I certify that the electrical installation, to the extent that it is effected by the electrical work, has been tested to ensure it is electrically safe and is in accordance with the requirements of the wiring rules and any other standard applying to the electrical installation under the Electrical Safety Regulation 2002."

        drawBoundedText(
            certText,
            in: CGRect(x: Layout.tableX, y: topY, width: Layout.tableWidth, height: 34),
            font: bodyFont,
            color: black,
            lineBreakMode: .byWordWrapping,
            maxLines: 3,
            minimumScaleFactor: 0.8
        )

        let footerY = topY + 42
        drawBoundedText(
            "Tested by:",
            in: CGRect(x: Layout.tableX, y: footerY, width: 58, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            report.testedBy,
            in: CGRect(x: Layout.tableX + 62, y: footerY, width: 150, height: 14),
            font: monoFont,
            color: black
        )
        drawBoundedText(
            "Licence Number:",
            in: CGRect(x: Layout.tableX + 220, y: footerY, width: 94, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            report.licenceNumber,
            in: CGRect(x: Layout.tableX + 320, y: footerY, width: 100, height: 14),
            font: monoFont,
            color: black
        )
        drawBoundedText(
            "Tester Model:",
            in: CGRect(x: Layout.tableX, y: footerY + 18, width: 86, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            report.testerModel,
            in: CGRect(x: Layout.tableX + 90, y: footerY + 18, width: 150, height: 14),
            font: monoFont,
            color: black
        )
        drawBoundedText(
            "Serial Number:",
            in: CGRect(x: Layout.tableX + 220, y: footerY + 18, width: 88, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            report.testerSerialNumber,
            in: CGRect(x: Layout.tableX + 312, y: footerY + 18, width: 120, height: 14),
            font: monoFont,
            color: black
        )
        drawBoundedText(
            "Tester's Signature:",
            in: CGRect(x: Layout.tableX + 430, y: footerY + 18, width: 110, height: 14),
            font: bodyFont,
            color: black
        )

        let signatureRect = CGRect(x: Layout.tableX + 548, y: footerY + 10, width: 84, height: 28)
        let signaturePath = UIBezierPath(roundedRect: signatureRect, cornerRadius: 6)
        UIColor.white.setFill()
        signaturePath.fill()
        black.withAlphaComponent(0.35).setStroke()
        signaturePath.lineWidth = 1
        signaturePath.stroke()

        if let signature {
            drawAspectFitImage(signature, in: signatureRect.insetBy(dx: 5, dy: 4))
        } else {
            drawBoundedText(
                "No signature",
                in: signatureRect.insetBy(dx: 6, dy: 6),
                font: UIFont.systemFont(ofSize: 8),
                color: UIColor.darkGray,
                alignment: .center
            )
        }

        drawBoundedText(
            "Date:",
            in: CGRect(x: Layout.tableX + 642, y: footerY + 18, width: 34, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            Layout.dateFormatter.string(from: report.date),
            in: CGRect(x: Layout.tableX + 680, y: footerY + 18, width: 90, height: 14),
            font: monoFont,
            color: black
        )
    }

    private static func drawContinuationFooter(in context: CGContext, leftMargin: CGFloat, tableBottomY: CGFloat) {
        let continuedY = tableBottomY + 10
        let continuedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 6),
            .foregroundColor: UIColor.darkGray
        ]
        let continuedRect = CGRect(
            x: leftMargin,
            y: continuedY,
            width: 200,
            height: 10
        )

        NSAttributedString(
            string: "Continued on next page",
            attributes: continuedAttributes
        ).draw(in: continuedRect)
    }

    private static func drawPageFooter(
        in context: CGContext,
        report: NPEReport,
        pageNumber: Int,
        totalPages: Int,
        footerY: CGFloat
    ) {
        let black = UIColor.black
        let footerFont = UIFont.systemFont(ofSize: 9, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let lineY = footerY - 6

        context.setStrokeColor(black.withAlphaComponent(0.35).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: Layout.marginLeft, y: lineY))
        context.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginRight, y: lineY))
        context.strokePath()

        let leftText = "Report No: \(report.reportNumber.isEmpty ? report.displayTitle : report.reportNumber)"
        let secondaryText = report.jobNumber.isEmpty ? report.customer : "Job: \(report.jobNumber)"
        let pageText = "Page \(pageNumber) of \(totalPages)"

        drawBoundedText(
            leftText,
            in: CGRect(x: Layout.marginLeft, y: footerY, width: 260, height: 14),
            font: footerFont,
            color: black
        )
        drawBoundedText(
            secondaryText,
            in: CGRect(x: Layout.marginLeft + 180, y: footerY, width: 260, height: 14),
            font: bodyFont,
            color: UIColor.darkGray
        )
        drawBoundedText(
            pageText,
            in: CGRect(x: Layout.pageWidth - Layout.marginRight - 120, y: footerY, width: 120, height: 14),
            font: footerFont,
            color: black,
            alignment: .right
        )
    }

    private static func attachmentCardRects(startingAt topY: CGFloat, count: Int) -> [CGRect] {
        guard count > 0 else { return [] }

        let availableHeight = Layout.bottomLimit - topY
        let totalSpacing = Layout.attachmentCardSpacing * CGFloat(max(count - 1, 0))
        let cardHeight = min(Layout.maxAttachmentCardHeight, floor((availableHeight - totalSpacing) / CGFloat(count)))
        let cardWidth = Layout.pageWidth - 88

        return (0..<count).map { index in
            CGRect(
                x: 44,
                y: topY + CGFloat(index) * (cardHeight + Layout.attachmentCardSpacing),
                width: cardWidth,
                height: cardHeight
            )
        }
    }

    private static func drawAttachmentCard(
        in context: CGContext,
        attachment: ReportAttachment,
        rect: CGRect,
        attachmentIndex: Int,
        totalAttachments: Int
    ) {
        let black = UIColor.black
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let cardPath = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        lightGray.setFill()
        cardPath.fill()
        black.setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()

        let labelRect = CGRect(x: rect.minX + 16, y: rect.minY + 10, width: rect.width - 32, height: 16)
        drawBoundedText(
            "Photo \(attachmentIndex) of \(totalAttachments)",
            in: labelRect,
            font: UIFont.boldSystemFont(ofSize: 11),
            color: black
        )

        let fileNameRect = CGRect(x: rect.minX + 16, y: rect.minY + 28, width: rect.width - 180, height: 18)
        drawBoundedText(
            attachment.fileName,
            in: fileNameRect,
            font: UIFont.systemFont(ofSize: 10),
            color: black
        )

        let createdAtText = "Added \(Layout.attachmentDateFormatter.string(from: attachment.createdAt))"
        let createdAtRect = CGRect(x: rect.maxX - 164, y: rect.minY + 28, width: 148, height: 16)
        drawBoundedText(
            createdAtText,
            in: createdAtRect,
            font: UIFont.systemFont(ofSize: 9),
            color: UIColor.darkGray,
            alignment: .right
        )

        let imageRect = CGRect(x: rect.minX + 16, y: rect.minY + 52, width: rect.width - 32, height: rect.height - 68)
        let imageFramePath = UIBezierPath(roundedRect: imageRect, cornerRadius: 10)
        UIColor.white.setFill()
        imageFramePath.fill()
        black.withAlphaComponent(0.18).setStroke()
        imageFramePath.lineWidth = 1
        imageFramePath.stroke()

        if let image = AttachmentStorage.resolvedImage(for: attachment) {
            drawAspectFitImage(image, in: imageRect.insetBy(dx: 4, dy: 4))
        } else {
            drawBoundedText(
                "Photo preview unavailable",
                in: imageRect.insetBy(dx: 8, dy: 8),
                font: UIFont.systemFont(ofSize: 10),
                color: UIColor.darkGray,
                alignment: .center,
                maxLines: 2
            )
        }
    }

    @discardableResult
    private static func drawSummaryStrip(in context: CGContext, report: NPEReport, topY: CGFloat) -> CGFloat {
        let stripRect = CGRect(x: Layout.marginLeft, y: topY, width: Layout.pageWidth - Layout.marginLeft - Layout.marginRight, height: 34)
        let yellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let black = UIColor.black
        let bodyFont = UIFont.systemFont(ofSize: 9)
        let titleFont = UIFont.boldSystemFont(ofSize: 9)

        yellow.setFill()
        UIBezierPath(roundedRect: stripRect, cornerRadius: 12).fill()

        let summaryItems = [
            ("Report", report.displayTitle),
            ("Status", report.lifecycleSummary),
            ("Circuits", "\(report.testResults.count)"),
            ("Photos", "\(report.attachments.count)")
        ]
        let widths: [CGFloat] = [0.34, 0.30, 0.18, 0.18]

        var currentX = stripRect.minX
        for (index, item) in summaryItems.enumerated() {
            let cellWidth = stripRect.width * widths[index]
            let cellRect = CGRect(x: currentX, y: stripRect.minY, width: cellWidth, height: stripRect.height)
            if index > 0 {
                context.setStrokeColor(black.withAlphaComponent(0.22).cgColor)
                context.setLineWidth(1)
                context.move(to: CGPoint(x: currentX, y: cellRect.minY + 6))
                context.addLine(to: CGPoint(x: currentX, y: cellRect.maxY - 6))
                context.strokePath()
            }

            drawBoundedText(
                item.0,
                in: CGRect(x: cellRect.minX + 10, y: cellRect.minY + 5, width: cellRect.width - 20, height: 12),
                font: titleFont,
                color: black
            )
            drawBoundedText(
                item.1,
                in: CGRect(x: cellRect.minX + 10, y: cellRect.minY + 17, width: cellRect.width - 20, height: 12),
                font: bodyFont,
                color: black
            )

            currentX += cellWidth
        }

        return stripRect.maxY
    }

    @discardableResult
    private static func drawAttachmentsSummary(in context: CGContext, report: NPEReport, topY: CGFloat) -> CGFloat {
        let rect = CGRect(x: 44, y: topY, width: Layout.pageWidth - 88, height: 46)
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let black = UIColor.black

        let summaryPath = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        lightGray.setFill()
        summaryPath.fill()
        black.withAlphaComponent(0.12).setStroke()
        summaryPath.lineWidth = 1
        summaryPath.stroke()

        let title = "Attachments for \(report.displayTitle)"
        let subtitle = "Job \(report.jobNumber.isEmpty ? "Not set" : report.jobNumber) • \(report.attachments.count) photo(s) • \(report.lifecycleSummary)"

        drawBoundedText(
            title,
            in: CGRect(x: rect.minX + 16, y: rect.minY + 8, width: rect.width - 32, height: 16),
            font: UIFont.boldSystemFont(ofSize: 12),
            color: black
        )
        drawBoundedText(
            subtitle,
            in: CGRect(x: rect.minX + 16, y: rect.minY + 24, width: rect.width - 32, height: 14),
            font: UIFont.systemFont(ofSize: 10),
            color: UIColor.darkGray
        )

        return rect.maxY
    }

    private static func drawSitePhotosHeader(
        in context: CGContext,
        report: NPEReport,
        sitePhotosTitleY: CGFloat,
        photosReportNoY: CGFloat,
        attachmentsTitleY: CGFloat,
        attachmentsStatusY: CGFloat
    ) {
        let black = UIColor.black
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let reportFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
        let attachmentsTitleFont = UIFont.boldSystemFont(ofSize: 12)
        let attachmentsStatusFont = UIFont.systemFont(ofSize: 10)
        _ = sitePhotosTitleY
        drawBoundedText(
            "Report No: \(report.reportNumber)",
            in: CGRect(x: Layout.marginLeft, y: photosReportNoY, width: Layout.pageWidth - (Layout.marginLeft + Layout.marginRight), height: 20),
            font: reportFont,
            color: black
        )

        let greyBoxY = attachmentsTitleY - 8
        let greyBoxHeight: CGFloat = 55
        let rect = CGRect(x: 44, y: greyBoxY, width: Layout.pageWidth - 88, height: greyBoxHeight)
        let summaryPath = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        lightGray.setFill()
        summaryPath.fill()
        black.withAlphaComponent(0.12).setStroke()
        summaryPath.lineWidth = 1
        summaryPath.stroke()

        drawBoundedText(
            "Attachments for \(report.displayTitle)",
            in: CGRect(x: rect.minX + 16, y: attachmentsTitleY, width: rect.width - 32, height: 22),
            font: attachmentsTitleFont,
            color: black
        )
        drawBoundedText(
            "Job \(report.jobNumber.isEmpty ? "Not set" : report.jobNumber) • \(report.attachments.count) photo(s) • \(report.lifecycleSummary)",
            in: CGRect(x: rect.minX + 16, y: attachmentsStatusY, width: rect.width - 32, height: 20),
            font: attachmentsStatusFont,
            color: UIColor.darkGray
        )
    }

    private static func drawField(
        title: String,
        value: String,
        origin: CGPoint,
        valueWidth: CGFloat,
        labelWidth: CGFloat = 110,
        labelFont: UIFont,
        valueFont: UIFont,
        color: UIColor
    ) {
        drawBoundedText(
            title,
            in: CGRect(x: origin.x, y: origin.y, width: labelWidth, height: 14),
            font: labelFont,
            color: color
        )

        let valueRect = CGRect(x: origin.x + labelWidth + 8, y: origin.y - 1, width: valueWidth, height: 22)
        drawBoundedText(
            value,
            in: valueRect,
            font: valueFont,
            color: color
        )
    }

    private static func drawAspectFitImage(_ image: UIImage, in rect: CGRect) {
        let fittedRect = AVMakeRect(aspectRatio: image.size, insideRect: rect)
        image.draw(in: fittedRect)
    }

    private static func drawBoundedText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left,
        lineBreakMode: NSLineBreakMode = .byTruncatingTail,
        maxLines: Int = 1,
        minimumScaleFactor: CGFloat = 1.0,
        allowsTightening: Bool = false
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode

        let drawingContext = NSStringDrawingContext()
        drawingContext.minimumScaleFactor = minimumScaleFactor

        let boundedRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: min(rect.height, ceil(font.lineHeight * CGFloat(maxLines)))
        )

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
                .kern: allowsTightening ? -0.15 : 0
            ]
        )

        attributedText.draw(
            with: boundedRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: drawingContext
        )
    }

    private static func drawCenteredMultilineText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor
    ) {
        let lines = text.components(separatedBy: "\n")
        let lineHeight = font.lineHeight
        var currentY = rect.midY - (CGFloat(lines.count) * lineHeight / 2)

        for line in lines {
            let size = (line as NSString).size(withAttributes: [.font: font])
            let x = rect.midX - size.width / 2
            (line as NSString).draw(
                at: CGPoint(x: x, y: currentY),
                withAttributes: [.font: font, .foregroundColor: color]
            )
            currentY += lineHeight
        }
    }

    private static func rowValues(_ result: TestResult) -> [String] {
        [
            formattedTestDate(result.testDate),
            result.circuitOrEquipment,
            result.visualInspection,
            result.circuitNo,
            result.cableSize.isEmpty ? "" : "\(result.cableSize) mm²",
            result.protectionSizeType,
            result.neutralNo,
            result.earthContinuity,
            rcdCellText(for: result),
            result.formattedSelectedPhases,
            result.irResultValue,
            result.polarityTest,
            faultLoopCellText(for: result),
            result.operationalTest
        ]
    }

    private static func exactMeasuredValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func formattedTestDate(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return "" }

        if let parsedDate = Layout.inputDateFormatters.compactMap({ $0.date(from: trimmedValue) }).first {
            return Layout.dateFormatter.string(from: parsedDate)
        }

        return trimmedValue
    }

    private static func measuredR1R2Label(for value: String) -> String {
        let trimmedValue = exactMeasuredValue(value)
        guard !trimmedValue.isEmpty else { return "" }
        if trimmedValue.contains("Ω") {
            return "R1+R2: \(trimmedValue)"
        }
        return "R1+R2: \(trimmedValue)Ω"
    }

    private static func contextValue(_ value: String, fallback: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? fallback : trimmedValue
    }

    private static func conductorSizeLabel(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "--" }
        return "\(value)mm²"
    }

    private static func rcdCellText(for result: TestResult) -> String {
        if result.isMainIsolator {
            return "N/A"
        }

        let rawValue = result.rcd.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = rawValue.lowercased()

        let rating: String
        if lowercased.contains("100ma") || lowercased.contains("100 ma") {
            rating = "100mA"
        } else if lowercased.contains("30ma") || lowercased.contains("30 ma") {
            rating = "30mA"
        } else if lowercased.contains("rcbo") {
            rating = "RCBO"
        } else if lowercased == "n/a" || lowercased.contains("not applicable") {
            rating = "N/A"
        } else if let firstToken = rawValue.components(separatedBy: .whitespacesAndNewlines).first, !firstToken.isEmpty {
            rating = firstToken
        } else {
            rating = rawValue
        }

        let resultText: String
        if lowercased.contains("pass") {
            resultText = "Pass"
        } else if lowercased.contains("fail") {
            resultText = "Fail"
        } else {
            resultText = ""
        }

        let tripTime = result.rcdTripTimeMs.trimmingCharacters(in: .whitespacesAndNewlines)
        let exportedTripTime = tripTime.isEmpty ? "N/A" : "\(tripTime)ms"

        let baseText = [rating, resultText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !baseText.isEmpty else {
            return exportedTripTime
        }

        return "\(baseText)\n\(exportedTripTime)"
    }

    private static func faultLoopCellText(for result: TestResult) -> String {
        if result.isMainIsolator {
            return compactMainIsolatorFaultLoopText(for: result)
        }

        return exactMeasuredValue(result.faultLoopImpedance)
    }

    private static func compactMainIsolatorFaultLoopText(for result: TestResult) -> String {
        let phaseLines = [
            ("A", result.mainIsolatorPhaseAZs),
            ("B", result.mainIsolatorPhaseBZs),
            ("C", result.mainIsolatorPhaseCZs)
        ]
        .compactMap { phase, value -> String? in
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else { return nil }
            return "\(phase): \(trimmedValue)Ω"
        }

        let activeTrimmedValue = result.mainIsolatorActiveZs.trimmingCharacters(in: .whitespacesAndNewlines)
        let measuredLines = phaseLines.isEmpty
            ? (activeTrimmedValue.isEmpty ? [] : ["Active: \(activeTrimmedValue)Ω"])
            : phaseLines

        return (measuredLines + ["Record Only", "Upstream Protection Applies"]).joined(separator: "\n")
    }

}

private enum PDFPageType {
    case results
    case attachments
}

private struct PDFPageContent {
    let pageType: PDFPageType
    let circuits: [TestResult]
    let attachments: [ReportAttachment]
    let showsCertification: Bool
    let attachmentStartIndex: Int
}

private struct CompanyInfo {
    let name: String
    let address: String
    let phone: String
    let email: String
    let abn: String
    let licence: String

    var addressLine1: String {
        splitAddressLines.0
    }

    var addressLine2: String {
        splitAddressLines.1
    }

    var contractorLicence: String {
        licence
    }

    var displayText: String {
        """
        \(name)
        \(address)
        Telephone: \(phone)
        Email: \(email)
        ABN: \(abn)
        Electrical Contractor Licence \(licence)
        """
    }

    private var splitAddressLines: (String, String) {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else { return ("", "") }

        let newlineComponents = trimmedAddress
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if newlineComponents.count >= 2 {
            return (newlineComponents[0], newlineComponents.dropFirst().joined(separator: ", "))
        }

        return (trimmedAddress, "")
    }

    static func load() -> CompanyInfo {
        CompanyInfo(
            name: UserDefaults.standard.string(forKey: "companyName") ?? "N & P Contracting",
            address: UserDefaults.standard.string(forKey: "companyAddress") ?? "Unit 9 / 48 Tennyson Memorial Avenue, Tennyson QLD 4105",
            phone: UserDefaults.standard.string(forKey: "companyPhone") ?? "07 3892 3399",
            email: UserDefaults.standard.string(forKey: "companyEmail") ?? "info@npcontracting.com.au",
            abn: UserDefaults.standard.string(forKey: "companyABN") ?? "51 709 046 128",
            licence: UserDefaults.standard.string(forKey: "companyLicense") ?? "65051"
        )
    }
}

private enum Layout {
    static let pageWidth: CGFloat = 842
    static let pageHeight: CGFloat = 595
    static let margin: CGFloat = 28
    static let footerHeight: CGFloat = 32
    static let marginLeft: CGFloat = margin
    static let marginRight: CGFloat = margin
    static let footerTopY: CGFloat = pageHeight - margin - footerHeight
    static let footerTextY: CGFloat = pageHeight - margin - 18
    static let bottomLimit: CGFloat = pageHeight - margin - footerHeight
    static let jobDetailsHeight: CGFloat = 114
    static let tableWidth: CGFloat = 780
    static let tableX: CGFloat = (pageWidth - tableWidth) / 2
    static let headerRowHeight: CGFloat = 42
    static let rowHeight: CGFloat = 34
    static let attachmentsPerPage = 2
    static let attachmentCardSpacing: CGFloat = 20
    static let maxAttachmentCardHeight: CGFloat = 154
    static let resultsTableToCertificationSpacing: CGFloat = 16
    static let certificationBlockHeight: CGFloat = 92
    static let faultLoopColumnIndex = 12
    static let rcdColumnIndex = 8
    static let columnTitles = [
        "Test Date",
        "Circuit or Equipment",
        "Visual Inspection\nComplete\n(Pass/Fail)",
        "Circuit No.",
        "Cable Size",
        "Protection Size\nand Type",
        "Neutral No.",
        "Earth Continuity\n(Ohms)",
        "RCD",
        "Phase",
        "IR Result\n(MΩ)",
        "Polarity Test\nEquip./Circuit\n(Pass/Fail)",
        "Fault Loop\nImpedance\nTest (Ohms)",
        "Operational\nTest\n(Pass/Fail)"
    ]
    static let columnWidths: [CGFloat] = {
        let baseColumnWidths: [CGFloat] = [72, 100, 74, 48, 56, 82, 48, 66, 48, 42, 78, 58, 104, 64]
        let total = baseColumnWidths.reduce(0, +)
        let scale = tableWidth / total
        return baseColumnWidths.map { $0 * scale }
    }()
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    static let inputDateFormatters: [DateFormatter] = {
        let formats = [
            "d/M/yyyy",
            "dd/MM/yyyy",
            "d/MM/yyyy",
            "d MMM yyyy",
            "dd MMM yyyy",
            "yyyy-MM-dd"
        ]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter
        }
    }()
    static let attachmentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
