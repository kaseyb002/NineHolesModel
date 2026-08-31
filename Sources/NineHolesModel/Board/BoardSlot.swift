import Foundation

public enum BoardRow: String, Equatable, Codable, Sendable, CaseIterable {
    case top
    case bottom

    public var displayableName: String {
        switch self {
        case .top: "Top"
        case .bottom: "Bottom"
        }
    }
}

public enum BoardColumn: String, Equatable, Codable, Sendable, CaseIterable {
    case one
    case two
    case three
    case four

    public var index: Int {
        switch self {
        case .one: 0
        case .two: 1
        case .three: 2
        case .four: 3
        }
    }

    public var displayableName: String {
        switch self {
        case .one: "1"
        case .two: "2"
        case .three: "3"
        case .four: "4"
        }
    }

    public static func from(index: Int) -> BoardColumn? {
        BoardColumn.allCases.first { column in
            column.index == index
        }
    }
}

public enum BoardSlot: String, Equatable, Codable, Sendable, CaseIterable, Identifiable {
    case top1
    case top2
    case top3
    case top4
    case bottom1
    case bottom2
    case bottom3
    case bottom4

    public var id: BoardSlot { self }

    public var displayableName: String {
        "\(row.displayableName) \(column.displayableName)"
    }

    public var row: BoardRow {
        switch self {
        case .top1, .top2, .top3, .top4:
            .top
        case .bottom1, .bottom2, .bottom3, .bottom4:
            .bottom
        }
    }

    public var column: BoardColumn {
        switch self {
        case .top1, .bottom1: .one
        case .top2, .bottom2: .two
        case .top3, .bottom3: .three
        case .top4, .bottom4: .four
        }
    }

    public var partner: BoardSlot {
        switch self {
        case .top1: .bottom1
        case .top2: .bottom2
        case .top3: .bottom3
        case .top4: .bottom4
        case .bottom1: .top1
        case .bottom2: .top2
        case .bottom3: .top3
        case .bottom4: .top4
        }
    }

    public static func slot(
        row: BoardRow,
        column: BoardColumn
    ) -> BoardSlot {
        switch (row, column) {
        case (.top, .one): .top1
        case (.top, .two): .top2
        case (.top, .three): .top3
        case (.top, .four): .top4
        case (.bottom, .one): .bottom1
        case (.bottom, .two): .bottom2
        case (.bottom, .three): .bottom3
        case (.bottom, .four): .bottom4
        }
    }
}

public struct BoardCard: Equatable, Codable, Sendable {
    public let cardID: CardID
    public var isFaceUp: Bool

    public enum CodingKeys: String, CodingKey {
        case cardID = "cardId"
        case isFaceUp
    }

    public init(
        cardID: CardID,
        isFaceUp: Bool
    ) {
        self.cardID = cardID
        self.isFaceUp = isFaceUp
    }
}

extension BoardCard {
    public static func fake(
        cardID: CardID = 0,
        isFaceUp: Bool = false
    ) -> BoardCard {
        .init(
            cardID: cardID,
            isFaceUp: isFaceUp
        )
    }
}
