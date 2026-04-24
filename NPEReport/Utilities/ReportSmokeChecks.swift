import Foundation
import PDFKit
import UIKit

struct ReportSmokeCheckResult: Identifiable {
    let id = UUID()
    let title: String
    let passed: Bool
}

@MainActor
enum ReportSmokeChecks {
    static func run(bundle: Bundle = .main) -> [ReportSmokeCheckResult] {
        let report = sampleReport()
        let pdfData = PDFGenerator.generatePDF(report: report, signature: nil)
        let payload = AppBackupPayload(reports: [report], templates: [])
        let encodedPayload = try? JSONEncoder().encode(payload)
        let decodedPayload = encodedPayload.flatMap(AppBackupPayload.decode)
        let boardTemplate = report.templateSnapshot(for: .board)
        let circuitsTemplate = report.templateSnapshot(for: .circuitsOnly)
        let savedTemplate = SavedReportTemplate(
            name: "Smoke Template",
            scope: .board,
            reportSnapshot: boardTemplate
        )
        let reportStorageRoundtripPassed = historyStorageRoundtrip(report)
        let templateStorageRoundtripPassed = templateStorageRoundtrip(savedTemplate)

        return [
            ReportSmokeCheckResult(title: "AS3000 bundled", passed: bundledPDFExists(named: "AS3000", bundle: bundle)),
            ReportSmokeCheckResult(title: "AS3008 bundled", passed: bundledPDFExists(named: "AS3008", bundle: bundle)),
            ReportSmokeCheckResult(title: "AS3017 bundled", passed: bundledPDFExists(named: "AS3017", bundle: bundle)),
            ReportSmokeCheckResult(title: "Logo asset available", passed: UIImage(named: "NPContractingLogo") != nil),
            ReportSmokeCheckResult(title: "PDF generation", passed: pdfData != nil && (PDFDocument(data: pdfData ?? Data())?.pageCount ?? 0) > 0),
            ReportSmokeCheckResult(title: "Report storage roundtrip", passed: reportStorageRoundtripPassed),
            ReportSmokeCheckResult(title: "Template storage roundtrip", passed: templateStorageRoundtripPassed),
            ReportSmokeCheckResult(title: "Backup encode/decode", passed: decodedPayload?.reports.count == 1 && decodedPayload?.templates.isEmpty == true),
            ReportSmokeCheckResult(title: "Board template keeps details", passed: !boardTemplate.customer.isEmpty && !boardTemplate.switchboardLocation.isEmpty),
            ReportSmokeCheckResult(title: "Circuit template drops details", passed: circuitsTemplate.customer.isEmpty && circuitsTemplate.siteAddress.isEmpty && circuitsTemplate.switchboardLocation.isEmpty),
            ReportSmokeCheckResult(title: "Protection 6A exports exact", passed: protectionExportPassed("6A")),
            ReportSmokeCheckResult(title: "Protection 10A exports exact", passed: protectionExportPassed("10A")),
            ReportSmokeCheckResult(title: "Protection 16A exports exact", passed: protectionExportPassed("16A")),
            ReportSmokeCheckResult(title: "Protection 20A exports exact", passed: protectionExportPassed("20A")),
            ReportSmokeCheckResult(title: "RCD 28.4ms exports exact", passed: rcdTripTimeExportPassed("28.4")),
            ReportSmokeCheckResult(title: "RCD 24.5ms exports exact", passed: rcdTripTimeExportPassed("24.5"))
        ]
    }

    private static func bundledPDFExists(named resourceName: String, bundle: Bundle) -> Bool {
        bundle.url(forResource: resourceName, withExtension: "pdf") != nil ||
        bundle.url(forResource: resourceName, withExtension: "pdf", subdirectory: "Resources") != nil
    }

