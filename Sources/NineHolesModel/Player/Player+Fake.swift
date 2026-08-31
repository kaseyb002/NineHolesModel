import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = Lorem.fullName,
        imageURL: URL? = .randomImageURL,
        score: Int = 0,
        holeScores: [Int] = []
    ) -> Player {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            score: score,
            holeScores: holeScores
        )
    }
}
