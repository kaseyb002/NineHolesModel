import Foundation

public typealias RoundID = String

public struct Round: Equatable, Codable, Sendable, Identifiable {
    public static let minPlayerCount: Int = 2
    public static let maxPlayerCount: Int = 6
    public static let cardsPerPlayer: Int = 8
    public static let teeOffCardCount: Int = 2
    public static let defaultHoleCount: Int = 9

    // MARK: - Initialized Properties
    public let id: RoundID
    public let started: Date
    public let holeNumber: Int
    public let ruleOptions: RuleOptions

    // MARK: - Card Data
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var deck: [CardID]
    public internal(set) var discardPile: [CardID]

    // MARK: - Players
    public internal(set) var playerHands: [PlayerHand]

    // MARK: - Game State
    public internal(set) var state: State
    public internal(set) var finalShotPlayerIDs: [PlayerID] = []

    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    public enum State: Equatable, Codable, Sendable {
        case waitingForPlayerToTeeOff(playerId: PlayerID)
        case waitingForPlayerToAct(playerId: PlayerID, turnState: TurnState)
        case roundComplete
        case gameComplete(winner: Player)

        public enum TurnState: Equatable, Codable, Sendable {
            case needsToDraw
            case needsToPlay(drawnCardId: CardID, fromDiscardPile: Bool)
            case needsToFlip
        }

        public var logValue: String {
            switch self {
            case .waitingForPlayerToTeeOff(let playerID):
                "Waiting for player \(playerID) to tee off"

            case .waitingForPlayerToAct(let playerID, .needsToDraw):
                "Waiting for player \(playerID) to draw"

            case .waitingForPlayerToAct(let playerID, .needsToPlay):
                "Waiting for player \(playerID) to play"

            case .waitingForPlayerToAct(let playerID, .needsToFlip):
                "Waiting for player \(playerID) to flip a card"

            case .roundComplete:
                "Round complete"

            case .gameComplete(let winner):
                "\(winner.name) won the game."
            }
        }
    }
}
