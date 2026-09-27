# Upstream 同步 SOP

> 當 `scripts/check-upstream.sh` 偵測到新版時，Claude 讀這份 SOP 執行翻譯同步。
> 觸發來源：scheduled-tasks 每週一 08:00、或手動執行 `bash scripts/check-upstream.sh`。

**同步政策：本地保留上游已刪的條目，採增量同步（雷蒙 2026-09-26 拍板）。** 上游刪掉或瘦身的 rows 不跟著刪（「近期更新」另有只留 5 條的規則，見第 4 步）；上游改名的 key 若本地已有同義條目就不重複加。

---

## 前置狀態

執行前專案應有：

- `scripts/upstream-baseline.html` — **上游基準檔**：上一次同步完成時的上游原始 HTML（進 git，兩台 Mac 共用）
- `tmp/upstream-latest.html` — 最新 upstream HTML（由 check-upstream.sh 產生）
- `tmp/upstream.diff` — 「基準檔 vs 最新上游」的 diff（由 check-upstream.sh 產生）
- `tmp/sync-meta.env` — 內含 `upstream_version=`、`current_version=`、`baseline_version=`、`diff_mode=`、`diff_lines=`、`needs_review=`
- 本地 `index.html` 為繁中版（只有**內容文字**是中文，結構 / class / 資料屬性與原站一致）

如果 `tmp/` 空的 → 先跑 `bash scripts/check-upstream.sh`。
如果 exit 0（版本一致）→ 本輪無需動作，結束。

---

## 執行流程

### 1. 讀版本號與 diff 摘要

```bash
cat tmp/sync-meta.env
```

記下 `upstream_version`（例：`v2.1.112`）、`current_version`（例：`v2.1.101`）、`diff_mode`、`diff_lines`、`needs_review`。

### 2. 看「上游這一輪改了什麼」的 diff

diff 已由 `check-upstream.sh` 算好，比的是**上游基準檔 vs 最新上游**（不是上游 vs 本地 index.html）：

```bash
wc -l tmp/upstream.diff
cat tmp/upstream.diff
# 需要重算時：bash scripts/check-upstream.sh --diff-only
```

- `diff_mode=baseline`：只含上游自上次同步以來的變動，一般是幾十行內。
- **500 行門檻看這份 diff**：`needs_review=1`（`diff_lines` > 500）代表上游大改版，停下來請雷蒙確認，不要自己硬同步。
- `diff_mode=legacy`：找不到 `scripts/upstream-baseline.html`，腳本退回舊行為（上游 vs 本地 index.html）。本地保留了上游已刪的條目，這份 diff 必然爆量，**行數不代表上游改版**；改用人工逐區比對新上游與本地，同步完成後在第 6.5 步建立基準檔，下一輪就會恢復正常。
- 差異一般集中在：版本號字串、新增的指令 / 旗標 / env var、cheat sheet 的章節條目。
- diff 中上游**刪除**的行（`<` 開頭）不動本地；上游**改名**的 key（例如 `/compact [focus]`）若本地已有同義條目，只在必要時更新該條寫法，不重複加。
- 只有 `diff_mode=legacy` 時才會看到以下已知差異（雷蒙版客製），**忽略、不要還原成英文**：
  - `<html lang="zh-Hant">` vs `en`
  - `<title>`、`<meta description/keywords>`、Open Graph、Twitter meta 全是中文
  - `--font-sans` 加了 `'Noto Sans TC'`
  - `font-size`、`padding`、`max-width` 等 CSS 排版（雷蒙版是**滿版設計**，原站是 A4 列印）
  - `.header-left` / `.header-buttons` / `.header-btn` / `.header-right` 區塊是繁中版獨有
  - `@page { size: A4 landscape }` 在原站有，繁中版刻意移除
  - 作者署名：`<meta name="author" content="雷蒙三十">`
  - favicon：繁中版只用 emoji SVG，不引 `/favicon.png`
  - `og:url` / `canonical` / `hreflang` 指向 `cc.storyfox.cz`，繁中版不抄；繁中版自己的 `canonical`、`og:url`、`meta refresh` 指向 `https://ai.lifehacker.tw/claude-code-cheatsheet-zh/`，**不要刪**

### 3. 鎖定真正需要翻譯的內容變動

用 `grep -n` 在 diff 中找：

- 新的指令字串（如 `/rewind`、`ctrl-shift-s`、新的 MCP 範例）
- 新的條目 `<li>` / `<tr>` / `<div class="kbd-row">`
- 版本號字樣 `Claude Code v...`
- `<div class="updated">` / 「Updated: YYYY-MM-DD」
- changelog 連結變更

### 4. 用 Edit 工具逐段同步

**原則**：只改變動處，保留繁中翻譯結構。

- 英文新條目 → 翻成繁中，語氣與既有翻譯一致（簡潔、技術用語保留原文，說明繁中化）。
- `<code>` / `<kbd>` 內容保持原文（指令、旗標、shortcut、env var 名稱一律不翻）。
- 新增 class / data-\* 屬性照抄。

**繁中版給新手的版面規則（雷蒙 2026-09-26 拍板，上游沒有，不要還原）**：

