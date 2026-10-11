import SwiftUI

enum BetweenPalette {
    static let ivory = Color(red: 0.965, green: 0.940, blue: 0.875)
    static let coral = Color(red: 0.88, green: 0.30, blue: 0.28)
    static let blue = Color(red: 0.16, green: 0.42, blue: 0.67)
    static let charcoal = Color(red: 0.13, green: 0.14, blue: 0.16)
    static let lavender = Color(red: 0.48, green: 0.39, blue: 0.63)
    static let peg = Color(red: 0.36, green: 0.32, blue: 0.29)
}

struct RibbonGameView: View {
    @State private var game = GameState()
    @State private var isHintVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            BetweenPalette.ivory
                .ignoresSafeArea()

            if game.hasCompletedGame {
                CompletionView(replay: game.replay)
                    .transition(.opacity)
            } else {
                VStack(spacing: 14) {
                    HeaderView(
                        levelLabel: game.levelLabel,
                        canUndo: game.canUndo,
                        hint: {
                            isHintVisible.toggle()
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        },
                        undo: {
                            isHintVisible = false
                            game.undo()
                        },
                        reset: {
                            isHintVisible = false
                            game.reset()
                        }
                    )

                    VStack(spacing: 3) {
                        Text(game.puzzle.title)
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(BetweenPalette.charcoal)
                        Text(
                            game.didRestartForWrongOrder
                                ? "Wrong peg — level restarted."
                                : (isHintVisible ? "The next peg is glowing." : "Follow the dotted route in order.")
                        )
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(
                                game.didRestartForWrongOrder
                                    ? BetweenPalette.coral
                                    : BetweenPalette.charcoal.opacity(0.68)
                            )
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    PuzzleBoard(game: game, isHintVisible: isHintVisible)
                        .frame(maxWidth: 720, maxHeight: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
                .padding(.top, 56)
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: game.hasCompletedGame)
        .onChange(of: game.attachedCount) { _, _ in
            isHintVisible = false
        }
        .preferredColorScheme(.light)
    }
}

private struct HeaderView: View {
    let levelLabel: String
    let canUndo: Bool
    let hint: () -> Void
    let undo: () -> Void
    let reset: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("BETWEEN")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(BetweenPalette.charcoal)
                Text("PUZZLE \(levelLabel)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(BetweenPalette.lavender)
            }

            Spacer()

            HStack(spacing: 2) {
                ControlButton(title: "Hint", systemImage: "lightbulb", enabled: true, action: hint)
                ControlButton(title: "Undo", systemImage: "arrow.uturn.backward", enabled: canUndo, action: undo)
                ControlButton(title: "Reset", systemImage: "arrow.counterclockwise", enabled: true, action: reset)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ControlButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(BetweenPalette.charcoal.opacity(enabled ? 0.78 : 0.25))
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}

private struct PuzzleBoard: View {
    @Bindable var game: GameState
    let isHintVisible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let puzzle = game.puzzle
            let target = BoardGeometry.path(points: BoardGeometry.targetPoints(for: puzzle), in: size)
            let route = BoardGeometry.path(
                points: BoardGeometry.routePoints(
                    puzzle: puzzle,
                    coral: game.coralPosition,
                    blue: game.bluePosition,
                    attachedCount: game.attachedCount
                ),
                in: size
            )

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.26))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(BetweenPalette.charcoal.opacity(0.07), lineWidth: 1)
                    }

                target
                    .stroke(
                        BetweenPalette.lavender.opacity(0.48),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 10])
                    )
                    .padding(1)

                GoalZone(position: puzzle.coralGoal, color: BetweenPalette.coral, symbol: .circle, size: size)
                GoalZone(position: puzzle.blueGoal, color: BetweenPalette.blue, symbol: .diamond, size: size)

                ForEach(Array(puzzle.pegs.enumerated()), id: \.offset) { index, peg in
                    PegView(
                        position: peg,
                        isAttached: attachedPegIndices.contains(index),
                        isEligible: isHintVisible && eligiblePegIndex == index,
                        size: size
                    )
                }

                route
                    .stroke(
                        BetweenPalette.charcoal.opacity(game.isSolved ? 0 : 0.92),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: BetweenPalette.charcoal.opacity(0.12), radius: 3, y: 2)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: game.isSolved)

                PlayerDot(position: game.coralPosition, player: .coral, size: size)
                    .opacity(game.isSolved ? 0 : 1)
                PlayerDot(position: game.bluePosition, player: .blue, size: size)
                    .opacity(game.isSolved ? 0 : 1)

                MultiTouchSurface(
                    coralPosition: game.coralPosition,
                    bluePosition: game.bluePosition,
                    enabled: !game.isSolved,
                    onBegin: game.beginDrag,
                    onMove: game.move
                )
                .accessibilityHidden(true)

                if game.isSolved {
                    SuccessOverlay(next: game.next)
                        .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: game.isSolved)
        }
    }

    private var attachedPegIndices: Set<Int> {
        Set(game.puzzle.requiredPegIndices.prefix(game.attachedCount))
    }

    private var eligiblePegIndex: Int? {
        guard game.attachedCount < game.puzzle.requiredPegIndices.count else { return nil }
        return game.puzzle.requiredPegIndices[game.attachedCount]
    }
}

