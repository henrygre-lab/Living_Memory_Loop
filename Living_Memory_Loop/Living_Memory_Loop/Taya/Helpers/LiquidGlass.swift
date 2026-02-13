import SwiftUI

enum LiquidGlassKind {
    case regular
    case prominent
}

extension Button {
    @ViewBuilder
    func liquidGlass(_ kind: LiquidGlassKind = .regular) -> some View {
        if #available(iOS 26.0, *) {
            switch kind {
            case .regular:
                buttonStyle(.glass)
            case .prominent:
                buttonStyle(.glassProminent)
            }
        } else {
            buttonStyle(.plain)
        }
    }
}
