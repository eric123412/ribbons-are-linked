import SwiftUI
import UIKit

struct MultiTouchSurface: UIViewRepresentable {
    let coralPosition: NormalizedPoint
    let bluePosition: NormalizedPoint
    let enabled: Bool
    let onBegin: (Player) -> Void
    let onMove: (Player, NormalizedPoint) -> Void

    func makeUIView(context: Context) -> TouchTrackingView {
        let view = TouchTrackingView()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.onBegin = onBegin
        view.onMove = onMove
        return view
    }

    func updateUIView(_ view: TouchTrackingView, context: Context) {
        view.coralPosition = coralPosition
        view.bluePosition = bluePosition
        view.isInteractionEnabled = enabled
        view.onBegin = onBegin
        view.onMove = onMove
    }
}

final class TouchTrackingView: UIView {
    var coralPosition = NormalizedPoint(x: 0, y: 0)
    var bluePosition = NormalizedPoint(x: 1, y: 1)
    var isInteractionEnabled = true
    var onBegin: ((Player) -> Void)?
    var onMove: ((Player, NormalizedPoint) -> Void)?

    private var owners: [ObjectIdentifier: Player] = [:]
    private var claimedPlayers: Set<Player> = []

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInteractionEnabled else { return }
        for touch in touches {
            let location = touch.location(in: self)
            let candidates: [(Player, CGPoint)] = [
                (.coral, coralPosition.point(in: bounds.size)),
                (.blue, bluePosition.point(in: bounds.size))
            ]
            let available = candidates
                .filter { !claimedPlayers.contains($0.0) }
                .map { ($0.0, hypot(location.x - $0.1.x, location.y - $0.1.y)) }
                .filter { $0.1 <= 58 }
                .sorted { $0.1 < $1.1 }

            guard let player = available.first?.0 else { continue }
            owners[ObjectIdentifier(touch)] = player
            claimedPlayers.insert(player)
            onBegin?(player)
            update(touch, player: player)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInteractionEnabled else { return }
        for touch in touches {
            guard let player = owners[ObjectIdentifier(touch)] else { continue }
            update(touch, player: player)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        release(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        release(touches)
    }

    private func update(_ touch: UITouch, player: Player) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let location = touch.location(in: self)
        onMove?(
            player,
            NormalizedPoint(x: location.x / bounds.width, y: location.y / bounds.height)
        )
    }

    private func release(_ touches: Set<UITouch>) {
        for touch in touches {
            if let player = owners.removeValue(forKey: ObjectIdentifier(touch)) {
                claimedPlayers.remove(player)
            }
        }
    }
}