- **近期更新只留最新 5 條**：新條目加在清單最上面，超過 5 條就刪掉最舊的；清單下方的「看完整更新紀錄 →」連結保留。
- **長小標題分兩層**：設定與環境、斜線指令「特殊指令」、CLI「核心指令」「重要旗標」、Skill／Agent Frontmatter。第一層（直接顯示）是為新手挑的常用項，其中 `permissions`、`model`、`env`、`outputStyle`、`hooks`、`statusLine` 等是繁中版自己補的，上游沒有，**不要刪**。第二層收在 `<details class="more">` 收合區。
- **上游新增的條目若屬於上面這些小標題，預設放進第二層**對應的收合區，並把該區 `<summary>` 括號裡的數字 +1：
  - 設定：Hook 相關 →「Hooks 進階」；受管理設定、企業、管理員 →「企業／管理員設定」；其他 →「其他進階設定」。
  - 環境變數：模型、API、思考、token、逾時 →「模型與 API 進階」；`OTEL_*`、Bedrock／Vertex、企業啟動器、憑證 →「企業、雲端與遙測」；其他 →「其他環境變數」。
  - 特殊指令 →「更多特殊指令」；`claude xxx` 子指令 →「更多 claude 子指令」。
  - 旗標：主要搭配 `-p` 寫腳本用的（輸出格式、回合／費用上限、工具白名單、除錯）→「搭配 -p 寫腳本用」；其他 →「其他進階旗標」。
  - Skill Frontmatter：`plugin` 開頭 →「外掛（plugin）相關」；其他 →「其他 Skill 欄位」。Agent Frontmatter →「其他 Agent 欄位」。
  - 只有明顯是新手每天會碰的（例如取代既有常用項的新寫法），才放第一層，並在回報中說明理由。

翻譯風格對照現有 index.html 抽樣：
- 「Keyboard Shortcuts」→「鍵盤快捷鍵」
- 「Slash Commands」→「斜線指令」
- 「Memory Files」→「記憶檔案」
- 「Environment Variables」→「環境變數」
- 動詞用短句，如「Interrupt current action」→「中斷目前動作」

### 5. 更新版本號三處

都改成 `${upstream_version}`：

1. `index.html` 顯示版本字樣（搜尋 `Claude Code v`）
2. `index.html` 的 `Updated: YYYY-MM-DD` → 改成今日日期（Asia/Taipei）
3. `README.md` 的「對齊版本」與「最後更新」表格

### 6. 自我驗證

```bash
# 版本號應該一致
grep -oE 'Claude Code v[0-9.]+' index.html | head -1
grep -oE 'Claude Code v[0-9.]+' README.md | head -1
# check-upstream.sh 應回傳 0
bash scripts/check-upstream.sh && echo "✅ 同步完成"
```

如果 `check-upstream.sh` 回傳 0 才算成功。

### 6.5 更新上游基準檔

同步成功後，把這輪抓到的上游原檔升級成新基準檔，下一輪 diff 才只會看到「下一輪上游的變動」：

```bash
bash scripts/check-upstream.sh --update-baseline
# 會檢查 tmp/upstream-latest.html 版本 = README 版本才覆蓋 scripts/upstream-baseline.html
```

### 7. Commit + Push

```bash
git add index.html README.md scripts/upstream-baseline.html
git commit -m "sync: 同步原站更新至 Claude Code ${upstream_version}"
git push
```

基準檔**一定要跟這次同步一起 commit**，否則另一台 Mac 下次會拿舊基準檔比對。

推送後：

- `.github/workflows/auto-release.yml` 會**自動發 Release**（讀 README 版本號建 tag）。
- `.github/workflows/check-upstream.yml` 下一輪（隔天 00:00 UTC+8）版本比對就會一致，不再開新 issue。

### 8. 關閉已解決的 upstream-update issue

```bash
# 列出所有 open 的 upstream-update issue
gh issue list --state open --label upstream-update --json number,title
```

對 title 中版本 ≤ `${upstream_version}` 的 issue 全部關閉：

```bash
gh issue close <number> --comment "已同步至 ${upstream_version}（見 Release ${upstream_version}）"
```

### 9. 清理

```bash
trash "$PWD/tmp/upstream-latest.html"
trash "$PWD/tmp/upstream.diff"
trash "$PWD/tmp/sync-meta.env"
```

`scripts/upstream-baseline.html` 不要刪，它是下一輪的比對基準。

---

## 故障排查

| 現象 | 處理 |
|:--|:--|
| `curl` 抓 upstream 失敗 | 檢查網路、重試一次；原站真的掛掉就略過本輪 |
| `needs_review=1`（基準檔 diff > 500 行） | 原站大改版，停下來請雷蒙確認；版面 / CSS 重排通常不跟（繁中版是滿版客製） |
| `diff_mode=legacy` | 基準檔不見了：照第 2 步人工比對，完成後跑第 6.5 步重建基準檔並 commit |
| 翻譯後 `check-upstream.sh` 還是 exit 1 | 確認 README 版本號真的改了 |
| auto-release 沒發 Release | 看 GitHub Actions log；通常是 `gh release view` 已存在，檢查 tag 列表 |
| issue 關不掉 | 確認 gh 已登入 `gh auth status` |

---

## 不做的事

- **不**從頭抓 upstream 全文覆蓋本地 index.html（會丟失繁中翻譯與版面客製）
- **不**因為上游刪了條目就刪本地 rows（增量同步）
- **不**照搬上游置頂的 email 訂閱橫幅（`#stickyBar`，原作者的 buttondown 電子報）
- **不**建新的 branch / PR（直接 push master，Release 靠 tag 觸發）
- **不**翻譯 `<code>` / `<kbd>` 內指令
- **不**加任何中文註解到 HTML / JS 內（維持原站結構便於下次 diff）
