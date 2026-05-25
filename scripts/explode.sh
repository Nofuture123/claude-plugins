#!/usr/bin/env bash
#
# explode.sh — 把上游 mattpocock/skills 的整包 plugin 爆破成 N 个独立 plugin。
#
# 行为：
#   1. clone 上游 main 到临时目录
#   2. 读取上游 .claude-plugin/plugin.json 里的 skills[] 数组（=作者推荐集）
#   3. 把每个 skill 目录复制到 vendor/matt-<name>/
#   4. 在每个 vendor 子目录注入独立的 .claude-plugin/plugin.json
#   5. 重新生成根目录 .claude-plugin/marketplace.json 的 plugins[] 列表
#
# 幂等：每次运行从零重建 vendor/，所以 git diff 自然反映上游变化。
# 依赖：git, jq, awk。

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_REPO="https://github.com/mattpocock/skills.git"
PREFIX="matt-"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "→ Cloning upstream..."
git clone --depth=1 --quiet "$UPSTREAM_REPO" "$WORK/upstream"

UPSTREAM_MANIFEST="$WORK/upstream/.claude-plugin/plugin.json"
if [[ ! -f "$UPSTREAM_MANIFEST" ]]; then
  echo "✗ Upstream lost its .claude-plugin/plugin.json — abort" >&2
  exit 1
fi

echo "→ Resetting vendor/"
rm -rf "$REPO_DIR/vendor"
mkdir -p "$REPO_DIR/vendor"

plugins_json='[]'
count=0

while IFS= read -r skill_rel; do
  src="$WORK/upstream/${skill_rel#./}"
  if [[ ! -d "$src" ]]; then
    echo "  ⚠ skipping missing: $skill_rel" >&2
    continue
  fi

  name="$(basename "$src")"
  plugin_name="${PREFIX}${name}"
  dest="$REPO_DIR/vendor/$plugin_name"

  cp -R "$src" "$dest"

  # Extract description from SKILL.md frontmatter.
  # Handles three YAML forms: inline (`description: text`), folded (`description: >`),
  # and literal (`description: |`) — folded/literal block scalars span subsequent indented lines.
  desc="$(awk '
    BEGIN { in_fm = 0; capturing = 0; desc = "" }
    /^---[[:space:]]*$/ {
      in_fm++
      if (in_fm == 2) { print desc; exit }
      next
    }
    in_fm == 1 {
      if (capturing) {
        if (match($0, /^[[:space:]]+[^[:space:]]/)) {
          sub(/^[[:space:]]+/, "")
          desc = (desc == "" ? $0 : desc " " $0)
          next
        }
        capturing = 0
      }
      if (/^description:[[:space:]]*[>|][-+]?[[:space:]]*$/) { capturing = 1; next }
      if (/^description:/) {
        sub(/^description:[[:space:]]*/, "")
        desc = $0
        print desc
        exit
      }
    }
  ' "$dest/SKILL.md")"

  # Per anthropic-agent-skills pattern: all plugins share source "./" (the marketplace root),
  # and each plugin's skills[] array points at its single vendor subdirectory.
  # vendor/<name>/.claude-plugin/plugin.json is NOT generated — Claude Code treats the
  # vendor subdir as a bare SKILL.md container, identity comes from the marketplace entry.

  plugins_json="$(echo "$plugins_json" | jq \
    --arg name "$plugin_name" \
    --arg desc "$desc" \
    --arg skill_path "./vendor/$plugin_name" \
    '. + [{
      name: $name,
      source: "./",
      description: $desc,
      strict: false,
      skills: [$skill_path]
    }]')"

  count=$((count + 1))
  echo "  ✓ $plugin_name"
done < <(jq -r '.skills[]' "$UPSTREAM_MANIFEST")

echo "→ Writing marketplace.json ($count plugins)"
jq -n --argjson plugins "$plugins_json" '{
  name: "rocky-plugins",
  owner: { name: "Rocky", email: "wpengf@gmail.com" },
  metadata: {
    description: "Rocky 的个人 Claude Code 插件聚合站 —— vendor/ 下的 plugin 由 scripts/explode.sh 从上游 mattpocock/skills 自动爆破生成。",
    version: "0.2.0",
    last_synced: (now | strftime("%Y-%m-%d"))
  },
  plugins: $plugins
}' > "$REPO_DIR/.claude-plugin/marketplace.json"

echo "✓ Done. $count plugins in vendor/, marketplace.json regenerated."
