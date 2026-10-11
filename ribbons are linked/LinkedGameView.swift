import SwiftUI

struct LinkedGameView: View {
    @State private var game = LinkedGameState()
    @State private var hintMove: LinkedMove?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            BetweenPalette.ivory
                .ignoresSafeArea()

            if game.hasCompletedGame {
                LinkedCompletionView(replay: game.replay)
                    .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    LinkedHeader(
                        levelLabel: game.levelLabel,
                        canUndo: game.canUndo,
                        undo: {
                            hintMove = nil
                            game.undo()
                        },
                        reset: {
                            hintMove = nil
                            game.reset()
                        },
                        hint: showHint
                    )

                    VStack(spacing: 3) {
                        Text(game.level.title)
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(BetweenPalette.charcoal)
                        Text(game.level.subtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(BetweenPalette.charcoal.opacity(0.68))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 22)

                    LinkModeBadge(mode: game.configuration.mode)

                    LinkedBoard(game: game, hintMove: hintMove) {
                        hintMove = nil
                    }
                    .frame(maxWidth: 610, maxHeight: 610)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 18)

                    if let hintMove {
                        Label(
                            "\(hintMove.player == .coral ? "Coral" : "Blue"): swipe \(hintMove.direction.rawValue)",
                            systemImage: hintMove.direction.symbolName
                        )
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(BetweenPalette.lavender)
                        .transition(.opacity)
                    } else {
                        Text("Swipe either dot one cell")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(BetweenPalette.charcoal.opacity(0.5))
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 10)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: game.hasCompletedGame)
        .preferredColorScheme(.light)
    }

    private func showHint() {
        hintMove = game.hint()
        if let hintMove {
            game.showPreview(hintMove)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

private struct LinkedHeader: View {
    let levelLabel: String
    let canUndo: Bool
    let undo: () -> Void
    let reset: () -> Void
    let hint: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("LINKED")
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
        .padding(.horizontal, 18)
    }
}

private struct LinkModeBadge: View {
    let mode: LinkMode

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: mode == .mirror ? "arrow.left.and.right" : "arrow.right")
            Text(mode.rawValue)
        }
        .font(.system(.caption, design: .rounded, weight: .bold))
        .foregroundStyle(BetweenPalette.charcoal.opacity(0.76))
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .background(BetweenPalette.lavender.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("\(mode.rawValue) link mode")
    }
}

private struct LinkedBoard: View {
    @Bindable var game: LinkedGameState
    let hintMove: LinkedMove?
    let didCommit: () -> Void
    @State private var pendingMove: LinkedMove?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let boardSide = min(proxy.size.width, proxy.size.height)
            let cellSide = boardSide / 5
            let origin = CGPoint(
                x: (proxy.size.width - boardSide) / 2,
                y: (proxy.size.height - boardSide) / 2
            )

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(game.invalidFeedbackID == 0 ? 0.30 : 0.34))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                BetweenPalette.charcoal.opacity(0.09),
                                lineWidth: game.invalidFeedbackID == 0 ? 1 : 2
                            )
                    }

                ForEach(0..<25, id: \.self) { index in
                    let point = GridPoint(index: index)
                    LinkedCell(
                        point: point,
                        level: game.level,
                        cellSide: cellSide
                    )
                    .position(center(for: point, cellSide: cellSide, origin: origin))
                }

                Path { path in
                    path.move(to: center(for: game.configuration.coral, cellSide: cellSide, origin: origin))
                    path.addLine(to: center(for: game.configuration.blue, cellSide: cellSide, origin: origin))
                }
                .stroke(
                    BetweenPalette.charcoal.opacity(0.36),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [3, 8])
                )
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: game.configuration)

                if let preview = game.preview {
                    PreviewDot(
                        player: .coral,
                        valid: game.previewIsValid,
                        size: cellSide * 0.52
                    )
                    .position(center(for: preview.coral, cellSide: cellSide, origin: origin))
                    PreviewDot(
                        player: .blue,
                        valid: game.previewIsValid,
                        size: cellSide * 0.52
                    )
                    .position(center(for: preview.blue, cellSide: cellSide, origin: origin))
                }

                LinkedPlayerDot(player: .coral, size: cellSide * 0.58)
                    .position(center(for: game.configuration.coral, cellSide: cellSide, origin: origin))
                    .gesture(moveGesture(for: .coral))
                    .accessibilityLabel("Coral player dot")
                LinkedPlayerDot(player: .blue, size: cellSide * 0.58)
                    .position(center(for: game.configuration.blue, cellSide: cellSide, origin: origin))
                    .gesture(moveGesture(for: .blue))
                    .accessibilityLabel("Blue player dot")

                if game.isSolved {
                    VStack(spacing: 10) {
                        Text("Completed")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(BetweenPalette.charcoal)
                        Button("Next", action: game.next)
                            .buttonStyle(BetweenButtonStyle())
                    }
                    .padding(22)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .transition(.opacity)
                }
            }
            .frame(width: boardSide, height: boardSide)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: game.configuration)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: game.isSolved)
        }
    }

    private func center(for point: GridPoint, cellSide: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(
            x: origin.x + (CGFloat(point.column) + 0.5) * cellSide,
            y: origin.y + (CGFloat(point.row) + 0.5) * cellSide
        )
    }

    private func moveGesture(for player: Player) -> some Gesture {
        DragGesture(minimumDistance: 7)
            .onChanged { value in
                guard !game.isSolved, let direction = direction(for: value.translation) else { return }
                let move = LinkedMove(player: player, direction: direction)
                guard move != pendingMove else { return }
                pendingMove = move
                game.showPreview(move)
            }
            .onEnded { value in
                defer {
                    pendingMove = nil
                    didCommit()
                }
                guard let direction = direction(for: value.translation) else {
                    game.clearPreview()
                    return
                }
                game.commit(LinkedMove(player: player, direction: direction))
            }
    }

    private func direction(for translation: CGSize) -> MoveDirection? {
        guard max(abs(translation.width), abs(translation.height)) >= 7 else { return nil }
        if abs(translation.width) > abs(translation.height) {
            return translation.width > 0 ? .right : .left
        }
        return translation.height > 0 ? .down : .up
    }
}

