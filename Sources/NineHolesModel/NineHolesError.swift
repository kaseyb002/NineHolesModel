import Foundation

public enum NineHolesError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case invalidHoleCount
    case notWaitingForPlayerToTeeOff
    case notWaitingForPlayerToDraw
    case notWaitingForPlayerToPlay
    case invalidTeeOffSlots
    case cardAlreadyFaceUp
    case cannotSkip
    case cannotDiscardDrawnFromDiscard
    case cannotDiscardDrawnCard
    case notWaitingForPlayerToFlip
    case discardPileEmpty
    case deckAndDiscardEmpty
    case roundIsIncomplete
    case roundIsComplete
    case gameIsComplete
    case playerNotFound
    case slotNotFound
}