private enum DotSymbol {
    case circle, diamond
}

private struct GoalZone: View {
    let position: NormalizedPoint
    let color: Color
    let symbol: DotSymbol
    let size: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.08))
            Circle()
                .stroke(color.opacity(0.42), style: StrokeStyle(lineWidth: 2, dash: [3, 5]))
            symbolShape
                .frame(width: 12, height: 12)
        }
        .frame(width: 54, height: 54)
        .position(position.point(in: size))
        .accessibilityElement()
        .accessibilityLabel(symbol == .circle ? "Coral goal" : "Blue goal")
    }

    @ViewBuilder
    private var symbolShape: some View {
        if symbol == .circle {
            Circle()
                .stroke(color.opacity(0.48), lineWidth: 2)
        } else {
            Diamond()
                .stroke(color.opacity(0.48), lineWidth: 2)
        }
    }
}

private struct PegView: View {
    let position: NormalizedPoint
    let isAttached: Bool
    let isEligible: Bool
    let size: CGSize

    var body: some View {
        ZStack {
            if isEligible {
                Circle()
                    .stroke(BetweenPalette.lavender.opacity(0.45), lineWidth: 2)
                    .frame(width: 42, height: 42)
            }
            Circle()
                .fill(isAttached ? BetweenPalette.charcoal : BetweenPalette.ivory)
                .frame(width: 18, height: 18)
                .overlay {
                    Circle()
                        .stroke(BetweenPalette.peg.opacity(0.85), lineWidth: 2)
                }
            if isAttached {
                Circle()
                    .fill(BetweenPalette.ivory)
                    .frame(width: 5, height: 5)
            }
        }
        .position(position.point(in: size))
        .accessibilityElement()
        .accessibilityLabel(isAttached ? "Attached peg" : (isEligible ? "Next peg" : "Peg"))
    }
}

private struct PlayerDot: View {
    let position: NormalizedPoint
    let player: Player
    let size: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(player == .coral ? BetweenPalette.coral : BetweenPalette.blue)
                .frame(width: 46, height: 46)
                .shadow(color: color.opacity(0.24), radius: 7, y: 3)
            if player == .coral {
                Circle()
                    .stroke(Color.white.opacity(0.94), lineWidth: 2.5)
                    .frame(width: 13, height: 13)
            } else {
                Diamond()
                    .stroke(Color.white.opacity(0.94), lineWidth: 2.5)
                    .frame(width: 14, height: 14)
            }
        }
        .frame(width: 58, height: 58)
        .position(position.point(in: size))
        .accessibilityElement()
        .accessibilityLabel(player == .coral ? "Coral player dot, circle symbol" : "Blue player dot, diamond symbol")
        .allowsHitTesting(false)
    }

    private var color: Color {
        player == .coral ? BetweenPalette.coral : BetweenPalette.blue
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct SuccessOverlay: View {
    let next: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                Text("Completed")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BetweenPalette.charcoal)
                Button("Next", action: next)
                    .buttonStyle(BetweenButtonStyle())
                    .accessibilityHint("Opens the next puzzle")
            }
            .padding(.bottom, 22)
        }
    }
}

struct BetweenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(BetweenPalette.ivory)
            .padding(.horizontal, 22)
            .frame(minHeight: 44)
            .background(BetweenPalette.charcoal.opacity(configuration.isPressed ? 0.74 : 0.94))
            .clipShape(Capsule())
    }
}

private struct IllustrationView: View {
    let kind: IllustrationKind
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            let path = illustrationPath(in: canvasSize)
            context.stroke(
                path,
                with: .color(BetweenPalette.charcoal),
                style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
            )

            let accent = accentPath(in: canvasSize)
            context.stroke(
                accent,
                with: .color(BetweenPalette.lavender.opacity(0.78)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size.width, height: size.height)
        .accessibilityElement()
        .accessibilityLabel(illustrationLabel)
        .allowsHitTesting(false)
    }

