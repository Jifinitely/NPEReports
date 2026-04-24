import SwiftUI

struct SplashScreenView: View {
    private enum Timing {
        static let nDelay = 0.12
        static let nDuration = 0.42
        static let symbolDelay = 0.54
        static let symbolDuration = 0.34
        static let pDelay = 0.88
        static let pDuration = 0.42
        static let arrowsDelay = 1.28
        static let arrowsDuration = 0.46
        static let statusDelay = 1.54
        static let statusDuration = 0.34
        static let solidDelay = 1.78
        static let solidDuration = 0.28
        static let strokeFadeDelay = 1.92
        static let strokeFadeDuration = 0.26
        static let headlineDelay = 1.96
        static let headlineDuration = 0.42
        static let shineDelay = 2.18
        static let shineDuration = 0.62
        static let finishDelay = 3.06
        static let reducedMotionFinishDelay = 1.1
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinished: () -> Void

    @State private var nProgress: CGFloat = 0
    @State private var symbolProgress: CGFloat = 0
    @State private var pProgress: CGFloat = 0
    @State private var arrowsProgress: CGFloat = 0
    @State private var solidLogoOpacity = 0.0
    @State private var solidLogoScale: CGFloat = 0.985
    @State private var strokeOpacity = 1.0
    @State private var shineProgress: CGFloat = 0
    @State private var ambientGlowOpacity = 0.08
    @State private var ambientGlowScale: CGFloat = 0.96
    @State private var chevronSweepPhase: CGFloat = 0.05
    @State private var headlineOpacity = 0.0
    @State private var headlineOffset: CGFloat = 18
    @State private var statusOpacity = 0.0
    @State private var statusOffset: CGFloat = 16
    @State private var hasAnimated = false

    init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    private var cleanPanelImage: UIImage? {
        UIImage(named: "np_clean_panel_no_yellow_border")
            ?? UIImage(named: "np_clean_panel_no_yellow_border.png")
    }

