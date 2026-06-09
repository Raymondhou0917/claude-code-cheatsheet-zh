# Claude Code 功能應用情境指南（繁體中文）

> 這份文檔回答的是「**這個功能是幹嘛的？我什麼時候該用它？**」——適合還不熟、想知道某個功能值不值得學的人。
>
> 如果你已經知道要用哪個指令、只是想快速查語法／快捷鍵，請看本 repo 的**速查表**：[線上版](https://raymondhou0917.github.io/claude-code-cheatsheet-zh/) 或 `index.html`。兩份互補：速查表負責「查」，這份負責「懂」。

| 項目 | 內容 |
|:--|:--|
| 對齊版本 | Claude Code v2.1.16x（2026-06） |
| 最後更新 | 2026-06-09 |
| 更新頻率 | 約一個月一次（對照官方 [changelog](https://code.claude.com/docs/en/changelog)） |
| 官方文件 | [code.claude.com/docs](https://code.claude.com/docs) |

**怎麼用這份指南**：照「我現在想幹嘛」找對應分類，每個功能都有「適合用」「別用在」幫你判斷。不用從頭讀，當索引翻就好。

---

## 目錄

1. [自動化與排程](#1-自動化與排程) — 重複任務、輪詢、定時、跑到完成
2. [多 Agent 與背景任務](#2-多-agent-與背景任務) — 把大任務拆給很多 AI 並行
3. [程式碼品質與驗證](#3-程式碼品質與驗證) — 審查、抓 bug、清乾淨、跑起來驗
4. [Hooks（事件自動化）](#4-hooks事件自動化) — 讓某些事「每次一定發生」
5. [外掛與擴充](#5-外掛與擴充) — plugin / skill / MCP / 輸出風格
6. [日常效率指令](#6-日常效率指令) — 每天都會用到的小工具

---

## 1. 自動化與排程

**先搞懂這三個的分工**（很多人搞混）：

| 指令 | 在哪跑 | 一句話 |
|:--|:--|:--|
| `/loop` | 你開著的對話裡 | 你在場，盯一件會變的事到有結果（電腦要開、視窗要在） |
| `/schedule` | Anthropic 雲端 | 無人值守、定時跑，電腦關機也照跑（但碰不到你本機檔案） |
| `/goal` | 你開著的對話裡 | 設一個完成條件，讓它自己一輪輪做到達標才停 |

### `/loop` — 在對話裡定時自動重跑同一句指令

**它做什麼**：在「目前這個對話開著」的前提下，把一句話或一個指令排成定時重複執行。可以給固定間隔（每 5 分鐘），也可以不給時間讓它自己抓節奏（忙就跑勤、閒就拉長）。底層用 cron，最小間隔 1 分鐘，任務 7 天後自動到期（避免被遺忘的迴圈無限燒額度）。

**什麼時候用**：
- 等部署：`/loop 5m 檢查部署好了沒、好了就告訴我`，不用自己一直重整 Zeabur／CI
- 顧 PR：`/loop 看 CI 過了沒、有 review 留言就處理`（不給間隔，它自己抓節奏）
- 反覆重試不穩的爬蟲、等某封重要信進來

**怎麼用**：`/loop [間隔] [指令]`。間隔單位 `s/m/h/d`。停止：下次觸發時按 `Esc`。

**別用在**：需要關電腦／關視窗還要繼續跑的（那是 `/schedule`）；需要秒級精準觸發的（最小 1 分鐘）。

📖 [官方文件](https://code.claude.com/docs/en/scheduled-tasks)

### `/schedule` — 雲端排程的遠端 agent（電腦關機也跑）

**它做什麼**：把任務存成 routine（一段 prompt + GitHub repo + 連接器），在 Anthropic 雲端按時間表自動跑，不需開著對話、不需電腦開機。每次執行 clone 一份乾淨 repo、全自動不跳權限詢問。CLI 最小間隔 1 小時。

**什麼時候用**：
- 每天早上自動整理 backlog、貼標籤、丟摘要到 Slack
- 一次性延後任務：「兩週後開一個移除舊 feature flag 的 PR」
- 每週掃過期文件、自動開更新 PR

**怎麼用**：`/schedule daily PR review at 9am`（定期）、`/schedule tomorrow at 9am, ...`（一次性）。管理：`/schedule list / update / run`。需 Pro/Max/Team/Enterprise 且用 claude.ai 訂閱登入（不是 API key）。

**別用在**：需要讀你本機檔案的任務（雲端是乾淨 clone，看不到你電腦上的東西）；對話內短期輪詢（用 `/loop`）；要小於 1 小時的高頻排程。

📖 [官方文件](https://code.claude.com/docs/en/routines)

### `/goal` — 設完成條件，讓它自己跑到達標

**它做什麼**：設一個可驗證的完成條件後，Claude 不再每做完一輪就停下等你，而是持續做到條件成立。每輪結束有一個小模型（Haiku）判斷「達標了沒」，沒達標就帶著原因繼續。本質是 session 範圍的自動「沒做完不准停」。

**什麼時候用**：
- 把測試跑到全綠：`/goal test/auth 底下所有測試通過且 lint 乾淨`
- 照設計文件實作到所有驗收條件成立
- 清空一批待辦（可加 `or stop after 20 turns` 設上限）

**怎麼用**：`/goal 你的完成條件`，設好立刻開跑。查進度打 `/goal`（不帶參數）；提早停 `/goal clear`。建議搭配 auto mode 不被權限打斷。

**別用在**：終點模糊、無法用「Claude 自己跑出來的結果」客觀驗證的任務（評估器不會自己讀檔／跑指令，條件太空泛會誤判）；純等外部事件（用 `/loop`）。

📖 [官方文件](https://code.claude.com/docs/en/goal)

---

## 2. 多 Agent 與背景任務

**先搞懂分工**：

| 功能 | 一句話 | 彼此能溝通？ | 省 token？ |
|:--|:--|:--|:--|
| `subagents` | 把雜事丟給一個小幫手只拿結論 | 不能（只回報主代理） | 最省 |
| `agent teams` | 一組 AI 像團隊互相討論挑錯 | 能 | 最貴 |
| `claude agents` | 儀表板管多個背景 session | — | 各自吃額度 |
| `ultracode` / workflow | 一句話編排數十到上百 agent | 由腳本協調 | 大任務專用 |

### subagents（子代理委派）

**它做什麼**：把一個會塞爆主對話的雜事（大量搜尋、讀檔、查 log）丟給一個有獨立 context、可限制工具的小幫手，它做完只回摘要，主對話保持乾淨。內建 Explore（唯讀快速找檔）、Plan、general-purpose。

**什麼時候用**：
- 「先探索一下這 codebase 哪裡處理付款」→ Explore 把搜尋做完只回關鍵位置
- 自訂一個唯讀 code-reviewer（只給 Read/Grep），不怕它誤改你的檔
- 把「讀一堆 log 找錯誤」這種雜活路由給便宜的 Haiku 子代理

**怎麼用**：`/agents` 開管理介面建立（存到 `.claude/agents/`）；或直接說「用 code-reviewer agent 檢查這專案」。

**別用在**：需要多個小幫手互相討論時（用 agent teams）；要上百個並行（用 workflow）。

📖 [官方文件](https://code.claude.com/docs/en/sub-agents)

### claude agents（背景 session 儀表板）

**它做什麼**：一個終端機儀表板，把你派出去的多個背景 session 集中看：誰在跑、誰卡住等你、誰做完了。由常駐 supervisor 託管——關終端機、闔筆電睡眠都繼續跑（關機/重開機會停）。

**什麼時候用**：
- 早上一次派三件事（修 bug、審 PR、查 flaky test），切去做別的，哪個亮黃燈再回來
- 派長任務後闔筆電出門，回來它已把 PR 開好等你 merge

**怎麼用**：終端機跑 `claude agents`；或 `claude --bg "任務"` 派背景；session 內 `/bg` 丟到背景。

**別用在**：背景 session 各自吃你的訂閱額度，同時跑 10 個約 10 倍速燒額度，別無腦開一堆。

📖 [官方文件](https://code.claude.com/docs/en/agent-view)

### agent teams（多 session 協作團隊，實驗性）

**它做什麼**：多個 session 組成團隊，一個當組長分派彙整，其他隊員各自獨立工作、還能**彼此直接對話、互相挑錯**。和 subagent 最大差別就在「能溝通」。代價是 token 用量明顯更高。

**什麼時候用**：
- 並行 code review：一人看資安、一人看效能、一人看測試，組長彙整
- 「競爭假設」除錯：生 5 個隊員各查一個假設、互相證偽，活下來的最可能是真因
- 跨前後端 + 測試各自擁有模組、平行開發

**怎麼用**：先設 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 開啟，再用自然語言叫它建團隊。做完叫組長「clean up the team」收尾。建議 3-5 個隊員。

**別用在**：順序相依、要改同一個檔的工作（協調成本和 token 都划不來）。仍在實驗，有已知限制。

📖 [官方文件](https://code.claude.com/docs/en/agent-teams)

### ultracode / 動態工作流

**它做什麼**：一句話讓 Claude 替你的任務寫一個編排腳本，並行調度數十到上百個 subagent，過程中互相挑錯、交叉驗證，最後給一份彙整結果。因為計畫寫成腳本（不靠對話記憶），跑上百 agent 或數小時也不會亂。

**什麼時候用**：
- 全專案安全稽核：「檢查每個 API 端點有沒有漏權限驗證」，幾十個 agent 同時掃
- 多來源交叉驗證的研究（內建 `/deep-research <問題>` 就是這類）
- 500 個檔案的大規模改寫/框架遷移

**怎麼用**：prompt 加 `ultracode:` 關鍵字；或 `/effort ultracode` 讓整個 session 自動編排；或直接 `/deep-research <問題>`。跑起來打 `/workflows` 看進度。需 v2.1.154+。

**別用在**：簡單、線性、改幾個字的小任務（會花比一般對話多很多的 token、也慢）。先拿一小塊試水溫估成本。

📖 [官方文件](https://code.claude.com/docs/en/workflows)

---

## 3. 程式碼品質與驗證

**先搞懂分工**：

| 指令 | 幹嘛 |
|:--|:--|
| `/code-review` | 抓 bug + 順手清理建議（本機 diff） |
| `/code-review ultra` | 雲端深審，每個發現都驗證過（合併前最高規格，收費） |
| `/security-review` | 只盯資安漏洞（injection / XSS / 權限） |
| `/simplify` | 只清乾淨不抓 bug，且直接幫你改 |
| `/verify` | 真的把 app 跑起來、操作、看它能不能動 |
| `/run` | 只負責把 app 啟動起來看效果 |

### `/code-review` — 改完程式的品質把關

**它做什麼**：分析你目前的 diff（未 commit / 已 staged 都算），用多個子代理從不同角度找 correctness bug + 可清理的地方。刻意過濾風格雞蛋裡挑骨頭、linter 會抓的小事，只留高信心真問題。

**什麼時候用**：commit / 開 PR 前一次品質把關；想把 AI 審查意見直接落到 GitHub PR 上。

**怎麼用**：`/code-review`（審本機 diff）。可設深淺 `/code-review high`；`--comment`（貼成 PR 行內留言）、`--fix`（直接套用修正）。傳 PR 編號 `/code-review 1234`。

**別用在**：當 linter/typechecker/跑測試用（它刻意略過）；純風格命名偏好。注意 v2.1.147 前叫 `/simplify`。

📖 [官方文件](https://code.claude.com/docs/en/code-review)

### `/code-review ultra` — 雲端深度審查（合併前體檢）

**它做什麼**：把 repo 打包上傳雲端沙盒，派一整隊 agent 從邏輯/安全/效能/邊界並行審，**每條回報都獨立重現驗證過**，訊號乾淨。在雲端跑、不佔本機，約 5–10 分鐘。

**什麼時候用**：要 merge 一個大改動、想要比本機 review 更深一層、每條都驗證過的信心時。

**怎麼用**：`/code-review ultra`（或別名 `/ultrareview`）；審 PR `/code-review ultra 1234`。跑前會顯示範圍、剩餘免費次數與預估費用。

**別用在**：日常快速回饋（用本機 `/code-review` 就好）。Pro/Max 只有 3 次免費，之後每次約 5–20 美元計入 usage credits。需用 claude.ai 帳號登入。

📖 [官方文件](https://code.claude.com/docs/en/ultrareview)

### `/security-review` — 專盯資安漏洞

**它做什麼**：分析待提交變更，專找 SQL injection、XSS、認證/權限漏洞、不安全資料處理、套件已知漏洞，附嚴重度與修補建議。

**什麼時候用**：提交「會碰使用者輸入、認證、資料庫、外部資料」的重要變更前。

**怎麼用**：`/security-review`，列出資安發現後可請 Claude 直接補修正。

**別用在**：當一般 code review（它窄化在資安，廣義品質用 `/code-review`）；不能取代人工資安審查。

📖 [官方說明](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code)

### `/simplify` — 只清乾淨、直接幫你改

**它做什麼**（v2.1.154 起）：只做清理不抓 bug——抽掉重複、改善命名、收斂冗餘、調整抽象層級，而且**直接套用修正**（輸出改好的碼，不是建議清單）。

**什麼時候用**：做完大重構、或剛吞下一批 AI 生成程式碼，想專心提升簡潔度時。

**怎麼用**：改完程式輸入 `/simplify`，它直接改檔，你再 review 一次 diff。

**別用在**：要找會出錯的邏輯 bug（用 `/code-review`）。它會直接動你的碼，套用後務必自己再看一次。

📖 [官方文件](https://code.claude.com/docs/en/code-review)

### `/verify` — 真的把 app 跑起來驗證

**它做什麼**：不只「看碼對不對」，而是實際啟動 app、走真實流程操作、觀察行為，附證據（輸出/截圖），用 ✅❌⚠️🔍 標記每步「做了什麼 → 觀察到什麼」，還會刻意加偏離 happy path 的探測去試著弄壞它。

**什麼時候用**：「驗證這個 PR」「確認 fix 生效」「push 前驗本機」——任何「光看 code 不夠」的場合。

**怎麼用**：`/verify`。

**別用在**：純審查邏輯不需執行（用 `/code-review`）；只想啟動 app 不做驗證流程（用 `/run`）。

📖 [來源](https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/skill-verify-skill.md)

### `/run` — 一鍵把 app 啟動起來看效果

**它做什麼**：啟動並驅動當前專案的 app，讓你親眼看到改動跑起來。會先找專案既有的啟動 skill，否則依專案類型（CLI/server/TUI/Electron/瀏覽器/函式庫）用內建模式啟動，支援啟動後截圖。

**什麼時候用**：改完前端想看畫面、開發 CLI 想看輸出、快速 demo 給自己看。

**怎麼用**：`/run`。

**別用在**：要「驗證正確性且有證據」用 `/verify` 更完整；只想審碼用 `/code-review`。

📖 [官方文件](https://code.claude.com/docs/en/overview)

---

## 4. Hooks（事件自動化）

**Hooks 是什麼**：寫在設定檔（`settings.json`）裡的「事件 → 指令」對照表。Claude Code 走到某個生命週期節點時，**一定**會自動執行你綁的指令——重點是「確定性」，不像放 CLAUDE.md 靠 AI 自由心證。設定檔三層：`~/.claude/settings.json`（全專案）、專案 `.claude/settings.json`（可進 git 共享）、`.claude/settings.local.json`（單機不進 git）。打 `/hooks` 可看（唯讀）目前掛了哪些。

> 想要「每次都一定發生」的事（格式化、通知、擋危險操作、注入背景）→ 用 hook。
> 需要 AI 判斷的彈性指引 → 放 CLAUDE.md / Skill。
> 要擋死的硬權限 → 用 permissions 規則（hook 的篩選是 best-effort，會 fail-open）。

| 事件 | 觸發時機 | 能擋嗎 | 最常拿來 |
|:--|:--|:--|:--|
| **SessionStart** | 開新/恢復對話 | 不能 | 注入專案背景、設 session 標題 |
| **UserPromptSubmit** | 你送出訊息、AI 還沒處理 | 能 | 攔危險請求、自動補背景 |
| **PreToolUse** | 工具執行前 | 能（硬防線） | 擋 `rm -rf`、保護 `.env` |
| **PostToolUse** | 工具執行後 | 不能撤銷 | 自動格式化、跑 lint |
| **Stop** | AI 講完話準備結束這輪 | 能 | 「測試沒過不准停」 |
| **SubagentStop** | 子代理跑完 | 能 | 驗證子代理產出 |
| **PreCompact** | 對話壓縮前 | 能 | 先備份重點 |
| **SessionEnd** | 對話關閉 | 不能 | 清暫存、寫日誌、封存 |
| **Notification** | AI 需要你關注 | 不能 | 跳桌面通知（最熱門入門用法） |

**基本寫法**：
```json
{ "hooks": { "事件名": [ { "matcher": "篩選條件", "hooks": [ { "type": "command", "command": "你的指令" } ] } ] } }
```

**幾個高 CP 值的入門 hook**：
- **跳桌面通知**（Notification）：AI 卡在等權限/做完時 macOS 跳通知，你可以切去做別的事
- **自動格式化**（PostToolUse + matcher `Edit|Write`）：改完檔自動跑 Prettier/ESLint
- **擋危險操作**（PreToolUse + matcher `Bash`）：偵測到 `rm -rf`/`drop table` 直接 deny，連 bypassPermissions 都擋得住
- **跨 session 記憶**（SessionStart 注入 + SessionEnd 寫日誌）：開工自動補進度、收尾自動記錄

📖 [Hooks 入門](https://code.claude.com/docs/en/hooks-guide)｜[完整事件參考](https://code.claude.com/docs/en/hooks)

---

## 5. 外掛與擴充

### Plugins（外掛）

**它做什麼**：把 skills + 自訂指令 + 子代理 + hook + MCP 設定打包成一個可安裝、可分享、可版本控管的整包。價值在「整包帶著走」——一套調好的工作流原封不動分享給隊友或跨專案重用。

**什麼時候用**：把一套擴充分享給團隊/社群、跨多專案重用同一套設定、要透過市集發布時。

**怎麼用**：本機測試 `claude --plugin-dir ./my-plugin`；從市集裝 `/plugin marketplace add ...` 再 `/plugin install 名稱@market`；改完 `/reload-plugins` 熱重載。

**別用在**：個人單一專案的小客製、還在實驗階段（用 `.claude/` 的 standalone 設定更輕量，穩定後再轉 plugin）。

📖 [官方文件](https://code.claude.com/docs/en/plugins)

### Skills（技能）

**它做什麼**：把你一再重複貼的指示/檢查清單/多步驟流程，存成一份 `SKILL.md`，Claude 需要時自動載入、也能 `/技能名` 手動叫。關鍵是「漸進式揭露」——平常只有描述在 context 裡（幾乎不花 token），被叫到才載入完整內容。

**什麼時候用**：同一套指示你貼第二次、或 CLAUDE.md 某段已從「事實」長成「流程」時，就該抽成技能。

**怎麼用**：建 `~/.claude/skills/<名稱>/SKILL.md`（個人）或 `.claude/skills/<名稱>/SKILL.md`（專案）。frontmatter 至少寫 `description`（決定何時自動用）。手動叫 `/技能名 參數`。建議 < 500 行，細節拆附檔。

**別用在**：只是描述專案慣例或一次性背景（用 CLAUDE.md）；別亂建一堆（描述太多會吃 context）。

📖 [官方文件](https://code.claude.com/docs/en/skills)

### MCP（外接工具/服務）

**它做什麼**：用開放標準把 Claude Code 接到外部工具與資料源（GitHub、Notion、資料庫、Sentry、Figma…），讓 Claude 直接讀寫，不用你手動複製貼上。判斷時機很簡單——**你發現自己一直把某工具的資料複製進對話，那個工具就該接成 MCP**。

**什麼時候用**：
- 接 GitHub + Jira：「把 ENG-4521 描述的功能做出來並開 PR」，它自己讀議題、改碼、開 PR
- 接 PostgreSQL：「找出用過某功能的 10 個使用者 email」，直接下 query

**怎麼用**：遠端 HTTP（推薦）`claude mcp add --transport http notion https://mcp.notion.com/mcp`；本機 `claude mcp add ... -- npx -y 某-mcp-server`。管理 `claude mcp list/get/remove`，session 內 `/mcp` 看狀態。

**別用在**：只連你信任的 server（會抓外部內容的有 prompt injection 風險）；一次性查詢用內建工具就夠。

📖 [官方文件](https://code.claude.com/docs/en/mcp)

### Output Styles（輸出風格）

**它做什麼**：改 Claude 的「講話方式」而不是「知道什麼」——接到 system prompt 後面，調整角色、語氣、預設格式。內建 Default、Proactive（直接動手少問）、Explanatory（邊做邊解釋為什麼）、Learning（留 TODO(human) 讓你練手）。

**什麼時候用**：接手陌生 codebase 切 Explanatory 學框架；想被動學習切 Learning；把 Claude 當寫作/分析助理（非工程）。

**怎麼用**：`/config` → 選 Output style（`/output-style` 指令已在 v2.1.91 移除）。自訂放 `~/.claude/output-styles/*.md`，改完要 `/clear` 或開新 session 才生效。

**別用在**：要告訴 Claude 專案慣例/事實（那該寫 CLAUDE.md）；單次臨時調整用 `--append-system-prompt`。

📖 [官方文件](https://code.claude.com/docs/en/output-styles)

---

## 6. 日常效率指令

### `/fewer-permission-prompts` — 少被問「可以執行嗎？」

掃你最近 50 個 session，找出你一直手動按「允許」的安全唯讀指令，依頻率加進專案白名單（自動擋掉危險萬用字元、出現少於 3 次的略過）。**適合**保留嚴格權限但受夠權限疲勞的人；**別用**在已開全自動模式時。📖 [文件](https://code.claude.com/docs/en/commands)

### `/effort` — 調 Claude「想多深」

一個旋鈕：low/medium/high/xhigh/max。重大決策、跨系統 debug、不可逆操作 → `/effort max`（最深推理、但寫不進 settings 重啟就沒）；簡單分類/格式化/短摘要 → 降到 low/medium 省錢加速。臨時想某輪深一點：prompt 裡寫 `ultrathink`。📖 [文件](https://code.claude.com/docs/en/model-config)

### `/model` 與 fast mode — 換腦袋 / 提速

`/model` 換模型：`opus`（最強）、`sonnet`（日常）、`haiku`（最快做簡單事）、`opus[1m]`（百萬 token 長 context）。`/fast` 是另一回事——同一個 Opus 走「優先速度」設定，最快 2.5 倍、品質不變但每 token 更貴（走 usage credits、不算訂閱額度）。**fast 適合**趕死線的互動工作；**別用**在批次/CI/在意成本時。📖 [文件](https://code.claude.com/docs/en/fast-mode)

### `/rewind` — 時光機，把碼/對話倒回先前狀態

把對話和/或程式碼倒回先前 checkpoint，可分開選「只倒碼」「只倒對話」「都倒」。別名 `/undo`、`/checkpoint`，連按兩次 `Esc` 也能叫出。**適合**Claude 把事情做壞、走錯方向想重來時（比手動 git reset 直覺）。已 push 的東西它管不到（那是 git 的事）。📖 [文件](https://code.claude.com/docs/en/commands)

### `/context` — 看「腦容量」還剩多少

把 context 用量畫成彩色方格，顯示是誰在吃（肥大的 MCP 輸出、過肥的 CLAUDE.md）並給優化建議。`/context all` 看完整細目。**搭配** `/compact`、`/clear` 的判斷依據。📖 [文件](https://code.claude.com/docs/en/commands)

### `/rename` — 幫 session 取看得懂的名字

重新命名當前 session（顯示在 prompt bar），不給名字會依對話內容自動生成。**適合**會回頭 `/resume` 的長期任務、或同時跑多個 session 要區分時——下週回來不再是一排時間戳。📖 [文件](https://code.claude.com/docs/en/commands)

### `/clear` vs `/compact` — 換任務 vs 省空間

- **`/clear`**：清空對話開新局（專案記憶 CLAUDE.md 還在），舊對話可 `/resume` 找回。換到**不相關**新任務時用。
- **`/compact`**：把對話壓成摘要、**延續同一段**，省 context 又不丟重點。context 超過 80% 或看到警告時用。

一句話：要換題用 `/clear`，要省空間續做用 `/compact`。📖 [clear](https://code.claude.com/docs/en/commands)｜[compact](https://code.claude.com/docs/en/context-window)

### `/statusline` — 自訂底部狀態列

底部一條常駐狀態列，跑你的 shell 腳本顯示任何東西（context 用量、成本、git 分支）。`/statusline 用自然語言描述你要什麼`，它自動生腳本並改好設定。**適合**想常駐監看用量/成本/分支、或跨多 session 視覺區分時。📖 [文件](https://code.claude.com/docs/en/statusline)

### `--bare` — 最小模式（啟動旗標，不是 session 內指令）

啟動時砍掉所有自動載入（hooks、skills、plugins、MCP、auto memory、CLAUDE.md），只剩 Bash + 讀檔 + 改檔三種工具，讓腳本化呼叫**秒開**。**適合**CI/CD、headless 批次、或隔離「是不是某個 hook/MCP 拖慢啟動」的問題。**日常互動絕對別用**——等於把整套知識庫和工具全關掉，Claude 會「失憶」。

> 💡 順帶一提：`claude -p`（headless）走訂閱 OAuth 認證時，每次冷啟動光認證握手就要約 35 秒；`--bare`（走 API key、跳過認證與載入）則約 1 秒。所以 hook 裡需要快速、輕量呼叫模型時，與其用 `claude -p`，不如直接打外部 API（如 Gemini）更划算。

📖 [CLI 參考](https://code.claude.com/docs/en/cli-reference)

---

## 怎麼維護這份文檔

- **更新頻率**：約一個月一次，對照官方 [changelog](https://code.claude.com/docs/en/changelog) 補新功能、修正變動的用法。
- **內容查證**：每個功能的用法都以官方文件為準（每條附 📖 連結），不憑記憶。
- **與速查表分工**：這份（FEATURES.md）= 學「何時用」；[速查表 index.html](https://raymondhou0917.github.io/claude-code-cheatsheet-zh/) = 查「怎麼用」。

> 本文檔內容由 Claude Code 並行查證官方文件後彙整，最後更新 2026-06-09。
