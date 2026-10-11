import SwiftUI

enum GameMode: String, CaseIterable {
    case ribbon = "Ribbon"
    case linked = "Linked"
}

struct ContentView: View {
    @AppStorage("selectedGameMode") private var selectedMode = GameMode.ribbon.rawValue

    private var mode: GameMode {
        GameMode(rawValue: selectedMode) ?? .ribbon
    }

    var body: some View {
        ZStack(alignment: .top) {
            switch mode {
            case .ribbon:
                RibbonGameView()
            case .linked:
                LinkedGameView()
            }

            ModeSelector(selection: Binding(
                get: { mode },
                set: { selectedMode = $0.rawValue }
            ))
            .padding(.top, 8)
        }
    }
}

private struct ModeSelector: View {
    @Binding var selection: GameMode

    var body: some View {
        HStack(spacing: 2) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                Button {
                    selection = mode
                } label: {
                    Text(mode.rawValue)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(selection == mode ? BetweenPalette.ivory : BetweenPalette.charcoal.opacity(0.68))
                        .padding(.horizontal, 14)
                        .frame(minHeight: 34)
                        .background(selection == mode ? BetweenPalette.charcoal : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.62))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(BetweenPalette.charcoal.opacity(0.09), lineWidth: 1)
        }
    }
}

#Preview("Between Modes") {
    ContentView()
}
