import Foundation

extension RuleOptions {
    public static func fake(
        holeCount: Int = Round.defaultHoleCount
    ) -> RuleOptions {
        .init(holeCount: holeCount)
    }
}
