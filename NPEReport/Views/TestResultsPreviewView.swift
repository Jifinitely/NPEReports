import SwiftUI

struct TestResultsPreviewView: View {
    @ObservedObject var viewModel: FormViewModel
    @Binding var selectedTab: Int
    @State private var activePDFPreview: PDFPreviewItem?
    @State private var activeAlert: PreviewAlertContext?

    private let brandYellow = Color.npBrandYellow

    var body: some View {
        VStack(spacing: 0) {
            BrandHeaderView(title: "Preview")

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.previewValidationIssues.isEmpty {
                        PreviewValidationCard(messages: viewModel.previewValidationIssues)
                    }

                    PreviewSection(title: "Report Snapshot", brandYellow: brandYellow) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                PreviewMetaPill(title: "Circuits", value: "\(viewModel.testResults.count)")
                                PreviewMetaPill(title: "Photos", value: "\(viewModel.attachments.count)")
                                PreviewMetaPill(title: "Signature", value: viewModel.signatureImage == nil ? "Needed" : "Saved")
                                PreviewMetaPill(title: "Tester", value: viewModel.testedBy.isEmpty ? "Not set" : viewModel.testedBy)
                            }
                        }
                    }

                    PreviewSection(title: "Job Summary", brandYellow: brandYellow) {
                        PreviewRow(title: "Customer", value: viewModel.customer)
                        PreviewRow(title: "Site Address", value: viewModel.siteAddress)
                        PreviewRow(title: "Switchboard Location", value: viewModel.switchboardLocation)
                        PreviewRow(title: "Building Number", value: viewModel.buildingNumber)
                        PreviewRow(title: "Job Number", value: viewModel.jobNumber)
                        PreviewRow(title: "Chassis ID", value: viewModel.chassisID)
                        PreviewRow(title: "Tested By", value: viewModel.testedBy)
                        PreviewRow(title: "Licence Number", value: viewModel.licenceNumber)
                        PreviewRow(title: "Tester Model", value: viewModel.testerModel)
                        PreviewRow(title: "Tester Serial Number", value: viewModel.testerSerialNumber)
                        PreviewRow(title: "Date", value: previewDateFormatter.string(from: viewModel.date))
                        PreviewRow(title: "Total Circuits", value: "\(viewModel.testResults.count)")
                        PreviewRow(title: "Photos", value: "\(viewModel.attachments.count)")
                    }

                    PreviewSection(
                        title: "Circuit Results (\(viewModel.testResults.count))",
                        brandYellow: brandYellow
                    ) {
                        if viewModel.testResults.isEmpty {
                            PreviewEmptyState(
                                icon: "list.bullet.rectangle",
                                title: "No saved circuits yet",
                                message: "Add at least one circuit on the form and it will appear here before the PDF is generated."
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.testResults.enumerated()), id: \.element.id) { index, result in
                                    CircuitPreviewCard(index: index + 1, result: result)
                                }
                            }
                        }
                    }

                    PreviewSection(
                        title: "Attachments (\(viewModel.attachments.count))",
                        brandYellow: brandYellow
                    ) {
                        if viewModel.attachments.isEmpty {
                            PreviewEmptyState(
                                icon: "photo",
                                title: "No site photos attached",
                                message: "If you add photos on the form, they will be appended to the PDF after the results pages."
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.attachments) { attachment in
                                        VStack(alignment: .leading, spacing: 8) {
                                            if let image = AttachmentStorage.resolvedImage(for: attachment) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 180, height: 120)
                                                    .clipped()
                                                    .cornerRadius(12)
                                            }

                                            Text(attachment.fileName)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 180)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                AppActionButton(
                    title: "Back to Form",
                    background: .black,
                    foreground: brandYellow
                ) {
                    selectedTab = 0
                }

                AppActionButton(
                    title: "Generate PDF",
                    background: brandYellow,
                    foreground: .black,
                    action: generatePDF
                )
            }
            .padding()
            .background(Color.npSurface)
        }
        .background(Color.npBackground)
        .navigationBarHidden(true)
        .alert(item: $activeAlert) { context in
            Alert(
                title: Text(context.title),
                message: Text(context.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(item: $activePDFPreview) { item in
            PDFPreviewView(item: item)
        }
    }

    private func generatePDF() {
        guard viewModel.isFormValid else {
            activeAlert = PreviewAlertContext(
                title: "Missing Information",
                message: viewModel.previewValidationMessage
            )
            return
        }

        let report = viewModel.makeReport()

        var reports = HistoryStorage.load()
        if let existingIndex = reports.firstIndex(where: { $0.id == report.id }) {
            reports[existingIndex] = report
        } else {
            reports.append(report)
        }
        HistoryStorage.save(reports)

        guard let url = ReportExportHelper.generatePDFFileURL(for: report) else {
            activeAlert = PreviewAlertContext(
                title: "PDF Error",
                message: "PDF could not be generated. Please try again."
            )
            return
        }

        activePDFPreview = PDFPreviewItem(report: report, url: url)
    }
}

private struct PreviewAlertContext: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct PreviewMetaPill: View {
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

private struct PreviewEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.npSecondarySurface)
        .cornerRadius(12)
    }
}

