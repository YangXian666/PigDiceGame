import Foundation
import Combine

class GameViewModel: ObservableObject {

    // MARK: - Setup
    @Published var gameMode: GameMode = .vsPlayer
    @Published var diceMode: DiceMode = .single

    // MARK: - Players
    @Published var players: [Player] = []

    // MARK: - Round state
    @Published var currentPlayerIndex: Int = 0
    @Published var currentRoundScore: Int = 0
    @Published var dice1: Int = 1
    @Published var dice2: Int = 1
    @Published var hasRolled: Bool = false
    @Published var gamePhase: GamePhase = .playing
    @Published var mustRollAgain: Bool = false
    @Published var roundMessage: String = ""
    @Published var isComputerThinking: Bool = false
    @Published var isEndingTurn: Bool = false
    
    private var currentComputerTask: Task<Void, Never>?

    // MARK: - Init
    init() {
        players = [
            Player(id: 0, name: "玩家 1"),
            Player(id: 1, name: "玩家 2")
        ]
    }

    // setupGame
    func setupGame(
        mode: GameMode,
        diceMode: DiceMode,
        playerNames: [String],
        computerCount: Int = 0
    ) {
        self.gameMode = mode
        self.diceMode = diceMode

        var newPlayers: [Player] = []

        // 加入真人玩家
        for (i, name) in playerNames.enumerated() {
            newPlayers.append(
                Player(id: i, name: name.isEmpty ? "玩家 \(i+1)" : name, isHuman: true)
            )
        }

        // 加入電腦玩家
        if mode == .vsComputer {
            for i in 0..<computerCount {
                let id = playerNames.count + i
                let name = computerCount == 1 ? "電腦" : "電腦 \(i+1)"
                newPlayers.append(Player(id: id, name: name, isHuman: false))
            }
        }

        players = newPlayers
        resetRound()
        gamePhase = .playing
    }

    var currentPlayer: Player { players[currentPlayerIndex] }

    // MARK: - Roll

    func roll() {
        guard case .playing = gamePhase, !isEndingTurn else { return }

        dice1 = Int.random(in: 1...6)
        dice2 = diceMode == .double ? Int.random(in: 1...6) : 1
        hasRolled = true
        mustRollAgain = false

        switch diceMode {
        case .single:
            handleSingleRoll()
        case .double:
            handleDoubleRoll()
        }
    }

    private func handleSingleRoll() {
        if dice1 == 1 {
            roundMessage = "🐷 \(currentPlayer.name) 丟到 1！本回合分數歸零！"
            currentRoundScore = 0
            hasRolled = true
            Task { @MainActor in
                isEndingTurn = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isEndingTurn = false
                endTurn()
            }
        } else {
            currentRoundScore += dice1
            roundMessage = "\(currentPlayer.name) 丟出 \(dice1)，本回合累積：\(currentRoundScore)"
            // ✅ 只有真人骰完才觸發電腦
            if currentPlayer.isHuman {
                triggerComputerIfNeeded()
            }
        }
    }

    // ✅ 修改 handleDoubleRoll()
    private func handleDoubleRoll() {
        let d1 = dice1, d2 = dice2

        if d1 == 1 && d2 == 1 {
            roundMessage = "💥 \(currentPlayer.name) 兩顆都是 1！總分歸零！"
            currentRoundScore = 0
            players[currentPlayerIndex].totalScore = 0
            hasRolled = true
            Task { @MainActor in
                isEndingTurn = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isEndingTurn = false
                endTurn()
            }
        } else if d1 == 1 || d2 == 1 {
            roundMessage = "🐷 \(currentPlayer.name) 有一顆是 1！本回合分數歸零！"
            currentRoundScore = 0
            hasRolled = true
            Task { @MainActor in
                isEndingTurn = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isEndingTurn = false
                endTurn()
            }
        } else if d1 == d2 {
            currentRoundScore += d1 + d2
            mustRollAgain = true
            roundMessage = "🎲 \(d1) + \(d2)！點數相同，必須再丟！累積：\(currentRoundScore)"
            // ✅ 只有真人骰完才觸發電腦
            if currentPlayer.isHuman {
                triggerComputerIfNeeded()
            }
        } else {
            currentRoundScore += d1 + d2
            roundMessage = "\(currentPlayer.name) 丟出 \(d1)+\(d2)=\(d1+d2)，累積：\(currentRoundScore)"
            // ✅ 只有真人骰完才觸發電腦
            if currentPlayer.isHuman {
                triggerComputerIfNeeded()
            }
        }
    }

