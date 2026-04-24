import PDFKit
import SwiftUI

struct PDFPreviewItem: Identifiable {
    let id = UUID()
    let report: NPEReport
    let url: URL
}

struct PDFPreviewView: View {
    let item: PDFPreviewItem

    @Environment(\.dismiss) private var dismiss
    @State private var shareFile: PDFFileItem?
    @State private var isLoading = true
    @State private var canLoadPDF = false

    var body: some View {
        VStack(spacing: 0) {
            BrandHeaderView(title: "PDF Preview")

            HStack {
                Button("Close") {
                    dismiss()
                }
                .font(.subheadline.bold())
                .foregroundColor(.primary)

                Spacer()

                Button {
                    shareFile = PDFFileItem(url: item.url)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.primary)
                .disabled(!canLoadPDF)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.npSurface)

            if isLoading {
                PDFPreviewLoadingState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if canLoadPDF {
                PDFPreviewSummaryCard(report: item.report, url: item.url)
                    .padding([.horizontal, .top])

                PDFKitRepresentedView(url: item.url)
                    .id(item.url.absoluteString)
                    .padding(.top, 12)
            } else {
                PDFPreviewUnavailableState(report: item.report)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.npBackground)
        .sheet(item: $shareFile) { file in
            ActivityView(activityItems: [file.url])
        }
        .task(id: item.url) {
            loadPreview()
        }
    }

    private func loadPreview() {
        isLoading = true
        let fileExists = FileManager.default.fileExists(atPath: item.url.path)
        canLoadPDF = fileExists && PDFDocument(url: item.url) != nil
        isLoading = false
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
    }
}

private struct PDFPreviewSummaryCard: View {
    let report: NPEReport
    let url: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.displayTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Review the generated layout, then share the finished PDF.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(report.reportNumber)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.npBrandYellow.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(999)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    PDFPreviewMetaPill(title: "Circuits", value: "\(report.testResults.count)")
                    PDFPreviewMetaPill(title: "Photos", value: "\(report.attachments.count)")
                    PDFPreviewMetaPill(title: "Status", value: report.lifecycleStatus.label)
                    PDFPreviewMetaPill(title: "File", value: url.lastPathComponent)
                }
            }
        }
        .padding(16)
        .background(Color.npSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.npBrandYellow.opacity(0.35), lineWidth: 1.5)
        )
        .cornerRadius(14)
    }
}

private struct PDFPreviewMetaPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.npSecondarySurface)
        .cornerRadius(12)
    }
}

private struct PDFPreviewUnavailableState: View {
    let report: NPEReport

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            Text("Unable to load PDF.")
                .font(.headline)
                .foregroundColor(.primary)
            Text("The PDF could not be opened. Please generate it again and try once more.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(report.displayTitle)
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 28)
    }
}

private struct PDFPreviewLoadingState: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Generating PDF…")
                .font(.headline)
                .foregroundColor(.primary)
            Text("The preview will appear once the PDF is ready.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }
}
