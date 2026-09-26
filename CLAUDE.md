# claude-code-cheatsheet-zh — 同步維運指南

> 此專案為 [cc.storyfox.cz](https://cc.storyfox.cz/) 的繁體中文翻譯版。
> 每當原站更新版本，我們要同步翻譯、發 Release、關掉追蹤 issue。
> 這份文件是給**未來的 Claude 或雷蒙**讀的 SOP — 讓任何一次 session 都能獨立完成同步。

---

## 架構速覽

```
├── index.html              ← 繁中版完整 cheat sheet（滿版客製設計，非 A4）
├── README.md               ← 版本號 / 更新日期寫在這（check-upstream.sh 讀這份）
├── assets/preview.png      ← README 封面截圖
├── scripts/
│   ├── check-upstream.sh   ← 比對 upstream vs README 版本（退出碼觸發後續）；diff 用基準檔算
│   ├── sync-upstream.md    ← 翻譯同步 SOP（Claude 讀這份執行）
│   └── upstream-baseline.html ← 上次同步時的上游原檔（進 git）；下一輪 diff「基準檔 vs 新上游」
└── .github/workflows/
    ├── check-upstream.yml  ← GitHub Actions：每日 00:00 CST，有新版→開 issue
    └── auto-release.yml    ← push 後偵測 README 版本號→發 Release
```

## 自動化的三段式流程

| 階段 | 觸發 | 做什麼 | 誰做 |
|:--|:--|:--|:--|
| 1. 偵測 | GitHub Actions `check-upstream.yml` 每日 00:00 CST | upstream 版本 ≠ README 版本 → 開 `upstream-update` label 的 issue | GitHub |
| 2. 翻譯 | Mac mini scheduled-task 每週一 08:00 CST | 跑 `scripts/check-upstream.sh`；exit 1 → Claude 讀 `scripts/sync-upstream.md` 執行翻譯 → commit push | Claude + 本機 |
| 3. 發 Release | push 到 master 後 | `auto-release.yml` 讀 README 版本號 → 建 tag + Release | GitHub |

發 Release 後 Claude 要手動**關閉對應的 `upstream-update` issues**（`gh issue close`）。

## 手動觸發同步

任何時候想立刻同步：

```bash
cd ~/Projects/claude-code-cheatsheet-zh
bash scripts/check-upstream.sh
# exit 0 → 無需動作
# exit 1 → 讀 scripts/sync-upstream.md 執行翻譯
```

遇到 exit 1 時，Claude 應**直接讀 `scripts/sync-upstream.md`** 按步驟跑完，不要反問用戶「要我做嗎」。

## 翻譯風格（core）

- `<code>` / `<kbd>` / 指令 / 旗標 / env var 名稱**一律保留原文**
- 說明文字繁中化，語氣參考現有 `index.html` 的其他條目
- 專有對照：
  - Keyboard Shortcuts → 鍵盤快捷鍵
  - Slash Commands → 斜線指令
  - Memory Files → 記憶檔案
  - Environment Variables → 環境變數
  - Skills & Agents → Skills 與 Agents
  - prompt caching → prompt caching（不翻）
- `data-added="YYYY-MM-DD"` 照抄 upstream（控制 NEW badge 的 8 天自動隱藏）

## 刻意不跟進 upstream 的差異

採增量同步：本地保留上游已刪的條目（雷蒙 2026-09-26 拍板），所以例行 diff 比的是「上游基準檔 vs 新上游」，不是上游 vs 本地。以下是雷蒙版的客製，直接對照上游與本地時會出現，**不要還原**：

| 項目 | 本地 | 原站 |
|:--|:--|:--|
| 佈局 | 滿版設計（`max-width: 1800px`） | A4 橫印（`max-width: 279mm`） |
| 版面單位 | `px` | `mm` |
| 字型 | `'Inter', 'Noto Sans TC'` | `'Inter'` |
| `@page` 列印設定 | 無 | `A4 landscape` |
| `.header-left/right/buttons/btn` | 有（雷蒙獨有的 header 按鈕） | 無 |
| `lang` | `zh-Hant` | `en` |
| `<title>` / meta / OG / Twitter | 全中文 + 雷蒙三十署名 | 英文 + Martin Baláž |
| `canonical` / `hreflang` | 不加 | 指向 cc.storyfox.cz |
| favicon PNG | 只用 emoji SVG | 另引 `/favicon.png` |
| 近期更新 | 只留最新 5 條＋「看完整更新紀錄 →」連結（2026-09-26） | 保留十幾條 |
| 設定與環境 | 兩層：常用項直接顯示（含繁中版補的 `permissions`、`model`、`env` 等），其餘收進 `<details class="more">`（2026-09-26） | 全部平鋪 |
| 手機排版（`max-width: 700px` 內） | 長 `.key`／說明可斷行、grid 子項 `min-width: 0`、近期更新一條一行（2026-09-26，手機頁寬 946→375px） | 無，長 key 會把整頁撐寬 |

## 故障排查

| 現象 | 處理 |
|:--|:--|
| `scripts/check-upstream.sh` 回 exit 2 | 原站抓不到 → 檢查網路；原站掛掉就略過本輪 |
| `auto-release.yml` 沒發 Release | 看 `gh run list --workflow=auto-release.yml`；通常是 tag 已存在 |
| `check-upstream.yml` 重複開同版本 issue | 已內建 `gh issue list --label upstream-update` 去重，不會重開 |
| Release 發了但 GitHub Pages 沒更新 | 等 `pages-build-deployment` workflow 跑完（~30 秒） |
| 翻譯後 CSS 排版破掉 | `diff` 看是否動到 `<style>`；繁中版的客製 CSS 不應被覆寫 |

## 誰維護

- **代碼 / 翻譯**：雷蒙（raymondhou0917）+ Claude Code
- **原站**：[@phasE89](https://x.com/phasE89)（Martin Baláž）
- **部署**：GitHub Pages（`https://raymondhou0917.github.io/claude-code-cheatsheet-zh/`）

## 絕對不做

- **不**從頭抓 upstream 整份覆蓋 `index.html`（會丟失繁中翻譯與版面客製）
- **不**建新 branch / PR（直接 push master，Release 靠 tag 觸發）
- **不**翻譯 `<code>` / `<kbd>` 裡的指令、旗標、env var 名稱
- **不**加中文註解到 HTML/JS 區塊（保留原站結構便於下次 diff）
- **不**改動「刻意不跟進」表格裡那些雷蒙版客製