    var body: some View {
        GeometryReader { geometry in
            let logoSide = min(
                geometry.size.width * 0.64,
                geometry.size.height * 0.34,
                290
            )
            let logoPanelWidth = logoSide * 1.08
            let logoPanelHeight = logoPanelWidth * 0.296
            let logoPanelCornerRadius: CGFloat = 32
            let statusWidth = geometry.size.width.isFinite
                ? min(max(geometry.size.width - 40, 0), 380.0)
                : 0
            let titleSize = min(geometry.size.width * 0.09, 36)

            ZStack {
                splashBackground(logoSide: logoSide)

                VStack(spacing: 18) {
                    SplashEyebrowBadge()

                    ZStack {
                        if let cleanPanelImage {
                            Image(uiImage: cleanPanelImage)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFill()
                                .frame(width: logoPanelWidth, height: logoPanelHeight)
                                .scaleEffect(1.08)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: logoPanelCornerRadius,
                                        style: .continuous
                                    )
                                )
                                .overlay {
                                    ChevronSweepOverlay(phase: chevronSweepPhase)
                                        .frame(width: logoPanelWidth, height: logoPanelHeight)
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: logoPanelCornerRadius,
                                                style: .continuous
                                            )
                                        )
                                        .blendMode(.screen)
                                }
                                .overlay {
                                    ChevronPulseOverlay(phase: chevronSweepPhase)
                                        .frame(width: logoPanelWidth, height: logoPanelHeight)
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: logoPanelCornerRadius,
                                                style: .continuous
                                            )
                                        )
                                        .blendMode(.screen)
                                }
                                .shadow(color: Color.black.opacity(0.28), radius: 20, y: 12)
                                .shadow(color: Color.black.opacity(0.14), radius: 6, y: 2)
                                .background {
                                    ZStack {
                                        RoundedRectangle(
                                            cornerRadius: logoPanelCornerRadius,
                                            style: .continuous
                                        )
                                        .fill(Color.black.opacity(0.10))
                                        .scaleEffect(x: 1.01, y: 1.05)
                                        .blur(radius: 2)

                                        RoundedRectangle(
                                            cornerRadius: logoPanelCornerRadius,
                                            style: .continuous
                                        )
                                        .fill(Color.npBrandYellow.opacity(0.18))
                                        .scaleEffect(x: 1.03, y: 1.16)
                                        .blur(radius: 22)
                                    }
                                }
                                .opacity(1)
                                .zIndex(10)
                        }
                    }
                    .frame(width: logoSide, height: logoSide)
                    .offset(y: -12)

                    VStack(spacing: 10) {
                        SplashWordmarkTitle(text: "NP E-REPORTS", fontSize: titleSize)
                            .frame(maxWidth: logoSide + 52)

                        Text("Site reports ready in seconds")
                            .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .semibold, design: .rounded))
                            .tracking(0.4)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.84),
                                        Color.npBrandYellow.opacity(0.72)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .opacity(headlineOpacity)
                    .offset(y: headlineOffset)

                    SplashStatusPanel(reduceMotion: reduceMotion)
                        .frame(maxWidth: statusWidth)
                        .opacity(statusOpacity)
                        .offset(y: statusOffset)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear(perform: startAnimation)
        }
    }

    @ViewBuilder
    private func splashBackground(logoSide: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.03, green: 0.03, blue: 0.04),
                    Color(red: 0.01, green: 0.01, blue: 0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.npBrandYellow.opacity(ambientGlowOpacity),
                    Color.npBrandYellow.opacity(ambientGlowOpacity * 0.28),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: logoSide * 0.42
            )
            .frame(width: logoSide * 0.82, height: logoSide * 0.82)
            .scaleEffect(ambientGlowScale)
            .offset(y: -logoSide * 0.04)
            .blur(radius: 24)

            Circle()
                .fill(Color.white.opacity(0.018))
                .frame(width: logoSide * 0.62, height: logoSide * 0.62)
                .offset(y: -logoSide * 0.05)
                .blur(radius: 18)
        }
    }

    private func startAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.22)) {
                ambientGlowOpacity = 0.17
                ambientGlowScale = 1.0
                chevronSweepPhase = 0.6
                nProgress = 1
                symbolProgress = 1
                pProgress = 1
                arrowsProgress = 1
                solidLogoOpacity = 1
                solidLogoScale = 1
                strokeOpacity = 0
                shineProgress = 1
                headlineOpacity = 1
                headlineOffset = 0
                statusOpacity = 1
                statusOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + Timing.reducedMotionFinishDelay) {
                onFinished()
            }
            return
        }

        withAnimation(.easeOut(duration: 0.9)) {
            ambientGlowOpacity = 0.17
            ambientGlowScale = 1.0
        }

        withAnimation(.linear(duration: 2.3).repeatForever(autoreverses: false)) {
            chevronSweepPhase = 1.24
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.nDelay) {
            withAnimation(.easeInOut(duration: Timing.nDuration)) {
                nProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.symbolDelay) {
            withAnimation(.easeInOut(duration: Timing.symbolDuration)) {
                symbolProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.pDelay) {
            withAnimation(.easeInOut(duration: Timing.pDuration)) {
                pProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.arrowsDelay) {
            withAnimation(.easeInOut(duration: Timing.arrowsDuration)) {
                arrowsProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.statusDelay) {
            withAnimation(.easeOut(duration: Timing.statusDuration)) {
                statusOpacity = 1
                statusOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.solidDelay) {
            withAnimation(.easeOut(duration: Timing.solidDuration)) {
                solidLogoOpacity = 1
                solidLogoScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.strokeFadeDelay) {
            withAnimation(.easeOut(duration: Timing.strokeFadeDuration)) {
                strokeOpacity = 0.12
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.headlineDelay) {
            withAnimation(.easeOut(duration: Timing.headlineDuration)) {
                headlineOpacity = 1
                headlineOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.shineDelay) {
            withAnimation(.easeInOut(duration: Timing.shineDuration)) {
                shineProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.finishDelay) {
            onFinished()
        }
    }
}

private struct SplashEyebrowBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.npBrandYellow)
                .frame(width: 8, height: 8)
                .shadow(color: Color.npBrandYellow.opacity(0.6), radius: 10)

            Text("N&P ELECTRICAL")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color.white.opacity(0.82))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 8)
    }
}

private struct SplashWordmarkTitle: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        ZStack(alignment: .center) {
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .default))
                .italic()
                .tracking(-1.1)
                .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))
                .foregroundStyle(Color.black.opacity(0.7))
                .offset(x: 1.6, y: 2.2)

            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .default))
                .italic()
                .tracking(-1.1)
                .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.95),
                            Color.npBrandYellow.opacity(0.92)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    Text(text)
                        .font(.system(size: fontSize, weight: .black, design: .default))
                        .italic()
                        .tracking(-1.1)
                        .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))
                        .foregroundStyle(.clear)
                        .overlay(alignment: .top) {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .mask(
                            Text(text)
                                .font(.system(size: fontSize, weight: .black, design: .default))
                                .italic()
                                .tracking(-1.1)
                                .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))
                        )
                }
                .scaleEffect(x: 1.02, y: 1.0)
                .shadow(color: Color.npBrandYellow.opacity(0.2), radius: 12, y: 2)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, 10)
        .background(alignment: .bottom) {
            Capsule(style: .continuous)
                .fill(Color.npBrandYellow.opacity(0.12))
                .frame(height: 10)
                .blur(radius: 8)
                .offset(y: 16)
        }
    }
}

