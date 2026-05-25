# rocky-plugins

Rocky 的个人 Claude Code 插件聚合站 —— 把上游打包的 skill 集合**爆破**成可单独安装的 plugin。

## 安装单个 skill

```bash
# 第一次先添加 marketplace
/plugin marketplace add Nofuture123/claude-plugins

# 按需安装：以 TDD 为例
/plugin install matt-tdd@rocky-plugins
```

每个 skill 都是独立 plugin，可以单装单卸 —— 解决了 Claude Code 不支持 per-skill 开关的限制。

## 当前清单

来源：[mattpocock/skills](https://github.com/mattpocock/skills)（由 `scripts/explode.sh` 从上游 `.claude-plugin/plugin.json` 的 curated 列表自动同步）

| Plugin | 用途 |
|---|---|
| `matt-tdd` | Red-green-refactor TDD 循环 |
| `matt-diagnose` | 系统化 bug 诊断（复现→最小化→假设→定位→修复→回归） |
| `matt-grill-with-docs` | 用项目领域语言挑战你的计划 |
| `matt-grill-me` | 通过盘问把模糊计划逼到清晰 |
| `matt-triage` | 状态机驱动的 issue 分类 |
| `matt-improve-codebase-architecture` | 找架构改进点 |
| `matt-to-prd` | 把对话上下文凝结成 PRD |
| `matt-to-issues` | 把 PRD/计划拆成 tracer-bullet vertical slices |
| `matt-zoom-out` | 让 agent 拉远视角看大局 |
| `matt-prototype` | 写一次性原型探索设计 |
| `matt-caveman` | 极简语言模式，省 token ~75% |
| `matt-handoff` | 压缩当前会话为接班文档 |
| `matt-write-a-skill` | 创建新 skill 的脚手架 |
| `matt-setup-matt-pocock-skills` | 给 repo 配置 issue tracker / triage 标签 / 文档位置（先跑这个） |

## 维护

- `scripts/explode.sh` 是幂等的爆破脚本：clone 上游 main → 重建 vendor/ → 重写 marketplace.json
- `.github/workflows/sync-upstream.yml` 每月 1 号 06:00 UTC 自动跑一次；也可以在 Actions 页面手动触发
- 想锁定上游某个 commit：编辑 `explode.sh` 把 `--depth=1` 改成 `--branch <sha>`

## 结构

```
.claude-plugin/marketplace.json   ← 入口清单
vendor/matt-<name>/               ← 每个独立 plugin，从上游复制 + 注入 plugin.json
scripts/explode.sh                ← 爆破脚本
.github/workflows/sync-upstream.yml
```

vendor/ 里的所有文件都是自动生成的 —— 不要手改，会被下次同步覆盖。
