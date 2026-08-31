import Foundation

public enum AIDifficulty: String, Equatable, Codable, Sendable, CaseIterable {
    case easy
    case medium
    case hard

    public var displayableName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

public struct AIEngine: Equatable, Codable, Sendable {
    public let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }

    public func makeMove(in round: Round, for playerID: PlayerID) -> Round {
        var updatedRound: Round = round

        do {
            switch round.state {
            case .waitingForPlayerToTeeOff(let currentPlayerID):
                guard currentPlayerID == playerID else { return round }
                guard let slot: BoardSlot = selectTeeOffSlot(in: round, for: playerID) else {
                    return round
                }
                try updatedRound.teeOff(slot: slot)

            case .waitingForPlayerToAct(let currentPlayerID, .needsToDraw):
                guard currentPlayerID == playerID else { return round }
                let fromDiscardPile: Bool = shouldDrawFromDiscard(in: round, for: playerID)
                try updatedRound.draw(fromDiscardPile: fromDiscardPile)

            case .waitingForPlayerToAct(let currentPlayerID, .needsToPlay):
                guard currentPlayerID == playerID else { return round }
                try performPlay(in: &updatedRound, for: playerID)

            case .waitingForPlayerToAct(let currentPlayerID, .needsToFlip):
                guard currentPlayerID == playerID else { return round }
                try performFlip(in: &updatedRound, for: playerID)

            case .roundComplete, .gameComplete:
                return round
            }
        } catch {
            return fallbackMove(in: round, for: playerID)
        }

        return updatedRound
    }

    // MARK: - Tee Off

    private func selectTeeOffSlot(
        in round: Round,
        for playerID: PlayerID
    ) -> BoardSlot? {
        round.playerHands
            .first { playerHand in playerHand.player.id == playerID }?
            .faceDownSlots
            .shuffled()
            .first
    }

    // MARK: - Draw

    private func shouldDrawFromDiscard(
        in round: Round,
        for playerID: PlayerID
    ) -> Bool {
        guard let discardCard: Card = round.topDiscardCard,
              let playerHand: PlayerHand = round.playerHands.first(where: { playerHand in
                  playerHand.player.id == playerID
              })
        else {
            return false
        }

        let discardValue: CardValue = discardCard.value
        let makesMatch: Bool = BoardColumn.allCases.contains { column in
            let top: BoardSlot = .slot(row: .top, column: column)
            let bottom: BoardSlot = .slot(row: .bottom, column: column)
            let topValue: CardValue? = playerHand.visibleValue(at: top, cardsMap: round.cardsMap)
            let bottomValue: CardValue? = playerHand.visibleValue(at: bottom, cardsMap: round.cardsMap)
            return topValue == discardValue || bottomValue == discardValue
        }
        let highestVisible: Int = highestVisibleStroke(
            in: playerHand,
            cardsMap: round.cardsMap
        )

        switch difficulty {
        case .easy:
            if playerHand.faceDownCount > 0 {
                return discardValue.strokeValue <= 2
            }
            return discardValue.strokeValue <= 3 || Bool.random()

        case .medium:
            if playerHand.faceDownCount > 0 {
                return makesMatch || discardValue.strokeValue <= 3
            }
            return makesMatch || discardValue.strokeValue < min(8, highestVisible)

        case .hard:
            if playerHand.faceDownCount > 0 {
                return makesMatch || discardValue.strokeValue <= 2
            }
            return makesMatch || discardValue.strokeValue <= 4 || discardValue.strokeValue < highestVisible - 2
        }
    }

    // MARK: - Play

    private enum PlayChoice {
        case replace(BoardSlot)
        case flip
        case skip
    }

    private func performPlay(
        in round: inout Round,
        for playerID: PlayerID
    ) throws {
        guard case .waitingForPlayerToAct(_, .needsToPlay(let drawnCardID, let fromDiscardPile)) = round.state,
              let playerHand: PlayerHand = round.playerHands.first(where: { playerHand in
                  playerHand.player.id == playerID
              }),
              let drawnCard: Card = round.cardsMap[drawnCardID]
        else {
            throw NineHolesError.notWaitingForPlayerToPlay
        }

        let choice: PlayChoice = choosePlay(
            drawnCard: drawnCard,
            fromDiscardPile: fromDiscardPile,
            playerHand: playerHand,
            cardsMap: round.cardsMap
        )

        switch choice {
        case .replace(let slot):
            try round.replaceCard(at: slot)

        case .flip:
            try round.discardDrawnCard()

        case .skip:
            try round.skip()
        }
    }

    private func performFlip(
        in round: inout Round,
        for playerID: PlayerID
    ) throws {
        guard let playerHand: PlayerHand = round.playerHands.first(where: { playerHand in
            playerHand.player.id == playerID
        }) else {
            throw NineHolesError.playerNotFound
        }

        if playerHand.faceDownCount == 1 {
            let skipScore: Int = scoreSkip(playerHand: playerHand, cardsMap: round.cardsMap)
            if skipScore > 5 {
                try round.skip()
                return
            }
        }

        guard let slot: BoardSlot = playerHand.faceDownSlots.shuffled().first else {
            throw NineHolesError.cannotDiscardDrawnCard
        }
        try round.flip(slot: slot)
    }

