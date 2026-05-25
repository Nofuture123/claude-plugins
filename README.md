# rocky-plugins

Rocky 的个人 Claude Code 插件聚合站 —— curated 第三方插件清单，本仓库不托管代码，只做指针索引（marketplace）。

## 安装

```bash
# 1. 添加 marketplace
/plugin marketplace add Nofuture123/claude-plugins

# 2. 安装其中的插件
/plugin install mattpocock-skills@rocky-plugins
```

## 当前清单

| 插件 | 来源 | 说明 |
|---|---|---|
| `mattpocock-skills` | [mattpocock/skills](https://github.com/mattpocock/skills) | Matt Pocock 的 14 个工程/生产力 skill |

## 添加新插件

编辑 `.claude-plugin/marketplace.json`，往 `plugins[]` 数组里追加一项即可。`source` 字段支持：
- `{ "source": "github", "repo": "owner/repo" }` — 引用任意 GitHub 仓库
- `"./subdir"` — 引用本仓库子目录
- `{ "source": "npm", "package": "..." }` — 引用 npm 包

详见 https://code.claude.com/docs/en/plugin-marketplaces.md
