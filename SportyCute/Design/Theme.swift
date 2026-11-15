import SwiftUI

enum Theme {
    static let paper = Color(red: 0.97, green: 0.958, blue: 0.927)
    static let ink = Color(red: 0.13, green: 0.11, blue: 0.17)
    static let muted = Color(red: 0.37, green: 0.34, blue: 0.41)
    static let line = Color(red: 0.87, green: 0.85, blue: 0.82)
    static let violet = Color(red: 0.25, green: 0.16, blue: 0.44)
    static let lavender = Color(red: 0.88, green: 0.82, blue: 0.99)
    static let lime = Color(red: 0.85, green: 0.98, blue: 0.40)
    static let peach = Color(red: 1, green: 0.81, blue: 0.71)

    static func display(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .rounded, weight: .black)
    }

    static let label = Font.system(.caption2, design: .monospaced, weight: .semibold)
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right").accessibilityHidden(true)
            }
            .font(.system(.headline, design: .rounded, weight: .heavy))
            .padding(.horizontal, 19)
            .padding(.vertical, 16)
            .foregroundStyle(Theme.ink)
            .background(Theme.lime.opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeading: View {
    let title: String
    let detail: String?

    init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.display(.title2)).accessibilityAddTraits(.isHeader)
            Spacer()
            if let detail {
                Text(detail).font(Theme.label).foregroundStyle(Theme.muted)
            }
        }
    }
}