    // MARK: - Hold

    func hold() {
        guard case .playing = gamePhase, hasRolled, !mustRollAgain, !isEndingTurn else { return }
        players[currentPlayerIndex].totalScore += currentRoundScore

        if players[currentPlayerIndex].totalScore >= 50 {
            endGame(winnerIndex: currentPlayerIndex)
        } else {
            roundMessage = "\(currentPlayer.name) Hold，獲得 \(currentRoundScore) 分！"
            endTurn()
        }
    }

    // MARK: - Turn Management

    private func endTurn() {
        currentRoundScore = 0
        hasRolled = false
        mustRollAgain = false
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        roundMessage += "\n輪到 \(players[currentPlayerIndex].name)"

        currentComputerTask?.cancel()
        currentComputerTask = nil

        // ✅ 只有下一位是真人時才重置，下一位是電腦交給 triggerComputerIfNeeded 處理
        if players[currentPlayerIndex].isHuman {
            isComputerThinking = false
        }

        triggerComputerIfNeeded()
    }

    private func endGame(winnerIndex: Int) {
        // ✅ 取消電腦 Task
        currentComputerTask?.cancel()
        currentComputerTask = nil
        isComputerThinking = false

        players[winnerIndex].wins += 1
        for i in players.indices where i != winnerIndex {
            players[i].losses += 1
        }
        gamePhase = .gameOver(winner: winnerIndex)
    }

    // MARK: - Replay

    func replay() {
        // ✅ 取消電腦 Task
        currentComputerTask?.cancel()
        currentComputerTask = nil
        isComputerThinking = false

        let savedStats = players.map {
            (name: $0.name, wins: $0.wins, losses: $0.losses, isHuman: $0.isHuman)
        }
        players = savedStats.enumerated().map { (i, p) in
            var newPlayer = Player(id: i, name: p.name, isHuman: p.isHuman)
            newPlayer.wins = p.wins
            newPlayer.losses = p.losses
            return newPlayer
        }
        resetRound()
        gamePhase = .playing
    }

    private func resetRound() {
        currentPlayerIndex = 0
        currentRoundScore = 0
        dice1 = 1
        dice2 = 1
        hasRolled = false
        mustRollAgain = false
        isEndingTurn = false
        roundMessage = players.isEmpty ? "" : "輪到 \(players[0].name)"
    }

    // MARK: - Computer AI

    private func triggerComputerIfNeeded() {
        guard case .playing = gamePhase,
              !currentPlayer.isHuman else { return }

        // ✅ 取消舊的 Task，再啟動新的
        currentComputerTask?.cancel()
        isComputerThinking = true
        currentComputerTask = Task { @MainActor in
            await computerTakeTurn()
        }
    }

    private func computerTakeTurn() async {
        while true {
            guard case .playing = gamePhase,
                  !currentPlayer.isHuman else {
                if !Task.isCancelled { isComputerThinking = false }
                return
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if Task.isCancelled { return }

            guard case .playing = gamePhase,
                  !currentPlayer.isHuman else {
                if !Task.isCancelled { isComputerThinking = false }
                return
            }

            if mustRollAgain || currentRoundScore < 10 {
                roll()

                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if Task.isCancelled { return }

                while isEndingTurn {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    if Task.isCancelled { return }
                }

                if currentPlayer.isHuman {
                    if !Task.isCancelled { isComputerThinking = false }
                    return
                }

            } else {
                hold()
                if Task.isCancelled { return }
                return
            }
        }
    }
}
