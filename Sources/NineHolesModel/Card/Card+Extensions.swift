import Foundation

extension [Card] {
    public static let holeInOneCount: Int = 4
    public static let copiesPerStandardValue: Int = 8

    public static func deck() -> [Card] {
        var cards: [Card] = []
        for value in CardValue.allCases {
            let copies: Int = value == .holeInOne
                ? holeInOneCount
                : copiesPerStandardValue
            for _ in 0 ..< copies {
                cards.append(
                    Card(
                        id: 0,
                        value: value
                    )
                )
            }
        }
        let shuffledIDs: [Int] = (0 ..< cards.count).shuffled()
        return zip(cards, shuffledIDs).map { card, cardID in
            Card(
                id: cardID,
                value: card.value
            )
        }
    }

    public static func cookedDeck(
        values: [CardValue]
    ) -> [Card] {
        values.enumerated().map { index, value in
            Card(
                id: index,
                value: value
            )
        }
    }
}

extension [CardID: Card] {
    public func findCards(byIDs cardIDs: [CardID]) -> [Card] {
        cardIDs.compactMap { cardID in self[cardID] }
    }
}
