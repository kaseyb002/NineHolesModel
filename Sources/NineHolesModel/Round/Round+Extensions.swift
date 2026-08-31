import Foundation

extension Round {
    public var currentPlayerHandIndex: Int? {
        switch state {
        case .waitingForPlayerToTeeOff(let playerID),
             .waitingForPlayerToAct(let playerID, _):
            return playerHands.firstIndex { playerHand in
                playerHand.player.id == playerID
            }

        case .roundComplete, .gameComplete:
            return nil
        }
    }

    public var currentPlayerHand: PlayerHand? {
        guard let currentPlayerHandIndex else { return nil }
        return playerHands[currentPlayerHandIndex]
    }

    public var currentPlayerID: PlayerID? {
        switch state {
        case .waitingForPlayerToTeeOff(let playerID),
             .waitingForPlayerToAct(let playerID, _):
            playerID

        case .roundComplete, .gameComplete:
            nil
        }
    }

    public var isComplete: Bool {
        switch state {
        case .roundComplete, .gameComplete: true
        case .waitingForPlayerToTeeOff, .waitingForPlayerToAct: false
        }
    }

    public var isSuddenDeath: Bool {
        holeNumber > ruleOptions.holeCount
    }

    public var topDiscardCard: Card? {
        guard let cardID: CardID = discardPile.last else {
            return nil
        }
        return cardsMap[cardID]
    }

    public var drawnCard: Card? {
        guard case .waitingForPlayerToAct(_, .needsToPlay(let cardID, _)) = state else {
            return nil
        }
        return cardsMap[cardID]
    }

    public var logValue: String {
        """
        State: \(state.logValue)
        Hole: \(holeNumber)/\(ruleOptions.holeCount)
        Deck remaining: \(deck.count)
        Discard top: \(topDiscardCard?.logValue ?? "None")

        \(playerHands.map { playerHand in
            "\(playerHand.player.name) (\(playerHand.player.id)): score \(playerHand.player.score), face-up \(playerHand.faceUpCount)/8"
        }.joined(separator: "\n"))
        """
    }
}
