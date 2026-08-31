import Foundation

extension Round {
    public mutating func teeOff(slot: BoardSlot) throws {
        guard case .waitingForPlayerToTeeOff(let playerID) = state,
              let handIndex: Int = currentPlayerHandIndex
        else {
            throw NineHolesError.notWaitingForPlayerToTeeOff
        }
        guard playerHands[handIndex].faceUpCount < Self.teeOffCardCount else {
            throw NineHolesError.invalidTeeOffSlots
        }
        guard let boardCard: BoardCard = playerHands[handIndex].slots[slot] else {
            throw NineHolesError.slotNotFound
        }
        guard boardCard.isFaceUp == false else {
            throw NineHolesError.cardAlreadyFaceUp
        }

        playerHands[handIndex].slots[slot]?.isFaceUp = true

        log.addAction(.init(
            playerID: playerID,
            decision: .teeOff(slots: [slot])
        ))

        if playerHands[handIndex].faceUpCount < Self.teeOffCardCount {
            return
        }

        let nextIndex: Int = handIndex + 1
        if nextIndex < playerHands.count {
            state = .waitingForPlayerToTeeOff(
                playerId: playerHands[nextIndex].player.id
            )
        } else {
            state = .waitingForPlayerToAct(
                playerId: playerHands[0].player.id,
                turnState: .needsToDraw
            )
        }
    }

    public mutating func teeOff(slots: [BoardSlot]) throws {
        guard slots.count == Self.teeOffCardCount,
              Set(slots).count == Self.teeOffCardCount
        else {
            throw NineHolesError.invalidTeeOffSlots
        }
        for slot in slots {
            try teeOff(slot: slot)
        }
    }

    public mutating func draw(fromDiscardPile: Bool) throws {
        guard case .waitingForPlayerToAct(let playerID, .needsToDraw) = state else {
            throw NineHolesError.notWaitingForPlayerToDraw
        }

        let drawnCardID: CardID
        if fromDiscardPile {
            guard let cardID: CardID = discardPile.popLast() else {
                throw NineHolesError.discardPileEmpty
            }
            drawnCardID = cardID
        } else {
            if deck.isEmpty {
                reshuffleDiscardIntoDeck()
            }
            guard let cardID: CardID = deck.popLast() else {
                throw NineHolesError.deckAndDiscardEmpty
            }
            drawnCardID = cardID
        }

        log.addAction(.init(
            playerID: playerID,
            decision: .draw(
                cardId: drawnCardID,
                fromDiscardPile: fromDiscardPile
            )
        ))

        state = .waitingForPlayerToAct(
            playerId: playerID,
            turnState: .needsToPlay(
                drawnCardId: drawnCardID,
                fromDiscardPile: fromDiscardPile
            )
        )
    }

    public mutating func replaceCard(at slot: BoardSlot) throws {
        let playContext: PlayContext = try currentPlayContext()
        guard let boardCard: BoardCard = playerHands[playContext.handIndex].slots[slot] else {
            throw NineHolesError.slotNotFound
        }

        playerHands[playContext.handIndex].slots[slot] = BoardCard(
            cardID: playContext.drawnCardID,
            isFaceUp: true
        )
        discardPile.append(boardCard.cardID)

        log.addAction(.init(
            playerID: playContext.playerID,
            decision: .replace(
                slot: slot,
                drawnCardId: playContext.drawnCardID,
                discardedCardId: boardCard.cardID
            )
        ))

        try finishPlay(handIndex: playContext.handIndex)
    }

    public mutating func discardDrawnCard() throws {
        let playContext: PlayContext = try currentPlayContext()
        guard playContext.fromDiscardPile == false else {
            throw NineHolesError.cannotDiscardDrawnFromDiscard
        }
        guard playerHands[playContext.handIndex].faceDownCount > 0 else {
            throw NineHolesError.cannotDiscardDrawnCard
        }

        discardPile.append(playContext.drawnCardID)

        log.addAction(.init(
            playerID: playContext.playerID,
            decision: .discardDrawn(drawnCardId: playContext.drawnCardID)
        ))

        state = .waitingForPlayerToAct(
            playerId: playContext.playerID,
            turnState: .needsToFlip
        )
    }

