import AVFoundation
import PhotosUI
import SwiftUI

struct FormView: View {
    @ObservedObject var viewModel: FormViewModel
    @Binding var selectedTab: Int
    @AppStorage("defaultSignature") private var defaultSignatureData: Data?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showCameraPicker = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = ""
    @State private var showValidationErrors = false
    @State private var showSignatureEditor = false
    @State private var showReplaceSignatureAlert = false

    private let brandYellow = Color.npBrandYellow

    private var defaultSignatureImage: UIImage? {
        guard let defaultSignatureData else { return nil }
        return UIImage(data: defaultSignatureData)
    }

    private var isUsingDefaultSignature: Bool {
        guard
            let currentData = viewModel.signatureImage?.pngData(),
            let defaultSignatureData
        else {
            return false
        }

        return currentData == defaultSignatureData
    }

    private var signatureStatusText: String {
        if isUsingDefaultSignature {
            return "Using the default signature from Settings."
        }

        if viewModel.signatureImage != nil {
            return "A custom signature is saved for this report."
        }

        if defaultSignatureImage != nil {
            return "No report signature yet. You can sign now or reuse the saved default signature."
        }

        return "No signature captured yet."
    }

    private var signatureActions: [SignatureAction] {
        var actions = [
            SignatureAction(
                title: viewModel.signatureImage == nil ? "Capture Signature" : "Replace Signature",
                style: .primary,
                action: beginSignatureCapture
            )
        ]

        if defaultSignatureImage != nil, !isUsingDefaultSignature {
            actions.append(
                SignatureAction(
                    title: "Use Default Signature",
                    style: .secondary,
                    action: applyDefaultSignature
                )
            )
        }

        if viewModel.signatureImage != nil {
            actions.append(
                SignatureAction(
                    title: "Clear Signature",
                    style: .destructive,
                    action: clearSignature
                )
            )
        }

        return actions
    }

    private var jobDetailsSection: some View {
        FormSection(title: "Job Details", brandYellow: brandYellow) {
            ValidatedTextField(
                title: "Customer",
                text: $viewModel.customer,
                errorMessage: fieldErrorMessage(for: viewModel.customer, label: "Customer")
            )
            ValidatedTextField(
                title: "Site Address",
                text: $viewModel.siteAddress,
                errorMessage: fieldErrorMessage(for: viewModel.siteAddress, label: "Site Address")
            )
            ValidatedTextField(
                title: "Switchboard Location",
                text: $viewModel.switchboardLocation,
                errorMessage: nil
            )
            ValidatedTextField(
                title: "Building Number",
                text: $viewModel.buildingNumber,
                errorMessage: nil
            )
            ValidatedTextField(
                title: "Job Number",
                text: $viewModel.jobNumber,
                errorMessage: nil
            )
            ValidatedTextField(
                title: "Chassis ID",
                text: $viewModel.chassisID,
                errorMessage: nil
            )
        }
    }

    private var progressSummarySection: some View {
        FormProgressCard(
            circuitCount: viewModel.testResults.count,
            attachmentCount: viewModel.attachments.count,
            hasSignature: viewModel.signatureImage != nil,
            remainingIssueCount: viewModel.previewValidationIssues.count
        )
    }

    private var testerDetailsSection: some View {
        FormSection(title: "Tester Details", brandYellow: brandYellow) {
            ValidatedTextField(
                title: "Tested By",
                text: $viewModel.testedBy,
                errorMessage: fieldErrorMessage(for: viewModel.testedBy, label: "Tested By")
            )
            ValidatedTextField(
                title: "Licence Number",
                text: $viewModel.licenceNumber,
                errorMessage: fieldErrorMessage(for: viewModel.licenceNumber, label: "Licence Number")
            )
            ValidatedTextField(
                title: "Tester Model",
                text: $viewModel.testerModel,
                errorMessage: nil
            )
            ValidatedTextField(
                title: "Tester Serial Number",
                text: $viewModel.testerSerialNumber,
                errorMessage: nil
            )

            DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                .foregroundColor(.primary)

            SignaturePreviewPanel(
                title: "Signature",
                signatureImage: viewModel.signatureImage,
                statusText: signatureStatusText,
                helperText: "Open the full-screen editor for a cleaner signature with Save, Clear, and Cancel controls.",
                actions: signatureActions
            )

            if showValidationErrors, viewModel.signatureImage == nil {
                InlineValidationMessage(message: "Signature is required.")
            }
        }
    }