    private var illustrationLabel: String {
        switch kind {
        case .sailboat: "A sailboat"
        case .mountain: "A mountain"
        case .leaf: "A leaf"
        case .fish: "A fish"
        case .constellation: "A constellation"
        }
    }

    private func p(_ x: CGFloat, _ y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    private func illustrationPath(in size: CGSize) -> Path {
        var path = Path()
        switch kind {
        case .sailboat:
            path.move(to: p(0.23, 0.66, in: size))
            path.addQuadCurve(to: p(0.77, 0.66, in: size), control: p(0.50, 0.78, in: size))
            path.move(to: p(0.50, 0.66, in: size))
            path.addLine(to: p(0.50, 0.26, in: size))
            path.addLine(to: p(0.72, 0.58, in: size))
            path.addLine(to: p(0.50, 0.58, in: size))
        case .mountain:
            path.move(to: p(0.16, 0.70, in: size))
            path.addLine(to: p(0.40, 0.32, in: size))
            path.addLine(to: p(0.53, 0.52, in: size))
            path.addLine(to: p(0.66, 0.26, in: size))
            path.addLine(to: p(0.86, 0.70, in: size))
        case .leaf:
            path.move(to: p(0.24, 0.70, in: size))
            path.addQuadCurve(to: p(0.72, 0.28, in: size), control: p(0.28, 0.24, in: size))
            path.addQuadCurve(to: p(0.24, 0.70, in: size), control: p(0.78, 0.74, in: size))
            path.move(to: p(0.26, 0.68, in: size))
            path.addLine(to: p(0.70, 0.31, in: size))
        case .fish:
            path.move(to: p(0.22, 0.50, in: size))
            path.addQuadCurve(to: p(0.72, 0.50, in: size), control: p(0.48, 0.18, in: size))
            path.addQuadCurve(to: p(0.22, 0.50, in: size), control: p(0.48, 0.82, in: size))
            path.move(to: p(0.72, 0.50, in: size))
            path.addLine(to: p(0.86, 0.32, in: size))
            path.addLine(to: p(0.86, 0.68, in: size))
            path.closeSubpath()
        case .constellation:
            let points = [(0.18, 0.62), (0.32, 0.34), (0.50, 0.55), (0.67, 0.25), (0.82, 0.58)]
            path.move(to: p(points[0].0, points[0].1, in: size))
            for point in points.dropFirst() {
                path.addLine(to: p(point.0, point.1, in: size))
            }
        }
        return path
    }

    private func accentPath(in size: CGSize) -> Path {
        var path = Path()
        switch kind {
        case .sailboat:
            path.move(to: p(0.50, 0.28, in: size))
            path.addLine(to: p(0.30, 0.57, in: size))
            path.addLine(to: p(0.50, 0.57, in: size))
        case .mountain:
            path.move(to: p(0.34, 0.42, in: size))
            path.addLine(to: p(0.40, 0.32, in: size))
            path.addLine(to: p(0.46, 0.42, in: size))
        case .leaf:
            path.move(to: p(0.38, 0.57, in: size))
            path.addLine(to: p(0.37, 0.43, in: size))
            path.move(to: p(0.50, 0.48, in: size))
            path.addLine(to: p(0.62, 0.49, in: size))
        case .fish:
            path.addEllipse(in: CGRect(x: size.width * 0.34, y: size.height * 0.42, width: 9, height: 9))
        case .constellation:
            for point in [(0.18, 0.62), (0.32, 0.34), (0.50, 0.55), (0.67, 0.25), (0.82, 0.58)] {
                path.addEllipse(in: CGRect(x: size.width * point.0 - 6, y: size.height * point.1 - 6, width: 12, height: 12))
            }
        }
        return path
    }
}

private struct CompletionView: View {
    let replay: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(BetweenPalette.lavender.opacity(0.26), lineWidth: 2)
                    .frame(width: 156, height: 156)
                Path { path in
                    path.move(to: CGPoint(x: 24, y: 88))
                    path.addCurve(
                        to: CGPoint(x: 132, y: 68),
                        control1: CGPoint(x: 54, y: 24),
                        control2: CGPoint(x: 96, y: 132)
                    )
                }
                .stroke(BetweenPalette.charcoal, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: 156, height: 156)
            }
            Text("Five shapes, one team.")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(BetweenPalette.charcoal)
            Text("You found every path between.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(BetweenPalette.charcoal.opacity(0.68))
            Button("Play again", action: replay)
                .buttonStyle(BetweenButtonStyle())
            Spacer()
        }
        .padding(32)
        .multilineTextAlignment(.center)
    }
}

#Preview("Phone") {
    RibbonGameView()
}

#Preview("iPad") {
    RibbonGameView()
        .frame(width: 820, height: 1080)
}