private struct SplashStatusPanel: View {
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preparing workspace")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))

                    Text("Forms, photos, signatures, and PDF export.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.56))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                SplashSignalPill(reduceMotion: reduceMotion)
            }

            SplashLoadingTrack(reduceMotion: reduceMotion)

            HStack(spacing: 10) {
                SplashFeatureMetric(value: "AS/NZS", title: "Standards")
                SplashFeatureMetric(value: "Photos", title: "Ready")
                SplashFeatureMetric(value: "PDF", title: "Export")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.055),
                            Color.white.opacity(0.025)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.24), radius: 22, y: 12)
    }
}

private struct SplashSignalPill: View {
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { context in
            let rawPhase = context.date.timeIntervalSinceReferenceDate * 2.3
            let pulse = reduceMotion ? 0.82 : 0.68 + (sin(rawPhase) + 1) * 0.16

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.npBrandYellow.opacity(pulse))
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.npBrandYellow.opacity(0.45), radius: 6)

                Text("Loading")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.18))
            )
        }
    }
}

private struct SplashLoadingTrack: View {
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                let phase = reduceMotion
                    ? 0.5
                    : context.date.timeIntervalSinceReferenceDate.remainder(dividingBy: 1.7) / 1.7
                let highlightWidth = geometry.size.width * 0.34
                let travel = max(geometry.size.width - highlightWidth, 0)

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    HStack(spacing: max(4, geometry.size.width * 0.022)) {
                        ForEach(0..<16, id: \.self) { _ in
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 3)
                        }
                    }
                    .padding(.horizontal, 10)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.npBrandYellow.opacity(0.18),
                                    Color.npBrandYellow.opacity(0.95),
                                    Color.white.opacity(0.82)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: highlightWidth)
                        .offset(x: travel * phase)
                }
            }
        }
        .frame(height: 10)
    }
}

private struct SplashFeatureMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))
                .lineLimit(1)

            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.56))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.16))
        )
    }
}

private struct LogoCardSurface: View {
    var body: some View {
        GeometryReader { geometry in
            let cornerRadius = geometry.size.width * 0.17

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.98),
                            Color(red: 0.03, green: 0.03, blue: 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.07),
                                    Color.npBrandYellow.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.npBrandYellow.opacity(0.14), radius: 26)
        }
    }
}

private struct DrawnLogoMark: View {
    let nProgress: CGFloat
    let symbolProgress: CGFloat
    let pProgress: CGFloat
    let arrowsProgress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let contentWidth = width * 0.8
            let contentHeight = height * 0.34
            let letterStroke = max(5, contentHeight * 0.11)
            let arrowStroke = max(4, contentHeight * 0.1)

