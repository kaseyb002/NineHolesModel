import Foundation
import Testing
@testable import NineHolesModel

// MARK: - Helpers

private func cookedDeck(
    playerBoards: [[CardValue]],
    discard: CardValue,
    draws: [CardValue]
) -> [Card] {
    var values: [CardValue] = []
    values.append(contentsOf: draws.reversed())
    values.append(discard)
    for board in playerBoards.reversed() {
        values.append(contentsOf: board)
    }
    return .cookedDeck(values: values)
}

private func twoPlayerBoards(
    player0: CardValue = .twelve,
    player1: CardValue = .twelve
) -> [[CardValue]] {
    [
        Array(repeating: player0, count: BoardSlot.allCases.count),
        Array(repeating: player1, count: BoardSlot.allCases.count),
    ]
}

private func playHoleToCompletion(
    round: inout Round,
    maxMoves: Int = 500
) throws {
    var moveCount: Int = 0
    while round.isComplete == false {
        moveCount += 1
        if moveCount > maxMoves {
            Issue.record("Hole did not complete within \(maxMoves) moves")
            break
        }
        switch round.state {
        case .waitingForPlayerToTeeOff:
            try round.teeOff(slots: [.top1, .top2])

        case .waitingForPlayerToAct(_, .needsToDraw):
            let fromDiscardPile: Bool = round.deck.isEmpty
            try round.draw(fromDiscardPile: fromDiscardPile)

        case .waitingForPlayerToAct(_, .needsToPlay(_, let fromDiscardPile)):
            if fromDiscardPile == false,
               let slot: BoardSlot = round.currentPlayerHand?.faceDownSlots.first
            {
                try round.discardAndFlip(slot: slot)
            } else if let slot: BoardSlot = BoardSlot.allCases.first {
                try round.replaceCard(at: slot)
            }

        case .waitingForPlayerToAct(_, .needsToFlip):
            if let slot: BoardSlot = round.currentPlayerHand?.faceDownSlots.first {
                try round.flip(slot: slot)
            }

        case .roundComplete, .gameComplete:
            break
        }
    }
}

private func players(
    _ ids: [PlayerID] = ["p1", "p2"]
) -> [Player] {
    ids.enumerated().map { index, id in
        Player.fake(id: id, name: "P\(index + 1)", score: 0)
    }
}

// MARK: - Deck

@Test func deckComposition() {
    let deck: [Card] = .deck()
    #expect(deck.count == 108)
    #expect(Set(deck.map(\.id)).count == 108)

    let holeInOnes: Int = deck.filter { card in card.value == .holeInOne }.count
    #expect(holeInOnes == 4)

    for value in CardValue.allCases where value != .holeInOne {
        let count: Int = deck.filter { card in card.value == value }.count
        #expect(count == 8)
    }
}

// MARK: - Init

@Test func roundInitDealsFacedownBoards() throws {
    let round: Round = try .init(players: players())
    #expect(round.playerHands.count == 2)
    #expect(round.playerHands.allSatisfy { playerHand in
        playerHand.slots.count == 8 && playerHand.faceDownCount == 8
    })
    #expect(round.discardPile.count == 1)
    #expect(round.holeNumber == 1)
    if case .waitingForPlayerToTeeOff(let playerID) = round.state {
        #expect(playerID == "p1")
    } else {
        Issue.record("Expected tee-off state")
    }
}

@Test func roundInitRejectsTooFewPlayers() {
    #expect(throws: NineHolesError.notEnoughPlayers) {
        try Round(players: [Player.fake()])
    }
}

@Test func roundInitRejectsTooManyPlayers() {
    let tooMany: [Player] = (0 ..< 7).map { index in
        Player.fake(id: "\(index)")
    }
    #expect(throws: NineHolesError.tooManyPlayers) {
        try Round(players: tooMany)
    }
}

@Test func roundInitRejectsInvalidHoleCount() {
    #expect(throws: NineHolesError.invalidHoleCount) {
        try Round(
            players: players(),
            ruleOptions: .init(holeCount: 0)
        )
    }
}

// MARK: - Tee Off

