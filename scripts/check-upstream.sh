#!/usr/bin/env bash
# 檢查 upstream (cc.storyfox.cz) 是否有新版
#
# 用法：
#   bash scripts/check-upstream.sh                       # 例行檢查（排程 / 手動）
#   bash scripts/check-upstream.sh --diff-only [FILE]    # 只重算 diff：基準檔 vs FILE（預設 tmp/upstream-latest.html）
#   bash scripts/check-upstream.sh --update-baseline     # 同步成功後，把 tmp/upstream-latest.html 升級為新基準檔
#
# 例行檢查的退出碼：
#   exit 0 → 版本一致，無需動作
#   exit 1 → 偵測到新版，HTML 已存入 tmp/upstream-latest.html、diff 存入 tmp/upstream.diff，
#            接著由 Claude 執行 scripts/sync-upstream.md
#   exit 2 → 抓取 / 解析失敗
#
# diff 邏輯（增量同步，雷蒙 2026-09-26 拍板）：
#   本地 index.html 保留上游已刪的條目，所以不再 diff「上游 vs 本地」。
#   改成 diff「上游基準檔 scripts/upstream-baseline.html（上次同步時的上游原檔）vs 新上游」，
#   只看上游這一輪改了什麼；DIFF_THRESHOLD（預設 500 行）也用這份 diff 計算。
#   基準檔不存在時退回舊行為（diff 新上游 vs 本地 index.html）並提示。

set -euo pipefail

UPSTREAM_URL="https://cc.storyfox.cz"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASELINE="scripts/upstream-baseline.html"
LATEST="tmp/upstream-latest.html"
DIFF_FILE="tmp/upstream.diff"
META="tmp/sync-meta.env"
DIFF_THRESHOLD="${DIFF_THRESHOLD:-500}"

VERSION_RE='Claude Code v([0-9.]+)'

# 從字串取第一個「Claude Code vX.Y.Z」的 vX.Y.Z；找不到回空字串（不用 grep|head，避免 pipefail 誤判）
version_in() {
  if [[ "$1" =~ $VERSION_RE ]]; then
    echo "v${BASH_REMATCH[1]}"
  fi
}

version_of() {
  version_in "$(cat "$1")"
}

# 算 diff，輸出 DIFF_MODE / DIFF_LINES / NEEDS_REVIEW 三個全域變數
compute_diff() {
  local target="$1"
  mkdir -p tmp
  if [[ -f "$BASELINE" ]]; then
    DIFF_MODE="baseline"
    diff "$BASELINE" "$target" > "$DIFF_FILE" || true
  else
    DIFF_MODE="legacy"
    echo "⚠️  找不到基準檔 ${BASELINE}，退回舊行為：diff 新上游 vs 本地 index.html" >&2
    echo "   （本地保留上游已刪條目，這份 diff 必然偏大；同步完成後請跑 --update-baseline 建立基準檔）" >&2
    diff "$target" index.html > "$DIFF_FILE" || true
  fi
  DIFF_LINES="$(wc -l < "$DIFF_FILE" | tr -d ' ')"
  if (( DIFF_LINES > DIFF_THRESHOLD )); then
    NEEDS_REVIEW=1
  else
    NEEDS_REVIEW=0
  fi
}

print_diff_summary() {
  local base_label="$BASELINE"
  [[ "$DIFF_MODE" == "legacy" ]] && base_label="index.html（legacy）"
  echo "Diff     : $DIFF_LINES 行（$base_label vs 新上游，門檻 ${DIFF_THRESHOLD}）→ $DIFF_FILE"
  if [[ "$NEEDS_REVIEW" == "1" ]]; then
    echo "⚠️  diff 超過 $DIFF_THRESHOLD 行：上游可能改版，停下來請雷蒙確認"
  fi
}

case "${1:-}" in
  --diff-only)
    TARGET="${2:-$LATEST}"
    [[ -f "$TARGET" ]] || { echo "❌ 找不到 ${TARGET}（先跑 bash scripts/check-upstream.sh）" >&2; exit 2; }
    compute_diff "$TARGET"
    print_diff_summary
    exit 0
    ;;
  --update-baseline)
    [[ -f "$LATEST" ]] || { echo "❌ 找不到 ${LATEST}，無法更新基準檔" >&2; exit 2; }
    LATEST_VER="$(version_of "$LATEST")"
    CURRENT_VER="$(version_of README.md)"
    if [[ -z "$LATEST_VER" || "$LATEST_VER" != "$CURRENT_VER" ]]; then
      echo "❌ $LATEST 的版本（${LATEST_VER}）≠ README 版本（${CURRENT_VER}），先完成同步再更新基準檔" >&2
      exit 2
    fi
    cp "$LATEST" "$BASELINE"
    echo "✅ 基準檔已更新為 $LATEST_VER → ${BASELINE}（記得跟 index.html / README.md 一起 commit）"
    exit 0
    ;;
  "")
    ;;
  *)
    echo "❌ 未知參數：$1" >&2
    exit 2
    ;;
esac

UPSTREAM_HTML="$(curl -fsSL "$UPSTREAM_URL")" || { echo "❌ 抓取 upstream 失敗" >&2; exit 2; }

UPSTREAM_VER="$(version_in "$UPSTREAM_HTML")"
CURRENT_VER="$(version_of README.md)"

if [[ -z "$UPSTREAM_VER" || -z "$CURRENT_VER" ]]; then
  echo "❌ 版本號解析失敗 (upstream='$UPSTREAM_VER' current='$CURRENT_VER')" >&2
  exit 2
fi

echo "Upstream : $UPSTREAM_VER"
echo "Current  : $CURRENT_VER"
if [[ -f "$BASELINE" ]]; then
  echo "Baseline : $(version_of "$BASELINE")"
else
  echo "Baseline : （無）"
fi

if [[ "$UPSTREAM_VER" == "$CURRENT_VER" ]]; then
  echo "✅ 版本一致，無需同步"
  exit 0
fi

mkdir -p tmp
printf '%s\n' "$UPSTREAM_HTML" > "$LATEST"
compute_diff "$LATEST"
{
  echo "upstream_version=$UPSTREAM_VER"
  echo "current_version=$CURRENT_VER"
  echo "baseline_version=$( [[ -f "$BASELINE" ]] && version_of "$BASELINE" || echo none )"
  echo "diff_mode=$DIFF_MODE"
  echo "diff_lines=$DIFF_LINES"
  echo "diff_threshold=$DIFF_THRESHOLD"
  echo "needs_review=$NEEDS_REVIEW"
  echo "fetched_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
} > "$META"

echo "⚠️  偵測到新版：$CURRENT_VER → $UPSTREAM_VER"
echo "   已存 upstream HTML → $LATEST"
print_diff_summary
echo "   下一步：讓 Claude 讀 scripts/sync-upstream.md 執行同步"
exit 1