            HStack(alignment: .center, spacing: contentWidth * 0.04) {
                NStrokeShape()
                    .trim(from: 0, to: nProgress)
                    .stroke(
                        Color.white.opacity(0.96),
                        style: StrokeStyle(
                            lineWidth: letterStroke,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(color: Color.white.opacity(0.22), radius: 10)
                    .frame(width: contentWidth * 0.18, height: contentHeight)

                AmpersandStrokeShape()
                    .trim(from: 0, to: symbolProgress)
                    .stroke(
                        Color.npBrandYellow,
                        style: StrokeStyle(
                            lineWidth: letterStroke * 0.7,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(color: Color.npBrandYellow.opacity(0.28), radius: 8)
                    .frame(width: contentWidth * 0.11, height: contentHeight * 0.72)
                    .offset(y: contentHeight * 0.15)

                PStrokeShape()
                    .trim(from: 0, to: pProgress)
                    .stroke(
                        Color.white.opacity(0.96),
                        style: StrokeStyle(
                            lineWidth: letterStroke,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(color: Color.white.opacity(0.22), radius: 10)
                    .frame(width: contentWidth * 0.18, height: contentHeight)

                HStack(spacing: contentWidth * 0.012) {
                    ForEach(0..<3, id: \.self) { index in
                        ChevronStrokeShape()
                            .trim(from: 0, to: max(0, min(1, arrowsProgress - CGFloat(index) * 0.12)))
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.74, blue: 0.10),
                                        Color(red: 1.0, green: 0.92, blue: 0.16)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(
                                    lineWidth: arrowStroke,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                            .shadow(color: Color.npBrandYellow.opacity(0.24), radius: 8)
                            .frame(width: contentWidth * 0.11, height: contentHeight * 0.72)
                    }
                }
            }
            .frame(width: contentWidth, height: contentHeight)
            .position(x: width * 0.5, y: height * 0.5)
        }
    }
}

private struct SolidLogoMark: View {
    private let chevronColors = [
        Color(red: 1.0, green: 0.72, blue: 0.08),
        Color(red: 1.0, green: 0.80, blue: 0.08),
        Color(red: 1.0, green: 0.92, blue: 0.08)
    ]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let contentWidth = width * 0.8
            let contentHeight = height * 0.34
            let letterSize = contentHeight * 0.96

            HStack(alignment: .center, spacing: contentWidth * 0.04) {
                ZStack(alignment: .bottomLeading) {
                    HStack(spacing: -contentWidth * 0.055) {
                        Text("N")
                            .font(.system(size: letterSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(x: 1.03, y: 1.0)

                        Text("P")
                            .font(.system(size: letterSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(x: 1.03, y: 1.0)
                    }

                    SlashBarShape()
                        .fill(Color.black)
                        .frame(width: contentWidth * 0.03, height: contentHeight * 0.9)
                        .offset(x: contentWidth * 0.09, y: -contentHeight * 0.02)

                    Text("&")
                        .font(.system(size: contentHeight * 0.5, weight: .black, design: .rounded))
                        .foregroundStyle(Color.npBrandYellow)
                        .shadow(color: .black, radius: 0, x: 2, y: 0)
                        .shadow(color: .black, radius: 0, x: -2, y: 0)
                        .shadow(color: .black, radius: 0, x: 0, y: 2)
                        .shadow(color: .black, radius: 0, x: 0, y: -2)
                        .offset(x: contentWidth * 0.055, y: contentHeight * 0.13)
                }
                .frame(width: contentWidth * 0.44, height: contentHeight)

                HStack(spacing: contentWidth * 0.012) {
                    ForEach(Array(chevronColors.enumerated()), id: \.offset) { index, color in
                        FilledChevronShape()
                            .fill(color)
                            .frame(width: contentWidth * 0.11, height: contentHeight * 0.72)
                            .shadow(color: color.opacity(index == 2 ? 0.32 : 0.16), radius: 8)
                    }
                }
            }
            .frame(width: contentWidth, height: contentHeight)
            .position(x: width * 0.5, y: height * 0.5)
        }
    }
}

private struct LogoShineOverlay: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let shineWidth = geometry.size.width * 0.42
            let travel = geometry.size.width + shineWidth * 1.4

            RoundedRectangle(cornerRadius: geometry.size.height * 0.04, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.16),
                            Color.npBrandYellow.opacity(0.22),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: shineWidth, height: geometry.size.height * 0.08)
                .blur(radius: 7)
                .offset(x: -travel * 0.5 + travel * progress)
                .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
        }
    }
}

private struct NStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.08))

        return path
    }
}

