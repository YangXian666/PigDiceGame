import SwiftUI

struct WinnerView: View {
    @ObservedObject var vm: GameViewModel
    let winnerIndex: Int
    @Environment(\.dismiss) var dismiss

    var sortedPlayers: [Player] {
        vm.players.sorted { $0.totalScore > $1.totalScore }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🎉 遊戲結束！")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("\(vm.players[winnerIndex].name) 獲勝！")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(.yellow)

                // 多人排名列表
                VStack(spacing: 8) {
                    Text("最終排名")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { rank, player in
                        HStack {
                            Text(rankEmoji(rank + 1))
                                .font(.title3)
                                .frame(width: 36)

                            HStack(spacing: 4) {
                                if !player.isHuman {
                                    Image(systemName: "cpu")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                                Text(player.name)
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(player.id == winnerIndex ? .yellow : .white)

                            Spacer()

                            Text("\(player.totalScore) 分")
                                .font(.subheadline.bold())
                                .foregroundColor(player.id == winnerIndex ? .yellow : .white.opacity(0.8))

                            Text("\(player.wins)勝\(player.losses)敗")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(player.id == winnerIndex
                                    ? Color.yellow.opacity(0.15)
                                    : Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(14)

                HStack(spacing: 16) {
                    Button("再玩一次") { vm.replay() }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)

                    Button("回主選單") { dismiss() }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
            .padding(16)
        }
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
}

#Preview {
    let vm = GameViewModel()
    vm.setupGame(
        mode: .vsPlayer,
        diceMode: .single,
        playerNames: ["Peter", "Mary", "John"],
        computerCount: 0
    )
    vm.players[0].totalScore = 102
    vm.players[0].wins = 3
    vm.players[0].losses = 2
    vm.players[1].totalScore = 87
    vm.players[1].wins = 2
    vm.players[1].losses = 3
    vm.players[2].totalScore = 65
    vm.players[2].wins = 1
    vm.players[2].losses = 4
    return WinnerView(vm: vm, winnerIndex: 0)
}