    private var attachmentsSection: some View {
        FormSection(title: "Attachments", brandYellow: brandYellow) {
            HStack(spacing: 12) {
                AppActionButton(
                    title: "Take Photo",
                    systemImage: "camera",
                    background: .black,
                    foreground: brandYellow,
                    action: openCamera
                )

                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    AppActionLabel(
                        title: "Choose Photos",
                        systemImage: "photo.on.rectangle",
                        background: brandYellow,
                        foreground: .black
                    )
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AttachmentSummaryPill(title: "Photos", value: "\(viewModel.attachments.count)")
                    AttachmentSummaryPill(title: "PDF Layout", value: "2 per page")
                    AttachmentSummaryPill(title: "Source", value: "Camera / Library")
                }
            }

            if viewModel.attachments.isEmpty {
                EmptyInlineState(
                    icon: "photo.on.rectangle.angled",
                    title: "No photos attached yet",
                    message: "Add site photos from the camera or library. They will appear after the results pages in the PDF."
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
                                        .frame(width: 150, height: 110)
                                        .clipped()
                                        .cornerRadius(12)
                                }

                                Text(attachment.fileName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Button(role: .destructive) {
                                    viewModel.removeAttachment(attachment)
                                } label: {
                                    Text("Remove")
                                        .font(.caption.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(width: 150)
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            BrandHeaderView(title: "New Test Report")

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if showValidationErrors, !viewModel.previewValidationIssues.isEmpty {
                        ValidationSummaryCard(
                            title: "Complete These Items Before Preview",
                            messages: viewModel.previewValidationIssues
                        )
                    }

                    progressSummarySection

                    jobDetailsSection

                    TestResultsTableView(
                        testResults: $viewModel.testResults,
                        showValidationErrors: showValidationErrors
                    )

                    testerDetailsSection
                    attachmentsSection

                    AppActionButton(
                        title: "Review Preview",
                        background: brandYellow,
                        foreground: .black,
                        action: reviewPreview
                    )
                }
                .padding()
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .numericKeyboardDoneToolbar()
        .background(Color.npBackground)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.refreshStoredDefaultsIfNeeded()
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView { image in
                addCapturedImage(image)
            }
        }
        .fullScreenCover(isPresented: $showSignatureEditor) {
            SignatureEditorView(
                title: "Report Signature",
                replacementNotice: viewModel.signatureImage == nil ? nil : "Saving here will replace the current report signature."
            ) { image in
                viewModel.signatureImage = image
            }
        }
        .alert("Camera Unavailable", isPresented: $showCameraAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cameraAlertMessage)
        }
        .alert("Replace Signature?", isPresented: $showReplaceSignatureAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) {
                showSignatureEditor = true
            }
        } message: {
            Text("This will replace the current signature for this report.")
        }
        .onChange(of: selectedPhotoItems) { _, items in
            Task {
                await loadAttachments(from: items)
            }
        }
    }

    private func loadAttachments(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let fallbackName = "Site Photo \(viewModel.attachments.count + index + 1)"
                viewModel.addAttachment(
                    imageData: data,
                    fileName: item.itemIdentifier ?? fallbackName
                )
            }
        }

        await MainActor.run {
            selectedPhotoItems = []
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlertMessage = "This device does not have a camera available."
            showCameraAlert = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraPicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCameraPicker = true
                    } else {
                        cameraAlertMessage = "Camera access was denied. Enable it in Settings to take site photos."
                        showCameraAlert = true
                    }
                }
            }
        case .denied, .restricted:
            cameraAlertMessage = "Camera access is turned off. Enable it in Settings to take site photos."
            showCameraAlert = true
        @unknown default:
            cameraAlertMessage = "Camera access is not available right now."
            showCameraAlert = true
        }
    }

    private func addCapturedImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }

        let fileName = "Camera Photo \(Self.cameraDateFormatter.string(from: Date()))"
        viewModel.addAttachment(imageData: imageData, fileName: fileName)
    }

    private func reviewPreview() {
        showValidationErrors = true

        guard viewModel.isFormValid else { return }
        selectedTab = 1
    }

    private func beginSignatureCapture() {
        if viewModel.signatureImage != nil {
            showReplaceSignatureAlert = true
        } else {
            showSignatureEditor = true
        }
    }

    private func applyDefaultSignature() {
        viewModel.signatureImage = defaultSignatureImage
    }

    private func clearSignature() {
        viewModel.signatureImage = nil
    }

    private func fieldErrorMessage(for value: String, label: String) -> String? {
        guard showValidationErrors else { return nil }
        let requiredLabels = ["Customer", "Site Address", "Tested By", "Licence Number"]
        guard requiredLabels.contains(label) else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(label) is required." : nil
    }

    private static let cameraDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter
    }()
}

private struct FormProgressCard: View {
    let circuitCount: Int
    let attachmentCount: Int
    let hasSignature: Bool
    let remainingIssueCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Report In Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(statusBadgeTitle)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusBadgeColor.opacity(0.16))
                    .foregroundColor(statusBadgeColor)
                    .cornerRadius(999)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AttachmentSummaryPill(title: "Circuits", value: "\(circuitCount)")
                    AttachmentSummaryPill(title: "Photos", value: "\(attachmentCount)")
                    AttachmentSummaryPill(title: "Signature", value: hasSignature ? "Saved" : "Needed")
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

    private var summaryText: String {
        if remainingIssueCount > 0 {
            return "\(remainingIssueCount) required item\(remainingIssueCount == 1 ? "" : "s") still need attention before preview."
        }

        return "The core report fields are in good shape. Review the preview when you are ready to export."
    }

    private var statusBadgeTitle: String {
        remainingIssueCount == 0 ? "Ready for Preview" : "\(remainingIssueCount) Left"
    }

    private var statusBadgeColor: Color {
        remainingIssueCount == 0 ? .green : .orange
    }
}

private struct AttachmentSummaryPill: View {
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

private struct EmptyInlineState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
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

struct FormSection<Content: View>: View {
    let title: String
    let brandYellow: Color
    let content: Content

    init(
        title: String,
        brandYellow: Color = .npBrandYellow,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.brandYellow = brandYellow
        self.content = content()
    }

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

private struct ValidationSummaryCard: View {
    let title: String
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
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
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .padding(.top, 1)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }

            Text("Finish these items below, then tap Review Preview again.")
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

private struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color.clear : Color.red, lineWidth: 1)
                )

            if let errorMessage {
                InlineValidationMessage(message: errorMessage)
            }
        }
    }
}

private struct InlineValidationMessage: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundColor(.red)
    }
}

private struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