private struct LinkedCell: View {
    let point: GridPoint
    let level: LinkedLevel
    let cellSide: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cellSide * 0.12, style: .continuous)
                .stroke(BetweenPalette.charcoal.opacity(0.08), lineWidth: 1)
                .padding(3)

            if level.walls.contains(point) {
                RoundedRectangle(cornerRadius: cellSide * 0.13, style: .continuous)
                    .fill(BetweenPalette.charcoal.opacity(0.86))
                    .padding(cellSide * 0.08)
                    .overlay {
                        Path { path in
                            path.move(to: CGPoint(x: cellSide * 0.25, y: cellSide * 0.50))
                            path.addLine(to: CGPoint(x: cellSide * 0.75, y: cellSide * 0.50))
                        }
                        .stroke(BetweenPalette.ivory.opacity(0.22), lineWidth: 2)
                    }
                    .accessibilityLabel("Wall")
            } else {
                if point == level.coralGoal {
                    LinkedGoal(player: .coral, size: cellSide * 0.62)
                }
                if point == level.blueGoal {
                    LinkedGoal(player: .blue, size: cellSide * 0.62)
                }
                if level.switches.contains(point) {
                    ZStack {
                        Circle()
                            .fill(BetweenPalette.lavender.opacity(0.14))
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .font(.system(size: max(13, cellSide * 0.23), weight: .semibold))
                            .foregroundStyle(BetweenPalette.lavender)
                    }
                    .frame(width: cellSide * 0.50, height: cellSide * 0.50)
                    .accessibilityLabel("Link mode switch")
                }
            }
        }
        .frame(width: cellSide, height: cellSide)
    }
}

private struct LinkedGoal: View {
    let player: Player
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.08))
            Circle()
                .stroke(color.opacity(0.48), style: StrokeStyle(lineWidth: 2, dash: [3, 4]))
            if player == .coral {
                Circle()
                    .stroke(color.opacity(0.65), lineWidth: 2)
                    .padding(size * 0.35)
            } else {
                Diamond()
                    .stroke(color.opacity(0.65), lineWidth: 2)
                    .padding(size * 0.34)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(player == .coral ? "Coral goal" : "Blue goal")
    }

    private var color: Color {
        player == .coral ? BetweenPalette.coral : BetweenPalette.blue
    }
}

private struct LinkedPlayerDot: View {
    let player: Player
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(player == .coral ? BetweenPalette.coral : BetweenPalette.blue)
                .shadow(color: color.opacity(0.22), radius: 5, y: 2)
            if player == .coral {
                Circle()
                    .stroke(Color.white.opacity(0.96), lineWidth: 2.5)
                    .padding(size * 0.34)
            } else {
                Diamond()
                    .stroke(Color.white.opacity(0.96), lineWidth: 2.5)
                    .padding(size * 0.32)
            }
        }
        .frame(width: max(44, size), height: max(44, size))
        .contentShape(Circle())
    }

    private var color: Color {
        player == .coral ? BetweenPalette.coral : BetweenPalette.blue
    }
}

private struct PreviewDot: View {
    let player: Player
    let valid: Bool
    let size: CGFloat

    var body: some View {
        Circle()
            .stroke(
                valid
                    ? (player == .coral ? BetweenPalette.coral : BetweenPalette.blue).opacity(0.55)
                    : Color.red.opacity(0.58),
                style: StrokeStyle(lineWidth: 3, dash: [3, 4])
            )
            .frame(width: max(38, size), height: max(38, size))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct LinkedCompletionView: View {
    let replay: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "link")
                .font(.system(size: 58, weight: .medium))
                .foregroundStyle(BetweenPalette.lavender)
                .frame(width: 138, height: 138)
                .background(BetweenPalette.lavender.opacity(0.10))
                .clipShape(Circle())
            Text("Completed")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(BetweenPalette.charcoal)
            Text("Eight puzzles, solved together.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(BetweenPalette.charcoal.opacity(0.65))
            Button("Play again", action: replay)
                .buttonStyle(BetweenButtonStyle())
            Spacer()
        }
        .padding(32)
    }
}
