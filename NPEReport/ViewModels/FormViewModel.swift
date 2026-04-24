import Combine
import Foundation
import SwiftUI

final class FormViewModel: ObservableObject {
    @Published private(set) var currentReportID = UUID()
    @Published var customer = ""
    @Published var siteAddress = ""
    @Published var switchboardLocation = ""
    @Published var buildingNumber = ""
    @Published var jobNumber = ""
    @Published var chassisID = ""
    @Published var testResults: [TestResult] = []
    @Published var attachments: [ReportAttachment] = []
    @Published var testedBy = ""
    @Published var licenceNumber = ""
    @Published var testerModel = ""
    @Published var testerSerialNumber = ""
    @Published var date = Date()
    @Published var signatureImage: UIImage?

    init() {
        applyStoredDefaults()
    }

    var isFormValid: Bool {
        previewValidationIssues.isEmpty
    }

    var missingJobDetailFields: [String] {
        missingFields(from: [
            ("Customer", customer),
            ("Site Address", siteAddress)
        ])
    }

    var missingTesterDetailFields: [String] {
        missingFields(from: [
            ("Tested By", testedBy),
            ("Licence Number", licenceNumber)
        ])
    }

    var invalidCircuitNumbers: [Int] {
        testResults.enumerated().compactMap { index, result in
            result.isComplete ? nil : index + 1
        }
    }

    var previewValidationIssues: [String] {
        var issues = [String]()

        if !missingJobDetailFields.isEmpty {
            issues.append("Complete job details: \(missingJobDetailFields.joined(separator: ", "))")
        }

        if testResults.isEmpty {
            issues.append("Add at least one circuit")
        } else if !invalidCircuitNumbers.isEmpty {
            let circuitList = invalidCircuitNumbers.map(String.init).joined(separator: ", ")
            let label = invalidCircuitNumbers.count == 1 ? "circuit" : "circuits"
            issues.append("Complete the missing fields in \(label): \(circuitList)")
        }

        if !missingTesterDetailFields.isEmpty {
            issues.append("Complete tester details: \(missingTesterDetailFields.joined(separator: ", "))")
        }

        if signatureImage == nil {
            issues.append("Capture a signature")
        }

        return issues
    }

    var previewValidationMessage: String {
        previewValidationIssues.joined(separator: "\n")
    }

    func reset() {
        currentReportID = UUID()
        customer = ""
        siteAddress = ""
        switchboardLocation = ""
        buildingNumber = ""
        jobNumber = ""
        chassisID = ""
        testResults = []
        attachments = []
        testerModel = ""
        testerSerialNumber = ""
        date = Date()
        applyStoredDefaults()
    }

    func makeReport() -> NPEReport {
        NPEReport(
            id: currentReportID,
            reportTitle: "",
            customer: customer,
            siteAddress: siteAddress,
            switchboardLocation: switchboardLocation,
            buildingNumber: buildingNumber,
            jobNumber: jobNumber,
            chassisID: chassisID,
            testResults: testResults,
            attachments: attachments,
            testedBy: testedBy,
            licenceNumber: licenceNumber,
            testerModel: testerModel,
            testerSerialNumber: testerSerialNumber,
            date: date,
            lifecycleStatus: .complete,
            isArchived: false,
            signatureData: signatureImage?.pngData()
        )
    }

    func load(report: NPEReport) {
        currentReportID = report.id
        customer = report.customer
        siteAddress = report.siteAddress
        switchboardLocation = report.switchboardLocation
        buildingNumber = report.buildingNumber
        jobNumber = report.jobNumber
        chassisID = report.chassisID
        testResults = report.testResults
        attachments = report.attachments
        testedBy = report.testedBy
        licenceNumber = report.licenceNumber
        testerModel = report.testerModel
        testerSerialNumber = report.testerSerialNumber
        date = report.date
        signatureImage = report.signatureData.flatMap(UIImage.init(data:))
    }

    func loadTemplate(from report: NPEReport) {
        load(report: report.duplicatedForTemplate())
        refreshStoredDefaultsIfNeeded()
    }

    func applySavedTemplate(_ template: SavedReportTemplate) {
        switch template.scope {
        case .board:
            load(report: template.reportSnapshot.duplicatedForTemplate())
            refreshStoredDefaultsIfNeeded()
        case .circuitsOnly:
            testResults = template.reportSnapshot.testResults.map { $0.duplicated() }
        }
    }

    func refreshStoredDefaultsIfNeeded() {
        if testedBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            testedBy = UserDefaults.standard.string(forKey: "testerName") ?? ""
        }

        if licenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            licenceNumber = UserDefaults.standard.string(forKey: "testerLicense") ?? ""
        }

        if testerModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            testerModel = UserDefaults.standard.string(forKey: "testerModel") ?? ""
        }

        if testerSerialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            testerSerialNumber = UserDefaults.standard.string(forKey: "testerSerialNumber") ?? ""
        }

        if signatureImage == nil,
           let signatureData = UserDefaults.standard.data(forKey: "defaultSignature") {
            signatureImage = UIImage(data: signatureData)
        }
    }

    func addAttachment(imageData: Data, fileName: String) {
        attachments.append(AttachmentStorage.storedAttachment(from: imageData, fileName: fileName))
    }

    func removeAttachment(_ attachment: ReportAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    private func applyStoredDefaults() {
        testedBy = UserDefaults.standard.string(forKey: "testerName") ?? ""
        licenceNumber = UserDefaults.standard.string(forKey: "testerLicense") ?? ""
        testerModel = UserDefaults.standard.string(forKey: "testerModel") ?? ""
        testerSerialNumber = UserDefaults.standard.string(forKey: "testerSerialNumber") ?? ""

        if let signatureData = UserDefaults.standard.data(forKey: "defaultSignature") {
            signatureImage = UIImage(data: signatureData)
        } else {
            signatureImage = nil
        }
    }

    private func missingFields(from values: [(String, String)]) -> [String] {
        values.compactMap { label, value in
            value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? label : nil
        }
    }
}
