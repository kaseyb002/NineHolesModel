import Foundation

extension Round {
    public static func fake(
        id: RoundID = UUID().uuidString,
        started: Date = .init(),
        cookedDeck: [Card]? = nil,
        players: [Player] = [
            .fake(),
            .fake(),
        ],
        holeNumber: Int = 1,
        ruleOptions: RuleOptions = .classic
    ) throws -> Round {
        try self.init(
            id: id,
            started: started,
            cookedDeck: cookedDeck,
            players: players,
            holeNumber: holeNumber,
            ruleOptions: ruleOptions
        )
    }
}
