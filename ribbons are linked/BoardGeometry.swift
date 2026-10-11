import SwiftUI

enum BoardGeometry {
    static let goalRadius: CGFloat = 0.075
    static let captureRadius: CGFloat = 0.055

    static func routePoints(
        puzzle: Puzzle,
        coral: NormalizedPoint,
        blue: NormalizedPoint,
        attachedCount: Int
    ) -> [NormalizedPoint] {
        let attached = puzzle.requiredPegIndices.prefix(attachedCount).map { puzzle.pegs[$0] }
        return [coral] + attached + [blue]
    }

    static func targetPoints(for puzzle: Puzzle) -> [NormalizedPoint] {
        [puzzle.coralGoal]
            + puzzle.requiredPegIndices.map { puzzle.pegs[$0] }
            + [puzzle.blueGoal]
    }

    static func path(points: [NormalizedPoint], in size: CGSize) -> Path {
        let resolved = points.map { $0.point(in: size) }
        var path = Path()
        guard let first = resolved.first else { return path }
        path.move(to: first)

        if resolved.count == 2, let last = resolved.last {
            path.addLine(to: last)
            return path
        }

        for index in 1..<resolved.count {
            let previous = resolved[index - 1]
            let current = resolved[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)

            if index == 1 {
                path.addLine(to: midpoint)
            } else {
                path.addQuadCurve(to: midpoint, control: previous)
            }

            if index == resolved.count - 1 {
                path.addQuadCurve(to: current, control: current)
            }
        }
        return path
    }

    static func normalizedDistance(_ a: NormalizedPoint, _ b: NormalizedPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    static func distanceFrom(_ point: CGPoint, toSegmentFrom start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(point.x - start.x, point.y - start.y) }
        let projection = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared))
        let nearest = CGPoint(x: start.x + projection * dx, y: start.y + projection * dy)
        return hypot(point.x - nearest.x, point.y - nearest.y)
    }

    static func routePasses(
        peg: NormalizedPoint,
        puzzle: Puzzle,
        coral: NormalizedPoint,
        blue: NormalizedPoint,
        attachedCount: Int
    ) -> Bool {
        let points = routePoints(puzzle: puzzle, coral: coral, blue: blue, attachedCount: attachedCount)
        guard points.count >= 2 else { return false }
        for index in 1..<points.count {
            let start = CGPoint(x: points[index - 1].x, y: points[index - 1].y)
            let end = CGPoint(x: points[index].x, y: points[index].y)
            let target = CGPoint(x: peg.x, y: peg.y)
            if distanceFrom(target, toSegmentFrom: start, to: end) <= captureRadius {
                return true
            }
        }
        return false
    }
}
