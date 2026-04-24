import SwiftUI

struct SignatureAction {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    let title: String
    let style: Style
    let action: () -> Void
}

struct SignaturePreviewPanel: View {
    let title: String
    let signatureImage: UIImage?
    let statusText: String
    let helperText: String
    let actions: [SignatureAction]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.npBrandYellow, lineWidth: 1.5)

                if let signatureImage {
                    Image(uiImage: signatureImage)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "signature")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("Sign here")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Open the signature editor to draw and save a clean signature.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)

            Text(statusText)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text(helperText)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.action) {
                        Text(action.title)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(backgroundColor(for: action.style))
                            .foregroundColor(foregroundColor(for: action.style))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func backgroundColor(for style: SignatureAction.Style) -> Color {
        switch style {
        case .primary:
            return Color.npBrandYellow
        case .secondary:
            return Color.black
        case .destructive:
            return Color.red
        }
    }

    private func foregroundColor(for style: SignatureAction.Style) -> Color {
        switch style {
        case .primary:
            return .black
        case .secondary, .destructive:
            return .white
        }
    }
}

struct SignatureEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let replacementNotice: String?
    let onSave: (UIImage) -> Void

    @State private var strokes: [SignatureStroke] = []
    @State private var currentStroke = SignatureStroke()
    @State private var showDiscardAlert = false

    private var drawnStrokes: [SignatureStroke] {
        currentStroke.points.isEmpty ? strokes : strokes + [currentStroke]
    }

    private var hasInk: Bool {
        drawnStrokes.contains { !$0.points.isEmpty }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sign below")
                                .font(.title3.bold())
                                .foregroundColor(.primary)

                            Text("Use a finger or Apple Pencil. Save stores a transparent signature for cleaner PDF output.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Rotate to landscape on iPhone if you want a wider signing area.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let replacementNotice {
                                Text(replacementNotice)
                                    .font(.caption.bold())
                                    .foregroundColor(.primary)
                            }
                        }

                        SignatureDrawingSurface(
                            strokes: $strokes,
                            currentStroke: $currentStroke
                        )
                        .frame(height: min(max(geometry.size.height * 0.42, 240), 340))

                        VStack(spacing: 12) {
                            Button(action: clearCanvas) {
                                Text("Clear")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.black)
                                    .foregroundColor(Color.npBrandYellow)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasInk)
                            .opacity(hasInk ? 1 : 0.45)

                            HStack(spacing: 12) {
                                Button(action: cancelCapture) {
                                    Text("Cancel")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.npSecondarySurface)
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)

                                Button(action: saveSignature) {
                                    Text("Save Signature")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.npBrandYellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .disabled(!hasInk)
                                .opacity(hasInk ? 1 : 0.45)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.npBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Discard Signature?", isPresented: $showDiscardAlert) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your current signature will be lost.")
            }
        }
    }

    private func clearCanvas() {
        strokes = []
        currentStroke = SignatureStroke()
    }

    private func cancelCapture() {
        if hasInk {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func saveSignature() {
        guard let image = SignatureRenderer.renderedImage(from: drawnStrokes) else { return }
        onSave(image)
        dismiss()
    }
}

private struct SignatureDrawingSurface: View {
    @Binding var strokes: [SignatureStroke]
    @Binding var currentStroke: SignatureStroke

    private var allStrokes: [SignatureStroke] {
        currentStroke.points.isEmpty ? strokes : strokes + [currentStroke]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.npBrandYellow, lineWidth: 2)

                if allStrokes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("Sign here")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)

                        Text("Your saved signature will have a transparent background.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Canvas { context, size in
                    for stroke in allStrokes where !stroke.points.isEmpty {
                        if stroke.points.count == 1 {
                            let point = SignatureRenderer.scaledPoint(for: stroke.points[0], in: size)
                            let dotPath = Path(
                                ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)
                            )
                            context.fill(dotPath, with: .color(.black))
                        } else {
                            let path = SignatureRenderer.smoothedPath(for: stroke.points, in: size)
                            context.stroke(
                                path,
                                with: .color(.black),
                                style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                            )
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        appendPoint(value.location, in: geometry.size)
                    }
                    .onEnded { _ in
                        commitCurrentStroke()
                    }
            )
        }
    }

    private func appendPoint(_ point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let normalizedPoint = CGPoint(
            x: min(max(point.x / size.width, 0), 1),
            y: min(max(point.y / size.height, 0), 1)
        )

        if currentStroke.points.last == normalizedPoint {
            return
        }

        currentStroke.points.append(normalizedPoint)
    }

    private func commitCurrentStroke() {
        guard !currentStroke.points.isEmpty else { return }
        strokes.append(currentStroke)
        currentStroke = SignatureStroke()
    }
}

private struct SignatureStroke: Equatable {
    var points: [CGPoint] = []
}

private enum SignatureRenderer {
    static let exportSize = CGSize(width: 1400, height: 500)

    static func renderedImage(from strokes: [SignatureStroke]) -> UIImage? {
        guard strokes.contains(where: { !$0.points.isEmpty }) else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: exportSize, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.setLineWidth(5)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            for stroke in strokes where !stroke.points.isEmpty {
                if stroke.points.count == 1 {
                    let point = scaledPoint(for: stroke.points[0], in: exportSize)
                    let dotRect = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)
                    cgContext.fillEllipse(in: dotRect)
                } else {
                    let bezierPath = smoothedBezierPath(for: stroke.points, in: exportSize)
                    cgContext.addPath(bezierPath.cgPath)
                    cgContext.strokePath()
                }
            }
        }
    }

    static func smoothedPath(for points: [CGPoint], in size: CGSize) -> Path {
        Path(smoothedBezierPath(for: points, in: size).cgPath)
    }

    static func scaledPoint(for normalizedPoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: normalizedPoint.x * size.width,
            y: normalizedPoint.y * size.height
        )
    }

    private static func smoothedBezierPath(for points: [CGPoint], in size: CGSize) -> UIBezierPath {
        let scaledPoints = points.map { scaledPoint(for: $0, in: size) }
        let path = UIBezierPath()

        guard let firstPoint = scaledPoints.first else {
            return path
        }

        path.move(to: firstPoint)

        if scaledPoints.count == 1 {
            path.addLine(to: firstPoint)
            return path
        }

        if scaledPoints.count == 2 {
            path.addLine(to: scaledPoints[1])
            return path
        }

        for index in 1..<scaledPoints.count {
            let previousPoint = scaledPoints[index - 1]
            let currentPoint = scaledPoints[index]
            let midpoint = CGPoint(
                x: (previousPoint.x + currentPoint.x) / 2,
                y: (previousPoint.y + currentPoint.y) / 2
            )

            path.addQuadCurve(to: midpoint, controlPoint: previousPoint)

            if index == scaledPoints.count - 1 {
                path.addQuadCurve(to: currentPoint, controlPoint: currentPoint)
            }
        }

        return path
    }
}
