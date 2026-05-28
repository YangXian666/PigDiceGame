import SwiftUI

struct MenuView: View {
    @ObservedObject var vm: GameViewModel

    // Game configuration
    @State private var selectedGameMode: GameMode = .vsPlayer
    @State private var selectedDiceMode: DiceMode = .single
    @State private var playerNames: [String] = Array(repeating: "", count: 6)

    // Player counts
    @State private var humanCount: Int = 2
    @State private var computerCount: Int = 1

    private let maxHuman = 6
    private let maxComputer = 5

    var totalPlayers: Int {
        humanCount + (selectedGameMode == .vsComputer ? computerCount : 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.7, green: 0.7, blue: 0.1),
                        Color(red: 0.3, green: 0.4, blue: 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("🐷 小豬骰子")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                            .padding(.top, 32)

                        // Game mode
                        sectionCard(title: "遊戲模式") {
                            Picker("", selection: $selectedGameMode) {
                                Text("👥 真人同機").tag(GameMode.vsPlayer)
                                Text("🤖 vs 電腦").tag(GameMode.vsComputer)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Dice mode
                        sectionCard(title: "骰子數量") {
                            Picker("", selection: $selectedDiceMode) {
                                Text("🎲 單顆骰子").tag(DiceMode.single)
                                Text("🎲🎲 雙顆骰子").tag(DiceMode.double)
                            }
                            .pickerStyle(.segmented)

                            if selectedDiceMode == .double {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• 一顆為 1：回合分歸零，換人")
                                    Text("• 兩顆都是 1：總分歸零，換人")
                                    Text("• 兩顆相同（非1）：強制再丟")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            }
                        }

                        // Human player count
                        sectionCard(title: "真人玩家數量") {
                            HStack {
                                Text("\(humanCount) 位")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 60)
                                Stepper("", value: $humanCount, in: 1...maxHuman)
                                    .labelsHidden()
                            }
                        }

                        // Computer player count (only for vsComputer)
                        if selectedGameMode == .vsComputer {
                            sectionCard(title: "電腦玩家數量") {
                                HStack {
                                    Text("\(computerCount) 位")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                        .frame(width: 60)
                                    Stepper("", value: $computerCount, in: 1...maxComputer)
                                        .labelsHidden()
                                }
                                Text("共 \(totalPlayers) 位玩家")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Player names (only show fields for human players)
                        sectionCard(title: "玩家名稱") {
                            VStack(spacing: 10) {
                                ForEach(0..<humanCount, id: \.self) { i in
                                    HStack {
                                        Text("玩家 \(i+1)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .frame(width: 60, alignment: .leading)
                                        TextField("玩家 \(i+1)", text: $playerNames[i])
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }

                        // Start button
                        NavigationLink(destination: GameView(vm: vm)) {
                            Text("開始遊戲")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(totalPlayers >= 2 ? Color.orange : Color.gray)
                                .cornerRadius(14)
                        }
                        .disabled(totalPlayers < 2)
                        .simultaneousGesture(TapGesture().onEnded {
                            guard totalPlayers >= 2 else { return }
                            let names = (0..<humanCount).map { i in
                                playerNames[i].isEmpty ? "玩家 \(i+1)" : playerNames[i]
                            }
                            vm.setupGame(
                                mode: selectedGameMode,
                                diceMode: selectedDiceMode,
                                playerNames: names,
                                computerCount: selectedGameMode == .vsComputer ? computerCount : 0
                            )
                        })
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            content()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    MenuView(vm: GameViewModel())
}
