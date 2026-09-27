import SwiftUI

enum Theme {
    static let accent = Color(red: 0.78, green: 1.0, blue: 0.22)
    static let ink = Color(red: 0.06, green: 0.08, blue: 0.08)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let radius: CGFloat = 22
}

struct RelayCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Theme.ink)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension View {
    func relayBackground() -> some View { background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea()) }
}
