# 🐷 小豬骰子

以 SwiftUI 開發的多人骰子遊戲，支援最多 6 位真人玩家與 5 位電腦玩家在同一台 iPhone 上對戰。

---

## 📱 介面

<img width="253" height="525" alt="image" src="https://github.com/user-attachments/assets/0822d52c-8bb3-4924-b887-67c2ac18ecf5" />
<img width="250" height="521" alt="image" src="https://github.com/user-attachments/assets/4dc0e703-f6fa-494c-bc71-9147be9932c2" />


---

## 🎮 功能特色

- **多人同機對戰** — 2 至 6 位真人玩家在同一台 iPhone 輪流操作
- **人機對戰模式** — 可混入最多 5 位電腦玩家一起對戰
- **單顆 / 雙顆骰子模式** — 兩種規則帶來不同難度與策略
- **累積戰績紀錄** — 勝敗場次跨局保留，長期較勁
- **終局排名顯示** — 遊戲結束後以 🥇🥈🥉 排行榜呈現最終名次
- **骰子動態繪製** — 以 `GeometryReader` 動態計算點數位置，還原實體骰子外觀
- **漸層視覺設計** — 自訂背景漸層搭配 `.ultraThinMaterial` 毛玻璃卡片效果

---

## 🎲 遊戲規則

### 單顆骰子
| 結果 | 效果 |
|------|------|
| 骰出 1 | 本回合分數歸零，換下一位玩家 |
| 骰出 2–6 | 點數加入本回合累積分數 |
| Hold | 本回合累積分數加入總分 |

### 雙顆骰子
| 結果 | 效果 |
|------|------|
| 一顆為 1 | 本回合分數歸零，換下一位玩家 |
| 兩顆都是 1 | **總分歸零**，換下一位玩家 |
| 兩顆相同（非 1）| **強制繼續擲骰**，無法 Hold |
| Hold | 本回合累積分數加入總分 |

**先累積到 50 分的玩家獲勝。**

---

## 🤖 電腦 AI 策略

電腦採用固定閾值策略：**回合累積分數超過 10 分即選擇 Hold**，否則繼續擲骰。每個動作間隔 1.5 秒，讓真人玩家能清楚觀察每一步。

---

## 🏗 程式碼架構

專案採用 **MVVM** 架構，分為 5 個 Swift 檔案：

```
PigDiceGame/
├── Models/
│   └── GameModel.swift         # 資料型別：Player、GameMode、DiceMode、GamePhase
├── ViewModels/
│   └── GameViewModel.swift     # 遊戲邏輯、AI 控制、回合管理
└── Views/
    ├── MenuView.swift           # 模式選擇、玩家設定
    ├── GameView.swift           # 遊戲主畫面
    └── WinnerView.swift         # 結局排名畫面
```

---

## 🔧 技術亮點

| 技術 | 應用場景 |
|------|----------|
| `SwiftUI` | 全部畫面層 |
| `MVVM` | 清楚分離資料、邏輯與畫面 |
| `@Published` + `ObservableObject` | 狀態變更自動驅動畫面更新 |
| `async/await` + `Task` | 電腦 AI 回合非同步控制 |
| `Task.isCancelled` | 防止舊 Task 在換人後污染新 Task 的狀態 |
| `currentComputerTask` | 追蹤並取消前一個 AI Task，確保同時只有一個電腦在運作 |
| `GeometryReader` | 骰子點數動態定位 / 畫面固定比例分割 |
| `LinearGradient` | 主選單與遊戲畫面自訂漸層背景 |
| `.ultraThinMaterial` | 毛玻璃效果卡片與標題列 |
| `LazyVGrid` | 5 人以上自動切換分數板兩欄排版 |
| `ScrollView` + `.defaultScrollAnchor(.top)` | 分數板支援多人捲動且從頂部對齊 |
| 自訂 Navigation Bar | 避免系統標題列在多人時遮擋分數板 |

---


## 🚀 執行方式

1. Clone 專案
   ```bash
   git clone https://github.com/YangXian666/PigDiceGame.git
   ```
2. 用 Xcode 開啟 `PigDiceGame.xcodeproj`
3. 選擇模擬器或實體裝置（iOS 16 以上）
4. 按下 `Command + R` 編譯並執行

---

## 📋 開發環境需求

- Xcode 15+
- iOS 16+
- Swift 5.9+
