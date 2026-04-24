import Foundation

struct PDFFileItem: Identifiable {
    let id = UUID()
    let url: URL
}

enum ReportExportHelper {
    static func generatePDFFileURL(for report: NPEReport) -> URL? {
        guard let data = PDFGenerator.generatePDF(report: report, signature: nil), !data.isEmpty else {
            return nil
        }

        do {
            return try makeTemporaryPDFURL(report: report, data: data)
        } catch {
            return nil
        }
    }

    static func makeTemporaryPDFURL(report: NPEReport, data: Data) throws -> URL {
        let fileName = "NP-E-Report-\(sanitizedFileComponent(report.reportNumber.isEmpty ? report.id.uuidString : report.reportNumber))-\(UUID().uuidString.prefix(8)).pdf"
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    private static func sanitizedFileComponent(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let components = value.components(separatedBy: invalidCharacters)
        let sanitized = components.joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitized.isEmpty ? "Report" : sanitized
    }
}
