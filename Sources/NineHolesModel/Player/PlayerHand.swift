import Foundation

public struct PlayerHand: Equatable, Codable, Sendable {
    public var player: Player
    public var slots: [BoardSlot: BoardCard]

    public init(
        player: Player,
        slots: [BoardSlot: BoardCard]
    ) {
        self.player = player
        self.slots = slots
    }

    public var isPuttedOut: Bool {
        faceDownCount == 0
    }

    public var faceDownCount: Int {
        slots.values.filter { boardCard in
            boardCard.isFaceUp == false
        }.count
    }

    public var faceUpCount: Int {
        slots.values.filter { boardCard in
            boardCard.isFaceUp
        }.count
    }

    public var faceDownSlots: [BoardSlot] {
        BoardSlot.allCases.filter { slot in
            slots[slot]?.isFaceUp == false
        }
    }

    public var faceUpSlots: [BoardSlot] {
        BoardSlot.allCases.filter { slot in
            slots[slot]?.isFaceUp == true
        }
    }
}
