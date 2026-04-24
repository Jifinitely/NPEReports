import SwiftUI

extension Color {
    static let npBrandYellow = Color(red: 1.0, green: 0.88, blue: 0.0)
    static let npBackground = Color(uiColor: .systemGroupedBackground)
    static let npSurface = Color(uiColor: .systemBackground)
    static let npSecondarySurface = Color(uiColor: .secondarySystemBackground)
    static let npFieldSurface = Color(uiColor: .tertiarySystemBackground)
}

struct BrandHeaderView: View {
    let title: String

    var body: some View {
        Rectangle()
            .fill(Color.npBrandYellow)
            .frame(height: 54)
            .overlay(
                HStack {
                    BrandLogoView()
                        .padding(.leading, 10)
                    Spacer()
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 24)
                }
            )
    }
}

struct BrandLogoView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)

            HeaderFallbackLogoMark()
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .frame(width: 126, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct HeaderFallbackLogoMark: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("N&P")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    ChevronShape()
                        .fill(index == 0 ? Color(red: 1.0, green: 0.74, blue: 0.08) : Color.npBrandYellow)
                        .frame(width: 11, height: 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
