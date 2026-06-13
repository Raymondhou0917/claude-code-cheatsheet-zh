# Codex 功能應用情境指南（繁體中文）

> 這份文檔回答的是「**Codex 現在能在哪裡用？我什麼時候該用哪個入口或功能？**」——適合剛開始用 Codex、還不確定 App / CLI / IDE / Web / GitHub review 怎麼分工的人。
>
> 如果 `FEATURES.md` 是 Claude Code 的功能地圖，這份就是 Codex 版的應用情境指南。

| 項目 | 內容 |
|:--|:--|
| 對齊版本 | Codex CLI `0.128.0`（本機實測）＋ OpenAI Codex 官方文件（2026-06） |
| 最後更新 | 2026-06-13 |
| 更新頻率 | 約一個月一次，或 Codex App / CLI / Web / GitHub review 有明顯改版時更新 |
| 官方文件 | [developers.openai.com/codex](https://developers.openai.com/codex) |

> [!IMPORTANT]
> **第一輪閱讀建議**：先看「先選入口」與「新手選擇速查」。Codex 現在不是單一工具，而是一組入口：App、CLI、IDE Extension、Web / Cloud、GitHub review。先選入口，後面功能才不會混在一起。

> [!TIP]
> **怎麼用這份指南**：先看「我現在想做什麼」，再選入口。Codex 不是只有 CLI；現在更像一組軟體工程代理入口：App、CLI、IDE Extension、Web、GitHub review、MCP、Skills、Subagents、Automations。

---

## 目錄

1. [先選入口：App / CLI / IDE / Web / GitHub](#1-先選入口app--cli--ide--web--github)
2. [本機實作與驗證](#2-本機實作與驗證)
3. [背景任務與並行工作](#3-背景任務與並行工作)
4. [程式碼品質與安全把關](#4-程式碼品質與安全把關)
5. [視覺、非程式碼與桌面操作](#5-視覺非程式碼與桌面操作)
6. [擴充、記憶與團隊工作流](#6-擴充記憶與團隊工作流)

---

## 1. 先選入口：App / CLI / IDE / Web / GitHub

**先搞懂這幾個入口的分工**：

| 入口 | 一句話 | 最適合 |
|:--|:--|:--|
| Codex App | 桌面版指揮中心 | 多專案、多 thread、看 diff、開 worktree、做海報/文件等 artifact |
| Codex CLI | 終端機代理 | 本機 repo 內快速讀檔、改碼、跑測試、腳本化 |
| IDE Extension | 編輯器旁協作 | 你正在看某些檔案、選取程式碼，想讓 Codex 直接接住上下文 |
| Codex Web / Cloud | 雲端委派 | 把 GitHub repo 任務丟到雲端背景跑，讓它開 PR |
| GitHub `@codex` | PR / issue 裡叫人 | 在 GitHub 上請 Codex review、修 CI、補測試 |

> [!NOTE]
> **入口不是能力高低，而是工作場景不同**：本機狀態很重要，用 App Local / CLI；正在編輯器裡改，用 IDE Extension；任務清楚、可丟雲端，用 Web / Cloud；PR 已經開出來，用 GitHub `@codex`。

### Codex App — 桌面版工作台

**它做什麼**：一個專門跑 Codex threads 的桌面工作台。可以管理多個 project、在 Local / Worktree / Cloud 模式間切換、看 diff、commit、push、開 PR，也能產出文件、簡報、圖片等非程式碼 artifacts。

**什麼時候用**：
- 你要同時跑幾個任務，但不想開一堆終端機。
- 你想一邊看 diff、一邊留言叫 Codex 修改。
- 你要做含圖片、簡報、PDF、試算表的工作，而不只是改 code。

**別用在**：只想快速問一句或批次腳本化時，CLI 更快。

📖 [Codex App](https://developers.openai.com/codex/app)｜[App features](https://developers.openai.com/codex/app/features)

### Codex CLI — 本機終端機代理

**它做什麼**：在指定資料夾裡讀檔、改碼、執行指令、跑測試，並受 sandbox / approval 控制。也支援圖片輸入、內建 web search、`review`、`cloud`、`mcp`、`plugin`、`exec` 等子命令。

**什麼時候用**：
- 你已經在 repo 裡，想直接叫它修 bug、改檔、跑測試。
- 你要把 Codex 放進腳本或 CI 前置檢查。
- 你偏好終端機可重現流程。

**怎麼用**：互動模式 `codex`；一次性問題 `codex "explain this codebase"`；非互動自動化 `codex exec "fix the CI failure"`。

**別用在**：你想要同時看多個 thread、管理 worktree、拖圖片做海報，App 體驗更好。

📖 [Codex CLI](https://developers.openai.com/codex/cli)｜[CLI features](https://developers.openai.com/codex/cli/features)

### IDE Extension — 在編輯器旁邊改

**它做什麼**：讓 Codex 直接在 VS Code、Cursor、Windsurf 等 VS Code 相容編輯器裡協作。它會吃到你打開的檔案與選取內容，所以 prompt 可以更短。

**什麼時候用**：
- 你正在看某個檔案，想叫 Codex 針對這個上下文改。
- 前端 / app 開發時，你想在 IDE 裡快速問、快速套改。
- 想把任務轉到 cloud 跑，但仍從 IDE 追進度。

**別用在**：需要大範圍多專案調度時，App 比較適合；要腳本化時用 CLI。

📖 [Codex IDE Extension](https://developers.openai.com/codex/ide)｜[IDE features](https://developers.openai.com/codex/ide/features)

### Codex Web / Cloud — 背景雲端代理

**它做什麼**：連 GitHub repo 後，把任務交給 Codex 在雲端環境背景跑。它能讀 repo、改 code、跑環境設定、產出 diff 或 PR。

**什麼時候用**：
- 你不想讓本機長時間跑任務。
- 你要把一個清楚的 issue / refactor / bugfix 丟給 Codex 背景處理。
- 同時開多個雲端任務，最後回來看結果。

**別用在**：需要讀你本機未提交檔案、local-only 憑證、或只能在你電腦上跑的流程。

📖 [Codex Web](https://developers.openai.com/codex/cloud)

### GitHub `@codex` — 在 PR / issue 裡叫 Codex

**它做什麼**：在 GitHub PR 留 `@codex review` 叫 Codex review；也可以在 PR comment 叫它修 CI、補測試、處理 review 發現。可設定自動 review。

**什麼時候用**：
- PR 開出來後，想要另一個高訊號 review pass。
- 想讓 Codex 看 CI 失敗並推修正。
- 團隊希望 merge 前固定有 AI reviewer。

**別用在**：需要本機互動驗證、需要看畫面、或需要你一邊改一邊討論的任務。

📖 [Codex code review in GitHub](https://developers.openai.com/codex/integrations/github)

---

## 2. 本機實作與驗證

### Local mode — 直接在目前專案工作

**它做什麼**：Codex 直接在目前 project directory 讀、改、跑。最接近日常 pair programming。

**什麼時候用**：小到中型改動、你想在同一個 working tree 驗證、或任務需要你當場看結果。

**別用在**：你還有未完成工作，怕 Codex 改到同一份檔案；這時用 Worktree。

### Integrated terminal — 邊改邊跑

**它做什麼**：Codex App 每個 thread 都有內建 terminal，可跑測試、看 dev server、做 git 操作；Codex 也能讀 terminal output，接住錯誤繼續修。

**什麼時候用**：
- 前端改完跑 `pnpm test` / `pnpm run lint`。
- dev server 在跑，讓 Codex 看錯誤輸出。
- 你想在 App 裡完成「改 → 測 → commit」。

📖 [Codex App features - integrated terminal](https://developers.openai.com/codex/app/features)

### Approval modes / Sandbox — 控制它能動到哪裡

**它做什麼**：Sandbox 決定 Codex 技術上能讀寫哪些位置、能不能連網；approval 決定何時需要停下來問你。預設適合一般本機開發：在工作資料夾內能讀、改、跑，跨出邊界或用網路會問。

**什麼時候用**：
- 想先討論不改檔 → Read-only / Chat。
- 想讓它在 repo 內順暢改 → Auto / Agent。
- 很確定任務安全、需要網路或跨資料夾 → Full Access，但要謹慎。

> [!CAUTION]
> **Full Access 不是日常預設**：不信任的 repo、會碰密碼金鑰、會操作生產資料時，不要開 Full Access。先用較窄的 sandbox，真的需要跨資料夾或連網時再放寬。

📖 [Agent approvals & security](https://developers.openai.com/codex/agent-approvals-security)

---

## 3. 背景任務與並行工作

> [!IMPORTANT]
> **先判斷任務需不需要本機狀態**：需要本機未提交檔案、登入態、dev server、GUI、私有憑證，就留在 Local / Worktree。任務只依賴 GitHub repo 與清楚指示，才適合交給 Cloud。

### Worktree — 讓 Codex 在旁邊開分身工作區

**它做什麼**：Codex App 用 Git worktree 幫你開另一份 checkout，讓 Codex 在背景改，不干擾你正在用的 Local checkout。完成後可 handoff 回 Local，或直接從 worktree 建 branch / PR。

**什麼時候用**：
- 想讓 Codex 試新功能，但你本機還在做別的事。
- 同一個 repo 裡要平行跑兩個互不干擾的任務。
- 想把 Codex 工作和自己的 working tree 隔離。

**別用在**：不是 Git repo 的資料夾；或任務依賴 `.gitignore` 裡的本機檔案但沒有 setup script。

📖 [Worktrees](https://developers.openai.com/codex/app/worktrees)

### Cloud tasks — 丟到雲端跑

**它做什麼**：Codex 在雲端環境跑背景任務。CLI 可用 `codex cloud` 查看、提交、套用雲端任務結果；IDE / Web 也可委派。

**什麼時候用**：
- 長任務、需要乾淨環境、希望它自己開 PR。
- 你要同時嘗試幾個方案，可用 attempts 做 best-of-N。
- 不想占用本機或不想保持 dev server 開著。

**別用在**：任務依賴本機未提交檔、私人登入態、或只能在你電腦跑的 GUI。

📖 [Codex Web](https://developers.openai.com/codex/cloud)｜[CLI cloud](https://developers.openai.com/codex/cli/features)

### Automations — 定期背景檢查

**它做什麼**：在 Codex App 排 recurring tasks。它會把發現放進 inbox；沒事則自動封存。專案型 automation 需要本機 Codex App 開著、機器有開機、專案還在磁碟上。

**什麼時候用**：
- 每天掃 telemetry errors，發現問題就開 thread 修。
- 每週整理 changelog、檢查過期文件。
- 例行跑 repo 健檢。

**別用在**：你需要電腦關機也跑的工作；目前 project-scoped automation 仍依賴本機 App 與磁碟。

📖 [Automations](https://developers.openai.com/codex/app/automations)

### Subagents — 拆給多個小代理並行

**它做什麼**：Codex 可以明確被要求 spawn 多個 subagents，各自查不同面向，最後彙整結果。內建 `worker`、`explorer`、`default`，也可自訂 agent。

**什麼時候用**：
- 大型 PR review：安全、效能、測試、可維護性各派一個 agent。
- 大型 codebase 探索：每個 agent 查一個模組。
- 多假設 debug：讓不同 agent 分別驗證可能根因。

**別用在**：簡單線性任務。Subagents 會增加 token、延遲與本機資源使用。

📖 [Subagents](https://developers.openai.com/codex/subagents)

---

## 4. 程式碼品質與安全把關

> [!TIP]
> **最穩的交付節奏**：本機先跑測試與 lint，再用 `codex review` 或 `/review` 看 diff；PR 開出來後，再用 GitHub `@codex review` 做另一層檢查。安全敏感改動再加 Codex Security。

### `/review` / `codex review` — 本機 code review

**它做什麼**：讀本機 diff，產出高優先級、可行動的 review findings，不直接改你的 working tree。可審 uncommitted changes、base branch diff、或單一 commit。

**什麼時候用**：
- commit 前檢查未提交變更。
- PR 前看和 `main` 的差異。
- 想用自訂指示聚焦：安全、a11y、測試缺口、行為回歸。

**怎麼用**：互動 CLI 用 `/review`；非互動用 `codex review --uncommitted`、`codex review --base main`、`codex review --commit <SHA>`。

📖 [CLI features - local review](https://developers.openai.com/codex/cli/features)

### GitHub code review — PR 上的 teammate

**它做什麼**：在 GitHub PR 上用 `@codex review` 觸發。Codex 會依 repo 的 `AGENTS.md` review guidelines 看 diff，並只標高優先級問題；也可開自動 review。

**什麼時候用**：
- 團隊 merge 前固定多一層 AI review。
- 大型 codebase 想抓 regressions、missing tests、docs issues。
- 想直接在 PR comment 裡叫它 `@codex fix it`。

📖 [GitHub integration](https://developers.openai.com/codex/integrations/github)

### Codex Security — 專門掃安全風險

**它做什麼**：Codex Security plugin 可在 thread 裡做深度安全掃描、diff 安全檢查、修漏洞 backlog；Codex Security cloud 可掃 connected GitHub repositories，建立 repo-specific threat model、降低 false positive、提出修補路徑。

**什麼時候用**：
- auth、payment、data export、admin permission 相關改動。
- 大型 repo 安全盤點。
- 想讓發現帶 evidence 與 patch options。

**別用在**：取代所有人工資安審查。高風險系統仍要人工確認。

📖 [Codex Security](https://developers.openai.com/codex/security)

---

## 5. 視覺、非程式碼與桌面操作

> [!WARNING]
> **畫面操作要縮小範圍**：In-app browser 與 Computer Use 很適合驗證 UI，但不要拿來處理密碼、金鑰、金融操作或高敏感資料。任務描述要窄，讓 Codex 只做必要步驟。

### Image input — 讓 Codex 看截圖 / 設計稿

**它做什麼**：把 PNG / JPEG 截圖、錯誤畫面、設計稿拖進 prompt，讓 Codex 直接讀圖、解釋、對照實作。

**什麼時候用**：
- 貼錯誤截圖問怎麼修。
- 給設計稿，叫它比對前端畫面。
- 給流程圖 / 架構圖，叫它整理成任務。

📖 [CLI features - image inputs](https://developers.openai.com/codex/cli/features)

### Image generation — 生圖 / 改圖

**它做什麼**：在 Codex App / CLI thread 裡直接生成或編輯圖片，內建 image generation 使用 `gpt-image-2`，適合 UI assets、banner、背景、插圖、sprites、placeholder art。

**什麼時候用**：
- 課程配圖、知識圖卡、社群圖、banner。
- 先做 placeholder，再交給設計師精修。
- 拿 reference image 變體化或延伸。

**別用在**：大量批次圖。大量生成建議走 API key，避免吃掉一般 Codex 用量。

📖 [App features - image generation](https://developers.openai.com/codex/app/features)

### In-app browser — 一起看網頁

**它做什麼**：Codex App 裡的共享瀏覽器，可開 local dev server、file preview、公開頁面；你可以在頁面上加 comments，叫 Codex 改。Browser use 則可讓 Codex 點擊、輸入、截圖、驗證頁面。

**什麼時候用**：
- 前端改完要看畫面。
- 你想在某個 UI 元素上留言：「這裡 spacing 太擠」。
- 要讓 Codex 自己點頁面驗證 bug fix。

**別用在**：需要登入態、cookies、extension、既有瀏覽器 profile 的網站；這時用一般瀏覽器或 Chrome extension。

📖 [In-app browser](https://developers.openai.com/codex/app/browser)

### Computer Use — 操作桌面 App

**它做什麼**：讓 Codex 看見並操作 macOS / Windows GUI：點擊、輸入、看視窗、改設定。適合 CLI / API 做不到的桌面流程。

**什麼時候用**：
- 測桌面 App 或 GUI-only bug。
- 操作沒有 API / MCP 的工具。
- 在瀏覽器、模擬器、設定頁重現問題。

**別用在**：高敏感流程、密碼金鑰、金融操作。任務要窄，權限提示要仔細看。

📖 [Computer Use](https://developers.openai.com/codex/app/computer-use)

### Non-code artifacts — 文件、簡報、試算表、PDF

**它做什麼**：Codex App sidebar 可預覽 PDF、spreadsheets、documents、presentations；任務過程也會展示 plan、sources、generated artifacts、summary。

**什麼時候用**：
- 把資料整理成簡報 / 報告 / 試算表。
- 檢查 PDF 或文件格式。
- 需要一邊看產出、一邊要求下一輪修改。

📖 [Codex App features - non-code artifacts](https://developers.openai.com/codex/app/features)

---

## 6. 擴充、記憶與團隊工作流

> [!NOTE]
> **從輕到重的沉澱順序**：先寫 `AGENTS.md` 固定專案規則；重複流程抽成 Skills；需要接外部工具時用 MCP；整套能力穩定後，再包成 Plugins 給團隊重用。

### AGENTS.md / Rules — 專案工作規則

**它做什麼**：把 repo 的開發規範、測試方式、review guidelines 寫成 agent 可讀規則。GitHub review 也會讀 `AGENTS.md`，並依最接近 changed file 的規則套用。

**什麼時候用**：
- 想讓 Codex 每次都知道怎麼跑測試、怎麼寫 commit、哪些檔案不能動。
- 想讓 GitHub `@codex review` 聚焦安全、文件、測試缺口。

📖 [GitHub review guidelines](https://developers.openai.com/codex/integrations/github)

### Skills — 把重複工作流存起來

**它做什麼**：把可複用的專業流程、設計規則、文檔格式、檢查清單包成 skill。Codex App、CLI、IDE Extension 都能用同一套 agent skills。

**什麼時候用**：
- 你第二次貼同一段長 prompt。
- 團隊有固定流程：上架檢查、資安 review、書稿配圖、簡報生成。
- 想讓不同專案共用同一套做法。

📖 [App features - skills support](https://developers.openai.com/codex/app/features)

### MCP — 接外部工具與資料源

**它做什麼**：用 Model Context Protocol 把 Codex 接到外部工具或資料源，例如文件、瀏覽器、Figma、資料庫、內部系統。CLI 與 IDE Extension 共用 MCP 設定，App 也共享相關設定。

**什麼時候用**：
- 一直把某個工具的資料複製貼上給 Codex。
- 想讓 Codex 查文件、讀設計稿、操作內部工具。
- 需要 OAuth 或 bearer token 的遠端 tool server。

**別用在**：不信任的 server；外部資料仍可能帶 prompt injection。

📖 [MCP](https://developers.openai.com/codex/mcp)

### Plugins — 整包擴充

**它做什麼**：把 skills、tools、流程與相關設定打包，讓 Codex 可安裝、可分享。適合團隊或特定領域工作流。

**什麼時候用**：
- 你要把一套能力交給團隊重複使用。
- 單一 skill 不夠，需要工具 + skill + UI / connector。
- 想讓新成員一鍵取得同一套 Codex 能力。

**別用在**：單次任務、還沒穩定的個人 prompt；先沉澱成 skill，再考慮 plugin。

### Config profiles / Hooks — 固定偏好與自動化

**它做什麼**：`~/.codex/config.toml` 和專案 `.codex/config.toml` 可控制模型、sandbox、approval、MCP；profile 可保存不同設定組。Hooks 可在 Codex lifecycle 事件觸發時執行固定指令。

**什麼時候用**：
- 想為深度 review、快速修 typo、full access 任務準備不同 profile。
- 想在每次改檔後自動跑格式化或檢查。
- 想把專案規則跟個人偏好分層管理。

📖 [Config basics](https://developers.openai.com/codex/config-basic)｜[Advanced config](https://developers.openai.com/codex/config-advanced)

---

## 新手選擇速查

| 我現在想做什麼 | 優先用 |
|:--|:--|
| 直接修本機 repo | Codex App Local 或 Codex CLI |
| 邊看 IDE 邊改 | IDE Extension |
| 背景試一個新想法，不干擾現在工作 | App Worktree |
| 交給雲端跑、最後看 PR | Codex Web / Cloud |
| PR 合併前多一層檢查 | GitHub `@codex review` 或 CLI `/review` |
| 需要看網頁畫面 | In-app browser / Browser use |
| 需要操作桌面 App | Computer Use |
| 需要生圖、改圖、看截圖 | Image input / Image generation |
| 任務太大想分工 | Subagents |
| 想讓 Codex 接 Notion / Figma / docs / browser | MCP |
| 重複工作流想保存 | Skills，穩定後再做 Plugins |

---

## 怎麼維護這份文檔

- **更新頻率**：約一個月一次；Codex App / CLI / IDE / Web / GitHub review 有大更新時立即補。
- **內容查證**：以 OpenAI 官方 Codex 文件為主，並搭配本機 `codex --help` / `codex features list` 實測。
- **與 Claude Code FEATURES.md 分工**：`FEATURES.md` = Claude Code；`CODEX_FEATURES.md` = Codex。

> 本文檔由 Codex 依 OpenAI 官方文件與本機 Codex CLI `0.128.0` 彙整，最後更新 2026-06-13。
