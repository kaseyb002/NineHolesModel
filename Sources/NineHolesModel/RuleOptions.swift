import Foundation

public struct RuleOptions: Equatable, Codable, Sendable {
    public var holeCount: Int

    public init(
        holeCount: Int = Round.defaultHoleCount
    ) {
        self.holeCount = holeCount
    }

    public static let classic: RuleOptions = .init()
}
