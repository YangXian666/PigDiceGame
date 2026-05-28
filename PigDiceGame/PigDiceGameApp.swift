//
//  PigDiceGameApp.swift
//  PigDiceGame
//
//  Created by 114-2Workshop14 on 2026/5/28.
//

import SwiftUI

@main
struct PigDiceGameApp: App {
    @StateObject var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            MenuView(vm: vm)
        }
    }
}
