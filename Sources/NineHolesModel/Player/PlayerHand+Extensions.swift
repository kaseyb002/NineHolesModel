import Foundation

extension PlayerHand {
    public mutating func revealAll() {
        for slot in BoardSlot.allCases {
            slots[slot]?.isFaceUp = true
        }
    }

    public func visibleValue(
        at slot: BoardSlot,
        cardsMap: [CardID: Card]
    ) -> CardValue? {
        guard let boardCard: BoardCard = slots[slot],
              boardCard.isFaceUp
        else {
            return nil
        }
        return cardsMap[boardCard.cardID]?.value
    }

    public func strokeScore(cardsMap: [CardID: Card]) -> Int {
        score(cardsMap: cardsMap, includeFaceDown: true)
    }

    public func visibleStrokeScore(cardsMap: [CardID: Card]) -> Int {
        score(cardsMap: cardsMap, includeFaceDown: false)
    }

    private func score(
        cardsMap: [CardID: Card],
        includeFaceDown: Bool
    ) -> Int {
        func value(at slot: BoardSlot) -> CardValue? {
            if includeFaceDown == false {
                return visibleValue(at: slot, cardsMap: cardsMap)
            }
            guard let cardID: CardID = slots[slot]?.cardID else {
                return nil
            }
            return cardsMap[cardID]?.value
        }

        func matchingValue(column: BoardColumn) -> CardValue? {
            let topSlot: BoardSlot = .slot(row: .top, column: column)
            let bottomSlot: BoardSlot = .slot(row: .bottom, column: column)
            guard let topValue: CardValue = value(at: topSlot),
                  let bottomValue: CardValue = value(at: bottomSlot),
                  topValue == bottomValue
            else {
                return nil
            }
            return topValue
        }

        func unmatchedColumnScore(column: BoardColumn) -> Int {
            let topSlot: BoardSlot = .slot(row: .top, column: column)
            let bottomSlot: BoardSlot = .slot(row: .bottom, column: column)
            let topStrokes: Int = value(at: topSlot)?.strokeValue ?? 0
            let bottomStrokes: Int = value(at: bottomSlot)?.strokeValue ?? 0
            return topStrokes + bottomStrokes
        }

        func scoreForMatchingRun(
            value: CardValue,
            columnCount: Int
        ) -> Int {
            if value.isHoleInOne {
                let cardCount: Int = columnCount * 2
                let cardStrokes: Int = cardCount * value.strokeValue
                let bonus: Int = columnCount == 2 ? -10 : 0
                return cardStrokes + bonus
            }

            switch columnCount {
            case 1: return 0
            case 2: return -10
            case 3: return -15
            case 4: return -20
            default: return 0
            }
        }

        var score: Int = 0
        var columnIndex: Int = 0
        let columns: [BoardColumn] = BoardColumn.allCases

        while columnIndex < columns.count {
            let column: BoardColumn = columns[columnIndex]
            if let runValue: CardValue = matchingValue(column: column) {
                var runLength: Int = 1
                while columnIndex + runLength < columns.count,
                      matchingValue(column: columns[columnIndex + runLength]) == runValue
                {
                    runLength += 1
                }
                score += scoreForMatchingRun(
                    value: runValue,
                    columnCount: runLength
                )
                columnIndex += runLength
            } else {
                score += unmatchedColumnScore(column: column)
                columnIndex += 1
            }
        }

        return score
    }
}
