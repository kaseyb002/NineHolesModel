import Foundation

extension AIEngine {
    public static func fake(
        difficulty: AIDifficulty = .medium
    ) -> AIEngine {
        .init(difficulty: difficulty)
    }
}

extension AIDifficulty {
    public static func fake() -> AIDifficulty {
        .medium
    }
}