    public mutating func flip(slot: BoardSlot) throws {
        guard case .waitingForPlayerToAct(let playerID, .needsToFlip) = state,
              let handIndex: Int = currentPlayerHandIndex
        else {
            throw NineHolesError.notWaitingForPlayerToFlip
        }
        guard let boardCard: BoardCard = playerHands[handIndex].slots[slot] else {
            throw NineHolesError.slotNotFound
        }
        guard boardCard.isFaceUp == false else {
            throw NineHolesError.cardAlreadyFaceUp
        }

        playerHands[handIndex].slots[slot]?.isFaceUp = true

        log.addAction(.init(
            playerID: playerID,
            decision: .flip(slot: slot)
        ))

        try finishPlay(handIndex: handIndex)
    }

    public mutating func discardAndFlip(slot: BoardSlot) throws {
        try discardDrawnCard()
        try flip(slot: slot)
    }

    public mutating func skip() throws {
        switch state {
        case .waitingForPlayerToAct(let playerID, .needsToPlay(let drawnCardID, let fromDiscardPile)):
            guard fromDiscardPile == false else {
                throw NineHolesError.cannotDiscardDrawnFromDiscard
            }
            guard let handIndex: Int = currentPlayerHandIndex else {
                throw NineHolesError.notWaitingForPlayerToPlay
            }
            guard playerHands[handIndex].faceDownCount == 1 else {
                throw NineHolesError.cannotSkip
            }

            discardPile.append(drawnCardID)

            log.addAction(.init(
                playerID: playerID,
                decision: .skip(drawnCardId: drawnCardID)
            ))

            try finishPlay(handIndex: handIndex)

        case .waitingForPlayerToAct(let playerID, .needsToFlip):
            guard let handIndex: Int = currentPlayerHandIndex else {
                throw NineHolesError.notWaitingForPlayerToFlip
            }
            guard playerHands[handIndex].faceDownCount == 1 else {
                throw NineHolesError.cannotSkip
            }

            log.addAction(.init(
                playerID: playerID,
                decision: .skip(drawnCardId: discardPile.last ?? 0)
            ))

            try finishPlay(handIndex: handIndex)

        case .waitingForPlayerToTeeOff, .waitingForPlayerToAct(_, .needsToDraw), .roundComplete, .gameComplete:
            throw NineHolesError.notWaitingForPlayerToPlay
        }
    }

    // MARK: - Private

    private struct PlayContext {
        let playerID: PlayerID
        let handIndex: Int
        let drawnCardID: CardID
        let fromDiscardPile: Bool
    }

    private func currentPlayContext() throws -> PlayContext {
        guard case .waitingForPlayerToAct(
            let playerID,
            .needsToPlay(let drawnCardID, let fromDiscardPile)
        ) = state,
              let handIndex: Int = currentPlayerHandIndex
        else {
            throw NineHolesError.notWaitingForPlayerToPlay
        }
        return PlayContext(
            playerID: playerID,
            handIndex: handIndex,
            drawnCardID: drawnCardID,
            fromDiscardPile: fromDiscardPile
        )
    }

    private mutating func reshuffleDiscardIntoDeck() {
        guard discardPile.count > 1 else { return }
        let topCardID: CardID = discardPile.removeLast()
        deck = discardPile.shuffled()
        discardPile = [topCardID]
    }

    private mutating func finishPlay(handIndex: Int) throws {
        if isComplete {
            throw NineHolesError.roundIsComplete
        }

        let playerID: PlayerID = playerHands[handIndex].player.id
        let justPuttedOut: Bool = playerHands[handIndex].isPuttedOut
            && finalShotPlayerIDs.contains(playerID) == false
            && finalShotPlayerIDs.isEmpty

        if justPuttedOut {
            finalShotPlayerIDs = (1 ..< playerHands.count).map { offset in
                let index: Int = (handIndex + offset) % playerHands.count
                return playerHands[index].player.id
            }
        }

        if finalShotPlayerIDs.isEmpty == false {
            finalShotPlayerIDs.removeAll { remainingPlayerID in
                remainingPlayerID == playerID
            }
            if let nextPlayerID: PlayerID = finalShotPlayerIDs.first {
                state = .waitingForPlayerToAct(
                    playerId: nextPlayerID,
                    turnState: .needsToDraw
                )
            } else {
                endHole()
            }
            return
        }

        let nextIndex: Int = (handIndex + 1) % playerHands.count
        state = .waitingForPlayerToAct(
            playerId: playerHands[nextIndex].player.id,
            turnState: .needsToDraw
        )
    }
}
