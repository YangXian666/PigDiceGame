import Foundation

// MARK: - Enums

enum GameMode {
    case vsPlayer
    case vsComputer
}

enum DiceMode {
    case single
    case double
}

// MARK: - Player

struct Player {
    let id: Int
    var name: String
    var totalScore: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var isHuman: Bool = true
}

// MARK: - GameState

enum GamePhase {
    case playing
    case gameOver(winner: Int) // player id
}
