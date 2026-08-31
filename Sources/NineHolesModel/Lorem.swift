import Foundation

public final class Lorem: Sendable {
    public static var firstName: String {
        firstNames.randomElement()!
    }

    public static var lastName: String {
        lastNames.randomElement()!
    }

    public static var fullName: String {
        "\(firstName) \(lastName)"
    }

    private static let firstNames: [String] = [
        "Judith", "Angelo", "Margarita", "Kerry", "Elaine", "Lorenzo",
        "Justice", "Doris", "Raul", "Liliana", "Elise", "Ciaran",
        "Johnny", "Moses", "Davion", "Penny", "Mohammed", "Harvey",
        "Sheryl", "Hudson", "Brendan", "Denis", "Sadie", "Trisha",
        "Virgil", "Cindy", "Alexa", "Casey", "Angela", "Katherine",
        "Abel", "Adrianna", "Luis", "Noel", "Ciara", "Roberto",
        "Skylar", "Brock", "Earl", "Jackie", "Sienna", "Nolan",
        "Jean", "Shirley", "Connor", "Niall", "Kristi", "Yvonne",
        "Fatima", "Ruby", "Nadia", "Calum", "Peggy", "Alfredo",
        "Bonnie", "Gordon", "Cara", "John", "Samuel", "Carmen",
    ]

    private static let lastNames: [String] = [
        "Chung", "Chen", "Melton", "Hill", "Puckett", "Song",
        "Hamilton", "Bender", "Wagner", "McLaughlin", "McNamara",
        "Raynor", "Moon", "Woodard", "Desai", "Wallace", "Lawrence",
        "Griffin", "Dougherty", "Powers", "May", "Steele", "Teague",
        "Gallagher", "Solomon", "Walsh", "Monroe", "Connolly",
        "Hawkins", "Middleton", "Goldstein", "Watts", "Johnston",
        "Weeks", "Wilkerson", "Barton", "Walton", "Hall", "Ross",
        "Woods", "Joseph", "Rosenthal", "Bowden", "Underwood",
        "Jones", "Baker", "Merritt", "Cross", "Cooper", "Holmes",
        "Sharpe", "Morgan", "Allen", "Rich", "Grant", "Proctor",
        "Diaz", "Graham", "Watkins", "Hinton", "Marsh", "Hewitt",
    ]
}
