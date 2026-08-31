import Foundation

public enum CardValue: Int, Equatable, Codable, Sendable, CaseIterable, Comparable {
    case holeInOne = -5
    case mulligan = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case eleven = 11
    case twelve = 12

    public var strokeValue: Int { rawValue }

    public var isHoleInOne: Bool { self == .holeInOne }

    public var displayableName: String {
        switch self {
        case .holeInOne: "Hole-in-One"
        case .mulligan: "Mulligan"
        case .twelve: "Out of Bounds"
        case .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .eleven:
            "\(rawValue)"
        }
    }

    public var logValue: String {
        switch self {
        case .holeInOne: "-5"
        case .mulligan: "0"
        default: "\(rawValue)"
        }
    }

    public static func < (lhs: CardValue, rhs: CardValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
