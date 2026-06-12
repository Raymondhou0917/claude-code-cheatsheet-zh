# Claude Code 中文速查表（claude-code-cheatsheet-zh）開發計畫

> 最後更新：2026-06-12
> 專案狀態：已上線 GitHub Pages、自動同步管線運作中，目前對齊 Claude Code v2.1.170，維護模式只需跟進 upstream 新版

---

## Phase 0：繁中版初版上線（2026-04 初）✅

- [x] 翻譯 [cc.storyfox.cz](https://cc.storyfox.cz/) 為繁體中文滿版網頁（`index.html`）
- [x] GitHub Pages 部署 + README 版本對齊資訊
- [x] 雷蒙版客製：滿版設計（1800px）、Noto Sans TC 字型、Mac/Windows 快捷鍵切換、NEW 標籤 8 天自動隱藏

**重要發現**：
- 繁中版有一批**刻意不跟進 upstream 的客製**（版面、字型、meta、header 按鈕），每次 diff 都會出現，不要還原（清單見 `CLAUDE.md`）

---

## Phase 1：三段式自動同步管線（2026-04 ～ 2026-05）✅

- [x] `check-upstream.yml`（GitHub Actions 每日 00:00 CST）：upstream 版本 ≠ README 版本 → 開 `upstream-update` issue
- [x] Mac mini scheduled-task（每週一 08:00 CST）：跑 `scripts/check-upstream.sh`，exit 1 → Claude 讀 `scripts/sync-upstream.md` 執行翻譯
- [x] `auto-release.yml`：push 後讀 README 版本號自動建 tag + Release
- [x] FEATURES.md：30+ 功能的情境導向應用指南（補「懂」的那一份，速查表負責「查」）

**重要發現**：
- 同步翻譯**絕不**整份覆蓋 `index.html`（會丟失繁中翻譯與版面客製），一律 diff 增量翻譯
- `<code>` / `<kbd>` / 指令 / 旗標 / env var 名稱一律保留原文

---

## Phase 2：維護模式（進行中）

- [ ] 跟進 upstream 新版本翻譯同步（自動化觸發，Release 後手動關閉對應 `upstream-update` issue）
- [ ] 視 Claude Code 大版本更新擴充 FEATURES.md

---

## 技術備註

- 語言 / 框架：純靜態 HTML/CSS/JS 單頁（`index.html`），無建置流程；自動化用 Bash + GitHub Actions
- 啟動：直接瀏覽器開 `index.html` 即可預覽，無本地伺服器需求
- 手動同步：`bash scripts/check-upstream.sh`（exit 0 = 無需動作；exit 1 = 讀 `scripts/sync-upstream.md` 執行翻譯；exit 2 = 原站抓不到，略過本輪）
- 測試：無自動化測試，靠人工 diff 檢查翻譯後 CSS 排版
- 部署：GitHub Pages，正式 URL `https://raymondhou0917.github.io/claude-code-cheatsheet-zh/`；push master 後 `pages-build-deployment` 自動更新（~30 秒）
- 注意：此專案是少數**不部署在 Zeabur** 的例外（純靜態 + GitHub 原生託管）

## 關聯文件

- `CLAUDE.md`：同步維運 SOP 總覽（架構、三段式流程、翻譯風格、故障排查、紅線）
- `scripts/sync-upstream.md`：翻譯同步逐步 SOP
- `FEATURES.md`：功能應用情境指南
