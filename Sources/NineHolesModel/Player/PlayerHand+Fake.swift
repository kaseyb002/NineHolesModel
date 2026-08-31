import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        slots: [BoardSlot: BoardCard]? = nil
    ) -> PlayerHand {
        if let slots {
            return .init(
                player: player,
                slots: slots
            )
        }

        var generatedSlots: [BoardSlot: BoardCard] = [:]
        for (index, slot) in BoardSlot.allCases.enumerated() {
            let card: Card = .fake(
                id: index,
                value: CardValue.allCases[index % CardValue.allCases.count]
            )
            generatedSlots[slot] = BoardCard(
                cardID: card.id,
                isFaceUp: false
            )
        }
        return .init(
            player: player,
            slots: generatedSlots
        )
    }

    public static func fakeFaceUp(
        player: Player = .fake(),
        values: [BoardSlot: CardValue]
    ) -> (hand: PlayerHand, cardsMap: [CardID: Card]) {
        var slots: [BoardSlot: BoardCard] = [:]
        var cardsMap: [CardID: Card] = [:]
        for (index, slot) in BoardSlot.allCases.enumerated() {
            let value: CardValue = values[slot] ?? .twelve
            let card: Card = .init(
                id: index,
                value: value
            )
            cardsMap[card.id] = card
            slots[slot] = BoardCard(
                cardID: card.id,
                isFaceUp: true
            )
        }
        let hand: PlayerHand = .init(
            player: player,
            slots: slots
        )
        return (hand, cardsMap)
    }
}