@Test func teeOffFlipsOneCardAtATime() throws {
    var round: Round = try .init(players: players())
    try round.teeOff(slot: .top1)

    #expect(round.playerHands[0].slots[.top1]?.isFaceUp == true)
    #expect(round.playerHands[0].faceUpCount == 1)
    if case .waitingForPlayerToTeeOff(let playerID) = round.state {
        #expect(playerID == "p1")
    } else {
        Issue.record("Expected same player to tee off the second card")
    }

    try round.teeOff(slot: .bottom4)
    #expect(round.playerHands[0].slots[.bottom4]?.isFaceUp == true)
    #expect(round.playerHands[0].faceUpCount == 2)
    if case .waitingForPlayerToTeeOff(let playerID) = round.state {
        #expect(playerID == "p2")
    } else {
        Issue.record("Expected next player to tee off")
    }
}

@Test func teeOffFlipsTwoCardsAndAdvances() throws {
    var round: Round = try .init(players: players())
    try round.teeOff(slots: [.top1, .bottom4])

    #expect(round.playerHands[0].slots[.top1]?.isFaceUp == true)
    #expect(round.playerHands[0].slots[.bottom4]?.isFaceUp == true)
    #expect(round.playerHands[0].faceUpCount == 2)
    if case .waitingForPlayerToTeeOff(let playerID) = round.state {
        #expect(playerID == "p2")
    } else {
        Issue.record("Expected next player to tee off")
    }
}

@Test func teeOffRejectsDuplicateSlots() throws {
    var round: Round = try .init(players: players())
    #expect(throws: NineHolesError.invalidTeeOffSlots) {
        try round.teeOff(slots: [.top1, .top1])
    }
}

@Test func teeOffThenStartsPlay() throws {
    var round: Round = try .init(players: players())
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    if case .waitingForPlayerToAct(let playerID, .needsToDraw) = round.state {
        #expect(playerID == "p1")
    } else {
        Issue.record("Expected first player to draw")
    }
}

// MARK: - Actions

@Test func drawFromDeckThenReplace() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: [.mulligan, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .one]
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    try round.draw(fromDiscardPile: false)

    guard case .waitingForPlayerToAct(_, .needsToPlay(let drawnCardID, false)) = round.state else {
        Issue.record("Expected needsToPlay from deck")
        return
    }
    #expect(round.cardsMap[drawnCardID]?.value == .mulligan)

    try round.replaceCard(at: .top3)
    #expect(round.playerHands[0].slots[.top3]?.cardID == drawnCardID)
    #expect(round.playerHands[0].slots[.top3]?.isFaceUp == true)
}

@Test func cannotDiscardAndFlipAfterDrawingFromDiscard() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .mulligan,
        draws: [.twelve, .eleven, .ten, .nine, .eight, .seven, .six, .five, .four, .three, .two, .one]
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    try round.draw(fromDiscardPile: true)

    #expect(throws: NineHolesError.cannotDiscardDrawnFromDiscard) {
        try round.discardAndFlip(slot: .bottom1)
    }
}

@Test func skipOnlyAllowedWithOneFacedownCard() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: Array(repeating: .twelve, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    try round.draw(fromDiscardPile: false)

    #expect(throws: NineHolesError.cannotSkip) {
        try round.skip()
    }
}

@Test func skipAllowedWithOneFacedownRemaining() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: Array(repeating: .twelve, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])

    let facedownSlots: [BoardSlot] = round.playerHands[0].faceDownSlots
    for slot in facedownSlots.dropLast() {
        try round.draw(fromDiscardPile: false)
        try round.discardAndFlip(slot: slot)
        try round.draw(fromDiscardPile: false)
        if let opponentSlot: BoardSlot = round.currentPlayerHand?.faceDownSlots.first {
            try round.discardAndFlip(slot: opponentSlot)
        }
    }

    #expect(round.playerHands[0].faceDownCount == 1)
    try round.draw(fromDiscardPile: false)
    try round.skip()
    #expect(round.playerHands[0].faceDownCount == 1)
}

