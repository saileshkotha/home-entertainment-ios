import SwiftUI

enum Theme {
    static let accent = Color.indigo
    static let accentGradient = LinearGradient(
        colors: [Color.indigo, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let explore = Color.indigo
    static let tv = Color.teal
    static let downloads = Color.orange

    static let heroGlass: Glass = .regular.tint(.indigo)
    static let cardGlass: Glass = .regular
    static let interactiveGlass: Glass = .regular.interactive()
}