    private static func historyStorageRoundtrip(_ report: NPEReport) -> Bool {
        withPreservedStoredData(forKey: HistoryStorage.key) {
            HistoryStorage.save([report])
            let loaded = HistoryStorage.load()
            guard let restoredReport = loaded.first, loaded.count == 1 else { return false }
            return restoredReport.id == report.id &&
                restoredReport.customer == report.customer &&
                restoredReport.jobNumber == report.jobNumber &&
                restoredReport.testResults.count == report.testResults.count
        }
    }

    private static func templateStorageRoundtrip(_ template: SavedReportTemplate) -> Bool {
        withPreservedStoredData(forKey: TemplateStorage.key) {
            TemplateStorage.save([template])
            let loaded = TemplateStorage.load()
            guard let restoredTemplate = loaded.first, loaded.count == 1 else { return false }
            return restoredTemplate.id == template.id &&
                restoredTemplate.displayName == template.displayName &&
                restoredTemplate.scope == template.scope &&
                restoredTemplate.reportSnapshot.testResults.count == template.reportSnapshot.testResults.count
        }
    }

    private static func withPreservedStoredData<T>(forKey key: String, perform: () -> T) -> T {
        let defaults = UserDefaults.standard
        let originalData = defaults.data(forKey: key)
        defer {
            if let originalData {
                defaults.set(originalData, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        return perform()
    }

    private static func sampleReport() -> NPEReport {
        let result = sampleResult()

        return NPEReport(
            reportTitle: "Smoke Check Report",
            customer: "ACME",
            siteAddress: "123 Sample Street",
            switchboardLocation: "Main Board",
            buildingNumber: "B1",
            jobNumber: "JOB-42",
            chassisID: "CH-7",
            testResults: [result],
            attachments: [],
            testedBy: "Tester",
            licenceNumber: "12345",
            date: Date(),
            lifecycleStatus: .complete,
            isArchived: false,
            signatureData: nil
        )
    }

    private static func sampleResult(
        protectionSizeType: String = "20A MCB Type C",
        rcd: String = "30mA Pass",
        rcdTripTimeMs: String = "24"
    ) -> TestResult {
        TestResult(
            id: UUID(),
            testDate: "23 Apr 2026",
            circuitOrEquipment: "Lighting",
            visualInspection: "Pass",
            circuitNo: "C1",
            cableSize: "2.5",
            protectionSizeType: protectionSizeType,
            neutralNo: "N1",
            earthContinuity: "0.24",
            rcd: rcd,
            rcdTripTimeMs: rcdTripTimeMs,
            insulationResistance: "200",
            polarityTest: "Pass",
            faultLoopImpedance: "0.44",
            operationalTest: "Pass"
        )
    }

    private static func protectionExportPassed(_ protectionSize: String) -> Bool {
        let protectionText = "\(protectionSize) RCBO Type C"
        return normalizedExportText(
            generatedPDFText(
            for: report(with: sampleResult(protectionSizeType: protectionText))
            )
        ).contains(protectionText)
    }

    private static func rcdTripTimeExportPassed(_ tripTime: String) -> Bool {
        normalizedExportText(
            generatedPDFText(
            for: report(with: sampleResult(rcdTripTimeMs: tripTime))
            )
        ).contains("\(tripTime)ms")
    }

    private static func report(with result: TestResult) -> NPEReport {
        NPEReport(
            reportTitle: "Smoke Check Report",
            customer: "ACME",
            siteAddress: "123 Sample Street",
            switchboardLocation: "Main Board",
            buildingNumber: "B1",
            jobNumber: "JOB-42",
            chassisID: "CH-7",
            testResults: [result],
            attachments: [],
            testedBy: "Tester",
            licenceNumber: "12345",
            date: Date(),
            lifecycleStatus: .complete,
            isArchived: false,
            signatureData: nil
        )
    }

    private static func generatedPDFText(for report: NPEReport) -> String {
        guard
            let pdfData = PDFGenerator.generatePDF(report: report, signature: nil),
            let document = PDFDocument(data: pdfData)
        else {
            return ""
        }

        return document.string ?? ""
    }

    private static func normalizedExportText(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