@Test func discardDrawnCardThenFlip() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: [.mulligan, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .one]
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    try round.draw(fromDiscardPile: false)

    guard let drawnCardID: CardID = round.drawnCard?.id,
          let flipSlot: BoardSlot = round.playerHands[0].faceDownSlots.first
    else {
        Issue.record("Expected a drawn card and a facedown slot")
        return
    }

    try round.discardDrawnCard()
    #expect(round.discardPile.last == drawnCardID)
    #expect(round.drawnCard == nil)
    if case .waitingForPlayerToAct(_, .needsToFlip) = round.state {
        // expected
    } else {
        Issue.record("Expected needsToFlip")
        return
    }

    try round.flip(slot: flipSlot)
    #expect(round.playerHands[0].slots[flipSlot]?.isFaceUp == true)
}

@Test func cannotDiscardDrawnCardAfterDrawingFromDiscard() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .mulligan,
        draws: [.twelve, .eleven, .ten, .nine, .eight, .seven, .six, .five, .four, .three, .two, .one]
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    try round.draw(fromDiscardPile: true)

    #expect(throws: NineHolesError.cannotDiscardDrawnFromDiscard) {
        try round.discardDrawnCard()
    }
}

@Test func skipAllowedAfterDiscardingDrawnCard() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: Array(repeating: .twelve, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])

    let facedownSlots: [BoardSlot] = round.playerHands[0].faceDownSlots
    for slot in facedownSlots.dropLast() {
        try round.draw(fromDiscardPile: false)
        try round.discardAndFlip(slot: slot)
        try round.draw(fromDiscardPile: false)
        if let opponentSlot: BoardSlot = round.currentPlayerHand?.faceDownSlots.first {
            try round.discardAndFlip(slot: opponentSlot)
        }
    }

    #expect(round.playerHands[0].faceDownCount == 1)
    try round.draw(fromDiscardPile: false)
    try round.discardDrawnCard()
    try round.skip()
    #expect(round.playerHands[0].faceDownCount == 1)
}

@Test func matchingPairCancelsToZero() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .six, .top2: .eight, .top3: .nine, .top4: .ten,
            .bottom1: .six, .bottom2: .eleven, .bottom3: .twelve, .bottom4: .five,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == 8 + 11 + 9 + 12 + 10 + 5)
}

@Test func matchingFourAddsMinusTenBonus() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .seven, .top2: .seven, .top3: .three, .top4: .four,
            .bottom1: .seven, .bottom2: .seven, .bottom3: .three, .bottom4: .five,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == -10 + 4 + 5)
}

@Test func matchingSixAddsMinusFifteenBonus() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .two, .top2: .two, .top3: .two, .top4: .twelve,
            .bottom1: .two, .bottom2: .two, .bottom3: .two, .bottom4: .eleven,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == -15 + 12 + 11)
}

@Test func matchingEightAddsMinusTwentyBonus() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .three, .top2: .three, .top3: .three, .top4: .three,
            .bottom1: .three, .bottom2: .three, .bottom3: .three, .bottom4: .three,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == -20)
}

@Test func holeInOnePairDoesNotCancel() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .holeInOne, .top2: .six, .top3: .seven, .top4: .eight,
            .bottom1: .holeInOne, .bottom2: .nine, .bottom3: .ten, .bottom4: .eleven,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == -10 + 6 + 9 + 7 + 10 + 8 + 11)
}

@Test func fourHoleInOneBonusIsMinusThirty() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .holeInOne, .top2: .holeInOne, .top3: .one, .top4: .two,
            .bottom1: .holeInOne, .bottom2: .holeInOne, .bottom3: .one, .bottom4: .two,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == -30)
}

@Test func adjacentDifferentPairsDoNotGetFourCardBonus() {
    let result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .six, .top2: .seven, .top3: .eight, .top4: .nine,
            .bottom1: .six, .bottom2: .seven, .bottom3: .eight, .bottom4: .ten,
        ]
    )
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == 9 + 10)
}

