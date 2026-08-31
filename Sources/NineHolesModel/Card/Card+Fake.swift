import Foundation

extension Card {
    public static func fake(
        id: CardID = 0,
        value: CardValue = .five
    ) -> Card {
        .init(
            id: id,
            value: value
        )
    }
}
