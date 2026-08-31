import Foundation

public typealias CardID = Int

public struct Card: Equatable, Codable, Sendable, Identifiable {
    public let id: CardID
    public let value: CardValue

    public init(
        id: CardID,
        value: CardValue
    ) {
        self.id = id
        self.value = value
    }

    public var strokeValue: Int { value.strokeValue }

    public var logValue: String {
        "\(value.logValue)#\(id)"
    }
}