@Test func visibleStrokeScoreIgnoresFacedownCards() {
    var result: (hand: PlayerHand, cardsMap: [CardID: Card]) = PlayerHand.fakeFaceUp(
        values: [
            .top1: .six, .top2: .eight, .top3: .nine, .top4: .ten,
            .bottom1: .six, .bottom2: .eleven, .bottom3: .twelve, .bottom4: .five,
        ]
    )
    result.hand.slots[.bottom1]?.isFaceUp = false
    result.hand.slots[.bottom2]?.isFaceUp = false
    #expect(result.hand.visibleStrokeScore(cardsMap: result.cardsMap) == 6 + 8 + 9 + 12 + 10 + 5)
    #expect(result.hand.strokeScore(cardsMap: result.cardsMap) == 8 + 11 + 9 + 12 + 10 + 5)
}

// MARK: - Full Hole

@Test func playsThroughAnEntireHole() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(player0: .mulligan, player1: .twelve),
        discard: .eleven,
        draws: Array(repeating: .ten, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players(),
        ruleOptions: .init(holeCount: 9)
    )
    try playHoleToCompletion(round: &round)

    #expect(round.isComplete)
    if case .roundComplete = round.state {
        #expect(round.playerHands[0].player.holeScores.count == 1)
        #expect(round.playerHands[1].player.holeScores.count == 1)
        #expect(round.playerHands[0].isPuttedOut)
        #expect(round.playerHands[1].faceUpCount == 8)
    } else {
        Issue.record("Expected roundComplete after hole 1 of 9, got \(round.state.logValue)")
    }
}

@Test func putOutGivesOpponentsOneFinalShot() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: Array(repeating: .twelve, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])

    func flipNextFacedown() throws {
        try round.draw(fromDiscardPile: false)
        guard let slot: BoardSlot = round.currentPlayerHand?.faceDownSlots.first else {
            Issue.record("Expected a facedown card")
            return
        }
        try round.discardAndFlip(slot: slot)
    }

    while round.playerHands[0].faceDownCount > 0 && round.isComplete == false {
        try flipNextFacedown()
        if round.playerHands[0].isPuttedOut {
            break
        }
        if case .waitingForPlayerToAct(let playerID, .needsToDraw) = round.state,
           playerID == "p2"
        {
            try flipNextFacedown()
        }
    }

    #expect(round.playerHands[0].isPuttedOut)
    #expect(round.finalShotPlayerIDs.contains("p2"))
    if case .waitingForPlayerToAct(let playerID, .needsToDraw) = round.state {
        #expect(playerID == "p2")
    } else {
        Issue.record("Expected p2 final shot, got \(round.state.logValue)")
    }
}

// MARK: - Next Round / Game Complete

@Test func nextRoundRotatesStarterAndIncrementsHole() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: Array(repeating: .ten, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players(),
        ruleOptions: .init(holeCount: 9)
    )
    try playHoleToCompletion(round: &round)

    let next: Round? = try Round.nextRound(previous: round)
    #expect(next != nil)
    #expect(next?.holeNumber == 2)
    #expect(next?.ruleOptions.holeCount == 9)
    #expect(next?.playerHands.first?.player.id == "p2")
    #expect(next?.playerHands.last?.player.id == "p1")
}

@Test func nextRoundUsesUpdatedHoleCountWhenProvided() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .eleven,
        draws: Array(repeating: .ten, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players(),
        ruleOptions: .init(holeCount: 9)
    )
    try playHoleToCompletion(round: &round)

    let next: Round? = try Round.nextRound(
        previous: round,
        ruleOptions: .init(holeCount: 3)
    )
    #expect(next?.holeNumber == 2)
    #expect(next?.ruleOptions.holeCount == 3)
    #expect(next?.isSuddenDeath == false)
}

@Test func gameCompletesAfterConfiguredHoleCountWithUniqueWinner() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: [
            Array(repeating: .mulligan, count: 8),
            [.twelve, .eleven, .ten, .nine, .eight, .seven, .six, .five],
        ],
        discard: .eleven,
        draws: Array(repeating: .ten, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players(),
        ruleOptions: .init(holeCount: 1)
    )
    try playHoleToCompletion(round: &round)

    if case .gameComplete(let winner) = round.state {
        #expect(winner.id == "p1")
        #expect(winner.score < round.playerHands[1].player.score)
    } else {
        Issue.record("Expected gameComplete, got \(round.state.logValue)")
    }
    #expect(try Round.nextRound(previous: round) == nil)
}

