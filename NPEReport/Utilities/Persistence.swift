import Foundation

@MainActor
enum HistoryStorage {
    static let key = "exported_reports"

    static func load() -> [NPEReport] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let reports = try? JSONDecoder().decode([NPEReport].self, from: data)
        else {
            return []
        }

        let normalizedReports = reports.map { $0.normalizedForPersistence() }
        if normalizedReports != reports {
            save(normalizedReports)
        }

        return normalizedReports
    }

    static func save(_ reports: [NPEReport]) {
        let normalizedReports = reports.map { $0.normalizedForPersistence() }
        if let data = try? JSONEncoder().encode(normalizedReports) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

@MainActor
enum TemplateStorage {
    static let key = "saved_report_templates"

    static func load() -> [SavedReportTemplate] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let templates = try? JSONDecoder().decode([SavedReportTemplate].self, from: data)
        else {
            return []
        }

        let normalizedTemplates = templates.map { $0.normalizedForPersistence() }
        if normalizedTemplates != templates {
            save(normalizedTemplates)
        }

        return normalizedTemplates
    }

    static func save(_ templates: [SavedReportTemplate]) {
        let normalizedTemplates = templates.map { $0.normalizedForPersistence() }
        if let data = try? JSONEncoder().encode(normalizedTemplates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

@MainActor
struct AppBackupPayload: Codable {
    var reports: [NPEReport]
    var templates: [SavedReportTemplate]

    init(reports: [NPEReport], templates: [SavedReportTemplate]) {
        self.reports = reports.map { $0.backupSnapshot() }
        self.templates = templates.map { $0.backupSnapshot() }
    }

    static func decode(from data: Data) -> AppBackupPayload? {
        let decoder = JSONDecoder()

        if let payload = try? decoder.decode(AppBackupPayload.self, from: data) {
            return payload
        }

        if let reports = try? decoder.decode([NPEReport].self, from: data) {
            return AppBackupPayload(reports: reports, templates: [])
        }

        return nil
    }
}

@MainActor
private extension NPEReport {
    func normalizedForPersistence() -> NPEReport {
        var report = self
        report.attachments = attachments.map(AttachmentStorage.migratedAttachment)
        return report
    }

    func backupSnapshot() -> NPEReport {
        var report = normalizedForPersistence()
        report.attachments = report.attachments.map { attachment in
            var backupAttachment = attachment
            backupAttachment.imageData = AttachmentStorage.resolvedImageData(for: attachment)
            return backupAttachment
        }
        return report
    }
}

@MainActor
private extension SavedReportTemplate {
    func normalizedForPersistence() -> SavedReportTemplate {
        var template = self
        template.reportSnapshot = reportSnapshot.normalizedForPersistence()
        return template
    }

    func backupSnapshot() -> SavedReportTemplate {
        var template = normalizedForPersistence()
        template.reportSnapshot = reportSnapshot.backupSnapshot()
        return template
    }
}
