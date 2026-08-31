import Foundation

extension Round {
    public init(
        id: RoundID = UUID().uuidString,
        started: Date = .init(),
        cookedDeck: [Card]? = nil,
        players: [Player],
        holeNumber: Int = 1,
        ruleOptions: RuleOptions = .classic
    ) throws {
        guard players.count >= Self.minPlayerCount else {
            throw NineHolesError.notEnoughPlayers
        }
        guard players.count <= Self.maxPlayerCount else {
            throw NineHolesError.tooManyPlayers
        }
        guard ruleOptions.holeCount >= 1 else {
            throw NineHolesError.invalidHoleCount
        }

        self.id = id
        self.started = started
        self.holeNumber = holeNumber
        self.ruleOptions = ruleOptions

        var deck: [Card] = cookedDeck ?? [Card].deck().shuffled()
        guard deck.count >= players.count * Self.cardsPerPlayer + 1 else {
            throw NineHolesError.deckAndDiscardEmpty
        }
        self.cardsMap = Dictionary(uniqueKeysWithValues: deck.map { card in
            (card.id, card)
        })
        self.playerHands = Self.dealCards(
            to: players,
            deck: &deck
        )

        guard deck.isEmpty == false else {
            throw NineHolesError.deckAndDiscardEmpty
        }
        let firstDiscard: Card = deck.removeLast()
        self.deck = deck.map(\.id)
        self.discardPile = [firstDiscard.id]
        self.state = .waitingForPlayerToTeeOff(
            playerId: players.first!.id
        )
    }

    /// Returns `nil` if the game is complete.
    public static func nextRound(
        previous: Round,
        newPlayers: [Player]? = nil,
        ruleOptions: RuleOptions? = nil
    ) throws -> Round? {
        switch previous.state {
        case .gameComplete:
            return nil

        case .roundComplete:
            break

        case .waitingForPlayerToTeeOff, .waitingForPlayerToAct:
            throw NineHolesError.roundIsIncomplete
        }

        var players: [Player] = newPlayers ?? previous.playerHands.map(\.player)
        let firstPlayer: Player = players.removeFirst()
        players.append(firstPlayer)

        return try .init(
            players: players,
            holeNumber: previous.holeNumber + 1,
            ruleOptions: ruleOptions ?? previous.ruleOptions
        )
    }

    private static func dealCards(
        to players: [Player],
        deck: inout [Card]
    ) -> [PlayerHand] {
        var playerHands: [PlayerHand] = []
        for player in players {
            let playerCards: [Card] = Array(deck.suffix(Self.cardsPerPlayer))
            deck.removeLast(Self.cardsPerPlayer)
            var slots: [BoardSlot: BoardCard] = [:]
            for (index, slot) in BoardSlot.allCases.enumerated() {
                slots[slot] = BoardCard(
                    cardID: playerCards[index].id,
                    isFaceUp: false
                )
            }
            playerHands.append(
                PlayerHand(
                    player: player,
                    slots: slots
                )
            )
        }
        return playerHands
    }
}
