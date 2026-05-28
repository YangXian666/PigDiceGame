import SwiftUI

struct GameView: View {
    @ObservedObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.9, green: 0.9, blue: 0.9),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("返回")
                            }
                            .foregroundColor(.primary)
                        }
                        Spacer()
                        Text("小豬骰子 🐷").font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .foregroundColor(.clear)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)

                    // 分數板 ── 佔畫面 40%
                    ScoreBoard(vm: vm)
                        .frame(height: geo.size.height * 0.40)

                    Divider()

                    // 回合分數 ── 佔畫面 10%
                    RoundInfoView(vm: vm)
                        .frame(height: geo.size.height * 0.10)

                    Divider()

                    // 骰子 ── 佔畫面 20%
                    DiceView(vm: vm)
                        .frame(height: geo.size.height * 0.20)

                    // 訊息 ── 佔畫面 10%
                    Text(vm.roundMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .frame(height: geo.size.height * 0.10)

                    // 按鈕 ── 佔畫面 10%
                    ActionButtons(vm: vm)
                        .frame(height: geo.size.height * 0.10)
                        .padding(.bottom, 10)
                }

                if case .gameOver(let winner) = vm.gamePhase {
                    WinnerView(vm: vm, winnerIndex: winner)
                }

                if vm.isComputerThinking {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                            Text("電腦思考中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
// MARK: - Score Board

struct ScoreBoard: View {
    @ObservedObject var vm: GameViewModel

    var useListLayout: Bool { vm.players.count > 4 }

    var body: some View {
        ScrollView {
            if useListLayout {
                listLayout
            } else {
                gridLayout
            }
        }
        .defaultScrollAnchor(.top)
    }

    var scoreboardMaxHeight: CGFloat {
        switch vm.players.count {
        case 1...4:  return 120   // 橫排一行夠用
        case 5...8:  return 200   // 兩欄兩行
        default:     return 280   // 超過 8 人才需要捲動
        }
    }

    var gridLayout: some View {
        HStack(spacing: 0) {
            ForEach(vm.players.indices, id: \.self) { i in
                playerCell(i: i)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var listLayout: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
            ForEach(vm.players.indices, id: \.self) { i in
                playerCell(i: i)
            }
        }
    }

    @ViewBuilder
    func playerCell(i: Int) -> some View {
        let player = vm.players[i]
        let isActive = vm.currentPlayerIndex == i

        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if !player.isHuman {
                    Image(systemName: "cpu")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
                Text(player.name)
                    .font(vm.players.count > 4 ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .orange : .primary)
                    .lineLimit(1)
            }

            Text("\(player.totalScore)")
                .font(vm.players.count > 4
                      ? .system(size: 28, weight: .bold)
                      : .system(size: 36, weight: .bold))
                .foregroundColor(isActive ? .orange : .primary)

            Text("\(player.wins)勝\(player.losses)敗")
                .font(.caption2)
                .foregroundColor(.secondary)

            if isActive {
                Text("▲ 目前")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Text(" ").font(.caption2)
            }
        }
        .padding(.vertical, 8)
        .background(isActive ? Color.orange.opacity(0.08) : Color.clear)
    }
}

// MARK: - Round Info

struct RoundInfoView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("本回合分數")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(vm.currentRoundScore)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)
            }
            Spacer()
            if vm.mustRollAgain {
                Label("必須再丟！", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Dice View

struct DiceView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(spacing: 24) {
            DieFaceView(value: vm.dice1, show: vm.hasRolled)
            if vm.diceMode == .double {
                DieFaceView(value: vm.dice2, show: vm.hasRolled)
            }
        }
        .padding(.vertical, 20)
    }
}

struct DieFaceView: View {
    let value: Int
    let show: Bool

    var dotPositions: [(x: CGFloat, y: CGFloat)] {
        switch value {
        case 1: return [(0.5, 0.5)]
        case 2: return [(0.25, 0.25), (0.75, 0.75)]
        case 3: return [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)]
        case 4: return [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)]
        case 5: return [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)]
        case 6: return [(0.25, 0.2), (0.75, 0.2), (0.25, 0.5), (0.75, 0.5), (0.25, 0.8), (0.75, 0.8)]
        default: return []
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(show ? Color.white : Color(.systemGray5))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            if show {
                GeometryReader { geo in
                    ForEach(dotPositions.indices, id: \.self) { i in
                        let pos = dotPositions[i]
                        Circle()
                            .fill(value == 1 ? Color.red : Color.black)
                            .frame(width: 12, height: 12)
                            .position(x: geo.size.width * pos.x, y: geo.size.height * pos.y)
                    }
                }
            } else {
                Text("?")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 90, height: 90)
    }
}

// MARK: - Action Buttons

struct ActionButtons: View {
    @ObservedObject var vm: GameViewModel

    var canHold: Bool {
        guard case .playing = vm.gamePhase else { return false }
        return vm.hasRolled && !vm.mustRollAgain && vm.currentPlayer.isHuman
            && !vm.isComputerThinking && !vm.isEndingTurn
    }

    var canRoll: Bool {
        guard case .playing = vm.gamePhase else { return false }
        return vm.currentPlayer.isHuman
            && !vm.isComputerThinking && !vm.isEndingTurn
    }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                vm.roll()
            } label: {
                Label("Roll", systemImage: "dice.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canRoll ? Color.blue : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!canRoll)

            Button {
                vm.hold()
            } label: {
                Label("Hold", systemImage: "hand.raised.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canHold ? Color.orange : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!canHold)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview 

#Preview("兩人對戰") {
    let vm = GameViewModel()
    vm.setupGame(
        mode: .vsPlayer,
        diceMode: .single,
        playerNames: ["Peter", "Mary"],
        computerCount: 0
    )
    return GameView(vm: vm)
}

#Preview("四人對戰") {
    let vm = GameViewModel()
    vm.setupGame(
        mode: .vsPlayer,
        diceMode: .single,
        playerNames: ["Peter", "Mary", "John", "Amy"],
        computerCount: 0
    )
    return GameView(vm: vm)
}

#Preview("六人對戰") {
    let vm = GameViewModel()
    vm.setupGame(
        mode: .vsPlayer,
        diceMode: .double,
        playerNames: ["Peter", "Mary", "John", "Amy", "Bob", "Lisa"],
        computerCount: 0
    )
    return GameView(vm: vm)
}

#Preview("人機對戰") {
    let vm = GameViewModel()
    vm.setupGame(
        mode: .vsComputer,
        diceMode: .single,
        playerNames: ["Peter"],
        computerCount: 2
    )
    return GameView(vm: vm)
}
