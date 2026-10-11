import SwiftUI
import Observation
import UIKit

@MainActor
@Observable
final class GameState {
    private(set) var levelIndex: Int
    private(set) var coralPosition: NormalizedPoint
    private(set) var bluePosition: NormalizedPoint
    private(set) var attachedCount = 0
    private(set) var isSolved = false
    private(set) var hasCompletedGame = false
    private(set) var didRestartForWrongOrder = false
    private var feedbackTask: Task<Void, Never>?

    @ObservationIgnored
    @AppStorage("ribbonHighestUnlockedLevel") private var storedHighestUnlockedLevel = 0

    var puzzle: Puzzle { PuzzleLibrary.puzzle(at: levelIndex) }
    var canUndo: Bool { attachedCount > 0 && !isSolved }
    var levelLabel: String { "\(levelIndex + 1)" }

    init() {
        let saved = max(0, UserDefaults.standard.integer(forKey: "ribbonHighestUnlockedLevel"))
        levelIndex = saved
        let initial = PuzzleLibrary.puzzle(at: saved)
        coralPosition = initial.startCoral
        bluePosition = initial.startBlue
    }

    func beginDrag(player: Player) {
        guard !isSolved else { return }
    }

    func move(player: Player, to position: NormalizedPoint) {
        guard !isSolved else { return }
        let clamped = NormalizedPoint(
            x: min(max(position.x, 0.06), 0.94),
            y: min(max(position.y, 0.06), 0.94)
        )
        switch player {
        case .coral:
            coralPosition = clamped
        case .blue:
            bluePosition = clamped
        }

        processRibbonCrossings()
        checkCompletion()
    }

    func undo() {
        guard canUndo else { return }
        attachedCount -= 1
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func reset() {
        feedbackTask?.cancel()
        let current = puzzle
        coralPosition = current.startCoral
        bluePosition = current.startBlue
        attachedCount = 0
        isSolved = false
        hasCompletedGame = false
        didRestartForWrongOrder = false
    }

    func next() {
        guard isSolved else { return }
        levelIndex += 1
        storedHighestUnlockedLevel = max(storedHighestUnlockedLevel, levelIndex)
        reset()
    }

    func replay() {
        levelIndex = 0
        storedHighestUnlockedLevel = 0
        reset()
    }

    private func processRibbonCrossings() {
        while attachedCount < puzzle.requiredPegIndices.count {
            let remainingIndices = Array(puzzle.requiredPegIndices.dropFirst(attachedCount))
            guard let expectedIndex = remainingIndices.first else { break }

            let expectedIsCrossed = BoardGeometry.routePasses(
                peg: puzzle.pegs[expectedIndex],
                puzzle: puzzle,
                coral: coralPosition,
                blue: bluePosition,
                attachedCount: attachedCount
            )
            let laterPegIsCrossed = remainingIndices.dropFirst().contains { index in
                BoardGeometry.routePasses(
                    peg: puzzle.pegs[index],
                    puzzle: puzzle,
                    coral: coralPosition,
                    blue: bluePosition,
                    attachedCount: attachedCount
                )
            }

            if laterPegIsCrossed && !expectedIsCrossed {
                break
            }
            guard expectedIsCrossed else { break }

            attachedCount += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func restartForWrongPeg() {
        feedbackTask?.cancel()
        let current = puzzle
        coralPosition = current.startCoral
        bluePosition = current.startBlue
        attachedCount = 0
        isSolved = false
        didRestartForWrongOrder = true
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        feedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            self?.didRestartForWrongOrder = false
        }
    }

    private func checkCompletion() {
        let coralAtGoal = BoardGeometry.normalizedDistance(coralPosition, puzzle.coralGoal) <= BoardGeometry.goalRadius
        let blueAtGoal = BoardGeometry.normalizedDistance(bluePosition, puzzle.blueGoal) <= BoardGeometry.goalRadius
        guard coralAtGoal && blueAtGoal else { return }

        guard attachedCount == puzzle.requiredPegIndices.count else {
            restartForWrongPeg()
            return
        }

        isSolved = true
        storedHighestUnlockedLevel = max(storedHighestUnlockedLevel, levelIndex + 1)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

enum Player: Hashable {
    case coral, blue
}