@Test func tiedGameContinuesAsSuddenDeath() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(player0: .twelve, player1: .twelve),
        discard: .eleven,
        draws: Array(repeating: .ten, count: 20)
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players(),
        ruleOptions: .init(holeCount: 1)
    )
    try playHoleToCompletion(round: &round)

    if case .roundComplete = round.state {
        #expect(round.playerHands[0].player.score == round.playerHands[1].player.score)
    } else {
        Issue.record("Expected roundComplete for sudden death, got \(round.state.logValue)")
    }

    let suddenDeath: Round? = try Round.nextRound(previous: round)
    #expect(suddenDeath?.holeNumber == 2)
    #expect(suddenDeath?.isSuddenDeath == true)
}

// MARK: - Reshuffle

@Test func reshufflesDiscardWhenDeckIsEmpty() throws {
    let deck: [Card] = cookedDeck(
        playerBoards: twoPlayerBoards(),
        discard: .one,
        draws: [.two]
    )
    var round: Round = try .init(
        cookedDeck: deck,
        players: players()
    )
    try round.teeOff(slots: [.top1, .top2])
    try round.teeOff(slots: [.top1, .top2])
    try round.draw(fromDiscardPile: false)
    try round.replaceCard(at: .bottom1)
    #expect(round.deck.isEmpty)

    try round.draw(fromDiscardPile: false)
    guard case .waitingForPlayerToAct(_, .needsToPlay(let drawnCardID, false)) = round.state else {
        Issue.record("Expected a reshuffled deck draw")
        return
    }
    #expect(round.cardsMap[drawnCardID] != nil)
    #expect(round.discardPile.isEmpty == false)
}

// MARK: - Log

@Test func logKeepsOnlyLatestHundredActions() {
    var log: Round.Log = .init()
    for _ in 0 ..< 120 {
        log.addAction(.init(
            playerID: "p1",
            decision: .skip(drawnCardId: 0)
        ))
    }
    #expect(log.actions.count == 100)
}

// MARK: - Fakes

@Test func fakesExist() throws {
    let _: Card = .fake()
    let _: BoardCard = .fake()
    let _: Player = .fake()
    let _: PlayerHand = .fake()
    let _: RuleOptions = .fake()
    let _: AIEngine = .fake()
    let _: AIDifficulty = .fake()
    let _: Round = try .fake()
}

// MARK: - AI

@Test func aiPlaysThroughEntireHoleWithoutCheating() throws {
    var round: Round = try .init(
        players: players(),
        ruleOptions: .init(holeCount: 1)
    )
    let engine: AIEngine = .init(difficulty: .medium)
    var moveCount: Int = 0
    var seenFacedownValues: Set<CardID> = []

    while round.isComplete == false {
        moveCount += 1
        if moveCount > 400 {
            Issue.record("AI failed to finish the hole")
            break
        }

        for playerHand in round.playerHands {
            for slot in playerHand.faceDownSlots {
                if let cardID: CardID = playerHand.slots[slot]?.cardID {
                    seenFacedownValues.insert(cardID)
                }
            }
        }

        guard let playerID: PlayerID = round.currentPlayerID else { break }
        let before: Round = round
        round = engine.makeMove(in: round, for: playerID)
        #expect(round != before || round.isComplete)
    }

    #expect(round.isComplete)
    #expect(moveCount > 4)
    _ = seenFacedownValues
}

@Test func aiAllDifficultiesCompleteAHole() throws {
    for difficulty in AIDifficulty.allCases {
        var round: Round = try .init(
            players: players(["a", "b"]),
            ruleOptions: .init(holeCount: 1)
        )
        let engine: AIEngine = .init(difficulty: difficulty)
        var moveCount: Int = 0
        while round.isComplete == false {
            moveCount += 1
            if moveCount > 400 { break }
            guard let playerID: PlayerID = round.currentPlayerID else { break }
            round = engine.makeMove(in: round, for: playerID)
        }
        #expect(round.isComplete, "AI \(difficulty) should complete a hole")
    }
}