private struct AmpersandStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.18))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.34),
            control1: CGPoint(x: rect.width * 0.72, y: rect.height * 0.05),
            control2: CGPoint(x: rect.width * 0.38, y: rect.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.60, y: rect.height * 0.58),
            control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.48),
            control2: CGPoint(x: rect.width * 0.46, y: rect.height * 0.48)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.28, y: rect.height * 0.84),
            control1: CGPoint(x: rect.width * 0.60, y: rect.height * 0.72),
            control2: CGPoint(x: rect.width * 0.40, y: rect.height * 0.90)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.80, y: rect.height * 0.70),
            control1: CGPoint(x: rect.width * 0.20, y: rect.height * 0.66),
            control2: CGPoint(x: rect.width * 0.68, y: rect.height * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.58, y: rect.height * 0.46),
            control1: CGPoint(x: rect.width * 0.86, y: rect.height * 0.82),
            control2: CGPoint(x: rect.width * 0.70, y: rect.height * 0.62)
        )

        return path
    }
}

private struct PStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.08))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.52),
            control1: CGPoint(x: rect.width * 0.94, y: rect.height * 0.10),
            control2: CGPoint(x: rect.width * 0.94, y: rect.height * 0.48)
        )
        path.addLine(to: CGPoint(x: rect.width * 0.14, y: rect.height * 0.52))

        return path
    }
}

private struct ChevronStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.08))

        return path
    }
}

private struct SlashBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

private struct FilledChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.26

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

private struct ChevronSweepOverlay: View {
    let phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let chevronZoneWidth = geometry.size.width * 0.42
            let sweepWidth = chevronZoneWidth * 0.22
            let travel = chevronZoneWidth + sweepWidth * 2.1

            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.03),
                        Color.white.opacity(0.12),
                        Color(red: 1.0, green: 0.94, blue: 0.62).opacity(0.09),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: sweepWidth, height: geometry.size.height * 0.66)
                .rotationEffect(.degrees(-7))
                .offset(x: -sweepWidth + travel * phase)
                .blur(radius: 0.8)
            }
            .frame(width: chevronZoneWidth, height: geometry.size.height, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .clipped()
            .allowsHitTesting(false)
        }
    }
}

private struct ChevronPulseOverlay: View {
    let phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let chevronZoneWidth = geometry.size.width * 0.42
            let pulseWidth = chevronZoneWidth * 0.34
            let travel = chevronZoneWidth + pulseWidth * 1.9

            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 1.0, green: 0.84, blue: 0.20).opacity(0.03),
                    Color(red: 1.0, green: 0.94, blue: 0.62).opacity(0.11),
                    Color(red: 1.0, green: 0.84, blue: 0.22).opacity(0.05),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: pulseWidth, height: geometry.size.height * 0.62)
            .offset(x: -pulseWidth * 0.9 + travel * phase)
            .blur(radius: 1.4)
            .frame(width: chevronZoneWidth, height: geometry.size.height, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .clipped()
            .allowsHitTesting(false)
        }
    }
}

struct MainMenuView: View {
    var body: some View {
        MainTabView()
    }
}

struct LaunchContainerView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            (showSplash ? Color.black : Color.npBackground)
                .ignoresSafeArea()

            MainMenuView()
                .opacity(showSplash ? 0 : 1)
                .scaleEffect(showSplash ? 1.02 : 1.0)
                .offset(y: showSplash ? 10 : 0)
                .blur(radius: showSplash ? 8 : 0)
                .allowsHitTesting(!showSplash)

            if showSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.62)) {
                        showSplash = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.03)))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.62), value: showSplash)
    }
}

#Preview("Splash") {
    SplashScreenView()
}

#Preview("Launch Container") {
    LaunchContainerView()
}