    private func choosePlay(
        drawnCard: Card,
        fromDiscardPile: Bool,
        playerHand: PlayerHand,
        cardsMap: [CardID: Card]
    ) -> PlayChoice {
        var choices: [(PlayChoice, Int)] = []

        for slot in BoardSlot.allCases {
            let score: Int = scoreReplace(
                slot: slot,
                drawnCard: drawnCard,
                playerHand: playerHand,
                cardsMap: cardsMap
            )
            choices.append((.replace(slot), score))
        }

        if fromDiscardPile == false, playerHand.faceDownCount > 0 {
            choices.append((.flip, scoreFlip(drawnCard: drawnCard)))
        }

        if playerHand.faceDownCount == 1 {
            choices.append((.skip, scoreSkip(playerHand: playerHand, cardsMap: cardsMap)))
        }

        switch difficulty {
        case .easy:
            if drawnCard.strokeValue <= 2,
               let bestReplace: BoardSlot = playerHand.faceUpSlots.max(by: { lhs, rhs in
                   (playerHand.visibleValue(at: lhs, cardsMap: cardsMap)?.strokeValue ?? 0)
                       < (playerHand.visibleValue(at: rhs, cardsMap: cardsMap)?.strokeValue ?? 0)
               })
            {
                return .replace(bestReplace)
            }
            return choices.randomElement()?.0 ?? .replace(.top1)

        case .medium, .hard:
            return choices.max { lhs, rhs in
                lhs.1 < rhs.1
            }?.0 ?? .replace(.top1)
        }
    }

    private func scoreReplace(
        slot: BoardSlot,
        drawnCard: Card,
        playerHand: PlayerHand,
        cardsMap: [CardID: Card]
    ) -> Int {
        var score: Int = 0
        let partnerValue: CardValue? = playerHand.visibleValue(
            at: slot.partner,
            cardsMap: cardsMap
        )
        let slotValue: CardValue? = playerHand.visibleValue(
            at: slot,
            cardsMap: cardsMap
        )

        if partnerValue == drawnCard.value {
            if drawnCard.value.isHoleInOne {
                score += 12
            } else {
                score += 30
            }
            if slotValue == partnerValue {
                score -= 40
            }
        }

        if let slotValue {
            score += slotValue.strokeValue - drawnCard.strokeValue
            if slotValue == partnerValue && drawnCard.value != slotValue {
                score -= 25
            }
        } else {
            score += 5 - drawnCard.strokeValue
        }

        return score
    }

    private func scoreFlip(drawnCard: Card) -> Int {
        drawnCard.strokeValue - 2
    }

    private func scoreSkip(
        playerHand: PlayerHand,
        cardsMap: [CardID: Card]
    ) -> Int {
        let visibleStrokes: Int = playerHand.faceUpSlots.reduce(0) { total, slot in
            total + (playerHand.visibleValue(at: slot, cardsMap: cardsMap)?.strokeValue ?? 0)
        }
        switch difficulty {
        case .easy:
            return -5
        case .medium:
            return visibleStrokes >= 18 ? 10 : 0
        case .hard:
            return visibleStrokes >= 12 ? 16 : 2
        }
    }

    private func highestVisibleStroke(
        in playerHand: PlayerHand,
        cardsMap: [CardID: Card]
    ) -> Int {
        playerHand.faceUpSlots.compactMap { slot in
            playerHand.visibleValue(at: slot, cardsMap: cardsMap)?.strokeValue
        }.max() ?? 12
    }

    private func fallbackMove(in round: Round, for playerID: PlayerID) -> Round {
        var updatedRound: Round = round
        do {
            switch round.state {
            case .waitingForPlayerToTeeOff:
                if let slot: BoardSlot = updatedRound.currentPlayerHand?.faceDownSlots.first {
                    try updatedRound.teeOff(slot: slot)
                }

            case .waitingForPlayerToAct(_, .needsToDraw):
                if round.deck.isEmpty == false {
                    try updatedRound.draw(fromDiscardPile: false)
                } else {
                    try updatedRound.draw(fromDiscardPile: true)
                }

            case .waitingForPlayerToAct(_, .needsToPlay(_, let fromDiscardPile)):
                guard let playerHand: PlayerHand = updatedRound.currentPlayerHand else {
                    return round
                }
                if fromDiscardPile == false, playerHand.faceDownCount > 0 {
                    try updatedRound.discardDrawnCard()
                } else if let slot: BoardSlot = BoardSlot.allCases.first {
                    try updatedRound.replaceCard(at: slot)
                }

            case .waitingForPlayerToAct(_, .needsToFlip):
                if let slot: BoardSlot = updatedRound.currentPlayerHand?.faceDownSlots.first {
                    try updatedRound.flip(slot: slot)
                }

            case .roundComplete, .gameComplete:
                return round
            }
        } catch {
            return round
        }
        return updatedRound
    }
}
