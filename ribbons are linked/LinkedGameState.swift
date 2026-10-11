import SwiftUI
import Observation
import UIKit

@MainActor
@Observable
final class LinkedGameState {
    private(set) var levelIndex: Int
    private(set) var configuration: LinkedConfiguration
    private(set) var history: [LinkedConfiguration] = []
    private(set) var preview: LinkedConfiguration?
    private(set) var previewIsValid = true
    private(set) var isSolved = false
    private(set) var hasCompletedGame = false
    private(set) var invalidFeedbackID = 0

    @ObservationIgnored
    @AppStorage("linkedHighestUnlockedLevel") private var storedHighestUnlockedLevel = 0

    var level: LinkedLevel { LinkedLevelLibrary.levels[levelIndex] }
    var canUndo: Bool { !history.isEmpty && !isSolved }
    var levelLabel: String { "\(levelIndex + 1) / \(LinkedLevelLibrary.levels.count)" }

    init() {
        let saved = min(
            UserDefaults.standard.integer(forKey: "linkedHighestUnlockedLevel"),
            LinkedLevelLibrary.levels.count - 1
        )
        levelIndex = saved
        configuration = LinkedLevelLibrary.levels[saved].start
    }

    func showPreview(_ move: LinkedMove) {
        guard !isSolved else { return }
        let destinations = LinkedRules.destination(for: move, from: configuration)
        preview = LinkedConfiguration(
            coral: destinations.coral,
            blue: destinations.blue,
            mode: configuration.mode
        )
        previewIsValid = LinkedRules.applying(move, to: configuration, level: level) != nil
    }

    func clearPreview() {
        preview = nil
        previewIsValid = true
    }

    func commit(_ move: LinkedMove) {
        guard !isSolved else { return }
        clearPreview()
        guard let next = LinkedRules.applying(move, to: configuration, level: level) else {
            invalidFeedbackID += 1
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        history.append(configuration)
        configuration = next
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if LinkedRules.isComplete(configuration, level: level) {
            isSolved = true
            storedHighestUnlockedLevel = max(
                storedHighestUnlockedLevel,
                min(levelIndex + 1, LinkedLevelLibrary.levels.count - 1)
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func undo() {
        guard let previous = history.popLast(), !isSolved else { return }
        configuration = previous
        clearPreview()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func reset() {
        configuration = level.start
        history.removeAll(keepingCapacity: true)
        clearPreview()
        isSolved = false
        hasCompletedGame = false
    }

    func next() {
        guard isSolved else { return }
        if levelIndex == LinkedLevelLibrary.levels.count - 1 {
            hasCompletedGame = true
            return
        }
        levelIndex += 1
        storedHighestUnlockedLevel = max(storedHighestUnlockedLevel, levelIndex)
        configuration = level.start
        history.removeAll(keepingCapacity: true)
        clearPreview()
        isSolved = false
    }

    func replay() {
        levelIndex = 0
        storedHighestUnlockedLevel = 0
        configuration = level.start
        history.removeAll(keepingCapacity: true)
        clearPreview()
        isSolved = false
        hasCompletedGame = false
    }

    func hint() -> LinkedMove? {
        LinkedSolver.solution(for: level, from: configuration)?.first
    }
}
