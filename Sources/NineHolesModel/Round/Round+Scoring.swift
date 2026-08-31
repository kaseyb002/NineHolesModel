import Foundation

extension Round {
    mutating func endHole() {
        for index in playerHands.indices {
            playerHands[index].revealAll()
            let holeScore: Int = playerHands[index].strokeScore(cardsMap: cardsMap)
            playerHands[index].player.holeScores.append(holeScore)
            playerHands[index].player.score += holeScore
        }

        ended = .now

        if holeNumber >= ruleOptions.holeCount {
            let lowestScore: Int = playerHands.map { playerHand in
                playerHand.player.score
            }.min() ?? 0
            let leaders: [Player] = playerHands
                .map(\.player)
                .filter { player in
                    player.score == lowestScore
                }
            if let winner: Player = leaders.first, leaders.count == 1 {
                state = .gameComplete(winner: winner)
                return
            }
        }

        state = .roundComplete
    }

    public func strokeScore(for playerID: PlayerID) -> Int? {
        guard let playerHand: PlayerHand = playerHands.first(where: { playerHand in
            playerHand.player.id == playerID
        }) else {
            return nil
        }
        return playerHand.strokeScore(cardsMap: cardsMap)
    }
}
