import CoreGraphics

struct NormalizedPoint: Hashable, Sendable {
    let x: CGFloat
    let y: CGFloat

    func point(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

struct Puzzle: Identifiable, Sendable {
    let id: Int
    let title: String
    let startCoral: NormalizedPoint
    let startBlue: NormalizedPoint
    let pegs: [NormalizedPoint]
    let requiredPegIndices: [Int]
    let coralGoal: NormalizedPoint
    let blueGoal: NormalizedPoint
    let illustration: IllustrationKind
}

enum IllustrationKind: CaseIterable, Sendable {
    case sailboat, mountain, leaf, fish, constellation
}

enum PuzzleLibrary {
    static let puzzles: [Puzzle] = [
        Puzzle(
            id: 0,
            title: "First bend",
            startCoral: .init(x: 0.16, y: 0.74),
            startBlue: .init(x: 0.84, y: 0.74),
            pegs: [.init(x: 0.50, y: 0.43)],
            requiredPegIndices: [0],
            coralGoal: .init(x: 0.24, y: 0.24),
            blueGoal: .init(x: 0.76, y: 0.24),
            illustration: .sailboat
        ),
        Puzzle(
            id: 1,
            title: "Two turns",
            startCoral: .init(x: 0.16, y: 0.22),
            startBlue: .init(x: 0.84, y: 0.78),
            pegs: [.init(x: 0.38, y: 0.38), .init(x: 0.62, y: 0.62)],
            requiredPegIndices: [0, 1],
            coralGoal: .init(x: 0.18, y: 0.78),
            blueGoal: .init(x: 0.82, y: 0.22),
            illustration: .mountain
        ),
        Puzzle(
            id: 2,
            title: "Around the stem",
            startCoral: .init(x: 0.16, y: 0.50),
            startBlue: .init(x: 0.84, y: 0.50),
            pegs: [.init(x: 0.38, y: 0.30), .init(x: 0.62, y: 0.50), .init(x: 0.38, y: 0.70)],
            requiredPegIndices: [0, 1, 2],
            coralGoal: .init(x: 0.22, y: 0.82),
            blueGoal: .init(x: 0.78, y: 0.18),
            illustration: .leaf
        ),
        Puzzle(
            id: 3,
            title: "A wide loop",
            startCoral: .init(x: 0.18, y: 0.80),
            startBlue: .init(x: 0.82, y: 0.80),
            pegs: [.init(x: 0.28, y: 0.46), .init(x: 0.50, y: 0.25), .init(x: 0.72, y: 0.46)],
            requiredPegIndices: [0, 1, 2],
            coralGoal: .init(x: 0.17, y: 0.22),
            blueGoal: .init(x: 0.83, y: 0.22),
            illustration: .fish
        ),
        Puzzle(
            id: 4,
            title: "Between us",
            startCoral: .init(x: 0.14, y: 0.78),
            startBlue: .init(x: 0.86, y: 0.78),
            pegs: [
                .init(x: 0.25, y: 0.42),
                .init(x: 0.50, y: 0.20),
                .init(x: 0.75, y: 0.42),
                .init(x: 0.62, y: 0.68)
            ],
            requiredPegIndices: [0, 1, 2, 3],
            coralGoal: .init(x: 0.20, y: 0.18),
            blueGoal: .init(x: 0.80, y: 0.18),
            illustration: .constellation
        )
    ]

    static func puzzle(at index: Int) -> Puzzle {
        if index < puzzles.count {
            return puzzles[index]
        }
        return generatedPuzzle(number: index)
    }

    private static func generatedPuzzle(number: Int) -> Puzzle {
        var generator = SeededGenerator(seed: UInt64(number + 1) &* 0x9E3779B97F4A7C15)
        let pegCount = 2 + Int(generator.next() % 3)
        var pegs: [NormalizedPoint] = []
        let columns: [CGFloat] = [0.28, 0.40, 0.50, 0.62, 0.74]
        let rows: [CGFloat] = [0.25, 0.38, 0.50, 0.63, 0.75]

        while pegs.count < pegCount {
            let point = NormalizedPoint(
                x: columns[Int(generator.next() % UInt64(columns.count))],
                y: rows[Int(generator.next() % UInt64(rows.count))]
            )
            if !pegs.contains(point) {
                pegs.append(point)
            }
        }

        let flip = generator.next().isMultiple(of: 2)
        let coralGoal = NormalizedPoint(x: flip ? 0.20 : 0.80, y: 0.18)
        let blueGoal = NormalizedPoint(x: flip ? 0.80 : 0.20, y: 0.18)
        return Puzzle(
            id: number,
            title: "New path \(number - puzzles.count + 1)",
            startCoral: .init(x: 0.16, y: 0.80),
            startBlue: .init(x: 0.84, y: 0.80),
            pegs: pegs,
            requiredPegIndices: Array(pegs.indices),
            coralGoal: coralGoal,
            blueGoal: blueGoal,
            illustration: IllustrationKind.allCases[number % IllustrationKind.allCases.count]
        )
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

