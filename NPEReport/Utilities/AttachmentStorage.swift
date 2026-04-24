import Foundation
import UIKit

enum AttachmentStorage {
    private static let directoryName = "NPEReportAttachments"
    private static let maxPixelDimension: CGFloat = 2200
    private static let compressionQuality: CGFloat = 0.82

    static func storedAttachment(from imageData: Data, fileName: String, id: UUID = UUID(), createdAt: Date = Date()) -> ReportAttachment {
        guard let normalizedData = normalizedJPEGData(from: imageData) else {
            return ReportAttachment(id: id, fileName: fileName, imageData: imageData, createdAt: createdAt)
        }

        let imageFileName = "\(id.uuidString).jpg"
        let storedFileName = persistImageData(normalizedData, fileName: imageFileName) ? imageFileName : nil

        return ReportAttachment(
            id: id,
            fileName: fileName,
            imageData: storedFileName == nil ? normalizedData : nil,
            createdAt: createdAt,
            imageFileName: storedFileName
        )
    }

    static func resolvedImageData(for attachment: ReportAttachment) -> Data? {
        if let imageFileName = attachment.imageFileName,
           let data = try? Data(contentsOf: fileURL(for: imageFileName)) {
            return data
        }

        return attachment.imageData
    }

    static func resolvedImage(for attachment: ReportAttachment) -> UIImage? {
        resolvedImageData(for: attachment).flatMap(UIImage.init(data:))
    }

    static func migratedAttachment(_ attachment: ReportAttachment) -> ReportAttachment {
        if let imageFileName = attachment.imageFileName,
           FileManager.default.fileExists(atPath: fileURL(for: imageFileName).path) {
            if attachment.imageData == nil {
                return attachment
            }

            var migrated = attachment
            migrated.imageData = nil
            return migrated
        }

        guard let embeddedData = attachment.imageData else {
            return attachment
        }

        let normalizedData = normalizedJPEGData(from: embeddedData) ?? embeddedData
        let imageFileName = attachment.imageFileName ?? "\(attachment.id.uuidString).jpg"

        guard persistImageData(normalizedData, fileName: imageFileName) else {
            return attachment
        }

        var migrated = attachment
        migrated.imageFileName = imageFileName
        migrated.imageData = nil
        return migrated
    }

    static func deleteImageFile(for attachment: ReportAttachment) {
        guard let imageFileName = attachment.imageFileName else { return }
        try? FileManager.default.removeItem(at: fileURL(for: imageFileName))
    }

    private static func persistImageData(_ data: Data, fileName: String) -> Bool {
        do {
            try ensureDirectoryExists()
            try data.write(to: fileURL(for: fileName), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private static func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: attachmentsDirectoryURL(),
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    private static func attachmentsDirectoryURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    private static func fileURL(for fileName: String) -> URL {
        attachmentsDirectoryURL().appendingPathComponent(fileName)
    }

    private static func normalizedJPEGData(from imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }

        return normalizedJPEGData(from: image)
    }

    private static func normalizedJPEGData(from image: UIImage) -> Data? {
        let resizedImage = resizedImageIfNeeded(image)
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    private static func resizedImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)
        guard maxDimension > maxPixelDimension, maxDimension > 0 else { return image }

        let scale = maxPixelDimension / maxDimension
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
