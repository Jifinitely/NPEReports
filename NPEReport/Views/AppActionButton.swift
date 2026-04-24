import SwiftUI

struct AppActionLabel: View {
    let title: String
    var systemImage: String? = nil
    let background: Color
    let foreground: Color
    var fullWidth = true
    var minHeight: CGFloat = 48
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.headline.weight(.semibold))
        .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight)
        .padding(.horizontal, fullWidth ? 0 : 16)
        .background(background)
        .foregroundColor(foreground)
        .cornerRadius(cornerRadius)
    }
}

struct AppActionButton: View {
    let title: String
    var systemImage: String? = nil
    let background: Color
    let foreground: Color
    var fullWidth = true
    var minHeight: CGFloat = 48
    var cornerRadius: CGFloat = 12
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppActionLabel(
                title: title,
                systemImage: systemImage,
                background: background,
                foreground: foreground,
                fullWidth: fullWidth,
                minHeight: minHeight,
                cornerRadius: cornerRadius
            )
        }
        .buttonStyle(.plain)
    }
}

struct AppIconActionButton: View {
    let systemImage: String
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 48, height: 48)
                .background(background)
                .foregroundColor(foreground)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
