import Foundation

struct GridPoint: Hashable, Sendable {
    let row: Int
    let column: Int

    nonisolated init(_ row: Int, _ column: Int) {
        self.row = row
        self.column = column
    }

    nonisolated init(index: Int) {
        row = index / 5
        column = index % 5
    }

    var index: Int { row * 5 + column }

    func moved(_ direction: MoveDirection) -> GridPoint {
        GridPoint(row + direction.rowDelta, column + direction.columnDelta)
    }

    var isOnBoard: Bool {
        (0..<5).contains(row) && (0..<5).contains(column)
    }
}

enum LinkMode: String, Hashable, Sendable {
    case mirror = "Mirror"
    case parallel = "Parallel"

    var toggled: LinkMode {
        self == .mirror ? .parallel : .mirror
    }
}

enum MoveDirection: String, CaseIterable, Hashable, Sendable {
    case up, down, left, right

    var rowDelta: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }

    var columnDelta: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    var opposite: MoveDirection {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }

    var symbolName: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        }
    }
}

struct LinkedMove: Hashable, Sendable {
    let player: Player
    let direction: MoveDirection
}

struct LinkedConfiguration: Hashable, Sendable {
    let coral: GridPoint
    let blue: GridPoint
    let mode: LinkMode
}

struct LinkedLevel: Identifiable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let start: LinkedConfiguration
    let coralGoal: GridPoint
    let blueGoal: GridPoint
    let walls: Set<GridPoint>
    let switches: Set<GridPoint>
}

enum LinkedRules {
    static func destination(
        for move: LinkedMove,
        from configuration: LinkedConfiguration
    ) -> (coral: GridPoint, blue: GridPoint) {
        let linkedDirection = configuration.mode == .parallel ? move.direction : move.direction.opposite
        switch move.player {
        case .coral:
            return (
                configuration.coral.moved(move.direction),
                configuration.blue.moved(linkedDirection)
            )
        case .blue:
            return (
                configuration.coral.moved(linkedDirection),
                configuration.blue.moved(move.direction)
            )
        }
    }

    static func applying(
        _ move: LinkedMove,
        to configuration: LinkedConfiguration,
        level: LinkedLevel
    ) -> LinkedConfiguration? {
        let destination = destination(for: move, from: configuration)
        guard destination.coral.isOnBoard,
              destination.blue.isOnBoard,
              !level.walls.contains(destination.coral),
              !level.walls.contains(destination.blue),
              destination.coral != destination.blue,
              !(destination.coral == configuration.blue && destination.blue == configuration.coral)
        else {
            return nil
        }

        let coralEnteredSwitch = destination.coral != configuration.coral
            && level.switches.contains(destination.coral)
        let blueEnteredSwitch = destination.blue != configuration.blue
            && level.switches.contains(destination.blue)
        let toggleCount = (coralEnteredSwitch ? 1 : 0) + (blueEnteredSwitch ? 1 : 0)
        let nextMode = toggleCount == 1 ? configuration.mode.toggled : configuration.mode

        return LinkedConfiguration(
            coral: destination.coral,
            blue: destination.blue,
            mode: nextMode
        )
    }

    static func isComplete(_ configuration: LinkedConfiguration, level: LinkedLevel) -> Bool {
        configuration.coral == level.coralGoal && configuration.blue == level.blueGoal
    }
}

enum LinkedSolver {
    private struct SearchNode {
        let configuration: LinkedConfiguration
        let path: [LinkedMove]
    }

    static func solution(
        for level: LinkedLevel,
        from start: LinkedConfiguration? = nil
    ) -> [LinkedMove]? {
        let initial = start ?? level.start
        var queue = [SearchNode(configuration: initial, path: [])]
        var visited: Set<LinkedConfiguration> = [initial]
        var head = 0

        while head < queue.count {
            let node = queue[head]
            head += 1

            if LinkedRules.isComplete(node.configuration, level: level) {
                return node.path
            }

            for player in [Player.coral, .blue] {
                for direction in MoveDirection.allCases {
                    let move = LinkedMove(player: player, direction: direction)
                    guard let next = LinkedRules.applying(move, to: node.configuration, level: level),
                          visited.insert(next).inserted
                    else {
                        continue
                    }
                    queue.append(SearchNode(configuration: next, path: node.path + [move]))
                }
            }
        }
        return nil
    }
}

enum LinkedLevelLibrary {
    static let levels: [LinkedLevel] = [
        level(0, "Together", "Parallel steps move as one.", 2, 22, 4, 24, .parallel),
        level(1, "Give and take", "Mirror sends your partner the other way.", 11, 23, 24, 10, .mirror),
        level(2, "The detour", "A clear-looking route is not always the right one.", 2, 14, 10, 22, .parallel, [17, 13, 24, 4]),
        level(3, "Passing places", "Plan around each other without swapping.", 1, 22, 18, 5, .mirror, [17, 16, 0, 9, 23]),
        level(4, "Change of mind", "A switch changes the link after the step.", 6, 23, 21, 8, .mirror, [7, 11, 0], [14]),
        level(5, "Double back", "Goals do not hold you. Sometimes leave and return.", 11, 19, 23, 15, .parallel, [16, 5, 0, 21, 1], [3, 6]),
        level(6, "Counterpoint", "Use both link modes to thread the walls.", 23, 6, 15, 14, .mirror, [4, 1, 8, 19, 20, 5, 3], [13, 15]),
        level(7, "Linked", "Everything you learned, in concert.", 18, 2, 13, 15, .parallel, [24, 0, 11, 17, 16, 10, 1, 9], [6, 8, 19])
    ]

    static var validationReport: [Int: Int] {
        Dictionary(uniqueKeysWithValues: levels.map { level in
            (level.id, LinkedSolver.solution(for: level)?.count ?? -1)
        })
    }

    private static func level(
        _ id: Int,
        _ title: String,
        _ subtitle: String,
        _ coral: Int,
        _ blue: Int,
        _ coralGoal: Int,
        _ blueGoal: Int,
        _ mode: LinkMode,
        _ walls: [Int] = [],
        _ switches: [Int] = []
    ) -> LinkedLevel {
        LinkedLevel(
            id: id,
            title: title,
            subtitle: subtitle,
            start: LinkedConfiguration(
                coral: GridPoint(index: coral),
                blue: GridPoint(index: blue),
                mode: mode
            ),
            coralGoal: GridPoint(index: coralGoal),
            blueGoal: GridPoint(index: blueGoal),
            walls: Set(walls.map(GridPoint.init(index:))),
            switches: Set(switches.map(GridPoint.init(index:)))
        )
    }
}