private struct PreviewValidationCard: View {
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Report Not Ready Yet")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
                Text("\(messages.count) item\(messages.count == 1 ? "" : "s")")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.14))
                    .foregroundColor(.red)
                    .cornerRadius(999)
            }

            ForEach(messages, id: \.self) { message in
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text("Return to the Form tab, finish these items, then come back here to generate the PDF.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.red.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

private struct PreviewSection<Content: View>: View {
    let title: String
    let brandYellow: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(brandYellow)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.npSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(brandYellow, lineWidth: 1.5)
            )
            .cornerRadius(14)
        }
    }
}

private struct PreviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Spacer(minLength: 12)
            Text(displayValue(value))
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func displayValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not provided" : value
    }
}

private struct CircuitPreviewCard: View {
    let index: Int
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circuit \(index)")
                .font(.headline)
                .foregroundColor(.primary)

            if !result.isComplete {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Missing required fields")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)

                    ForEach(result.missingRequiredFields, id: \.self) { field in
                        Label("\(field) is required.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .cornerRadius(12)
            }

            PreviewRow(title: "Test Date", value: result.testDate)
            PreviewRow(title: "Circuit / Equipment", value: result.circuitOrEquipment)
            PreviewRow(title: "Visual Inspection", value: result.visualInspection)
            PreviewRow(title: "Circuit No.", value: result.circuitNo)
            PreviewRow(title: "Cable Size", value: result.cableSize)
            PreviewRow(title: "Protection", value: result.protectionSizeType)
            PreviewRow(title: "Neutral No.", value: result.neutralNo)
            PreviewRow(title: "Earth Continuity", value: result.earthContinuity)
            PreviewRow(title: "RCD", value: result.displayRCDValue)
            PreviewRow(title: "Phase", value: result.formattedSelectedPhases)
            PreviewRow(title: "IR Result (MΩ)", value: result.irResultValue)
            PreviewRow(title: "Polarity Test", value: result.polarityTest)
            PreviewRow(title: "Fault Loop Impedance", value: faultLoopPreviewValue)
            PreviewRow(title: "Operational Test", value: result.operationalTest)
        }
        .padding(16)
        .background(Color.npSecondarySurface)
        .cornerRadius(14)
    }

    private var faultLoopPreviewValue: String {
        if result.isMainIsolator {
            return result.mainIsolatorFaultLoopSummary
        }

        let context = FaultLoopExportContextBuilder.build(for: result)
        guard !context.measuredValue.isEmpty else { return result.faultLoopImpedance }

        if context.isR1R2 {
            var lines = [
                context.measuredValue,
                "Method: \(context.method)",
                "Table: \(context.tableLabel)",
                "Result: \(context.resultTitle)",
                "Active: \(conductorSizeLabel(context.activeConductorSize))",
                "Earth: \(conductorSizeLabel(context.earthConductorSize))"
            ]
            if let maxAllowedValue = context.maxAllowedValue {
                lines.append("Max R1+R2: \(formatOhms(maxAllowedValue))")
            }
            return lines.joined(separator: "\n")
        }

        var lines = [
            context.measuredValue,
            "Method: \(context.method)",
            "Table: \(context.tableLabel)",
            "Result: \(context.resultTitle)",
            "Voltage: \(contextValue(context.voltage))",
            "Disconnection Time: \(contextValue(context.disconnectionTime))"
        ]
        if let maxAllowedValue = context.maxAllowedValue {
            lines.append("Max Zs: \(formatOhms(maxAllowedValue))")
        }
        return lines.joined(separator: "\n")
    }

    private func contextValue(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "Not Set" : trimmedValue
    }

    private func conductorSizeLabel(_ value: String?) -> String {
        guard let value else { return "Not Set" }
        return "\(value)mm²"
    }

    private func formatOhms(_ value: Double) -> String {
        if value >= 1 {
            return String(format: "%.2f Ω", value)
        }

        return String(format: "%.3f Ω", value)
    }
}

private let previewDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
