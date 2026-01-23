# Stash

[English](README.md) | [简体中文](README.zh-CN.md)

保存和恢复命名的 Claude Code 会话，轻松切换工作上下文。灵感来自 `git stash`。

## 命令

| 命令 | 说明 |
|------|------|
| `/stash:push "名称"` | 用指定名称保存当前会话 |
| `/stash:list` | 列出所有已保存的会话 |
| `/stash:pop "名称"` | 恢复指定名称的会话 |
| `/stash:drop "名称"` | 删除指定名称的会话 |

## 依赖

- Python 3（macOS/Linux 预装）
- **tmux** 或 **screen**（可选，用于自动恢复功能）

### 关于 tmux/screen 依赖

`/stash:pop` 命令支持自动恢复会话：

| 运行环境 | 行为 |
|----------|------|
| **在 tmux 中** | 自动打开新窗口恢复会话，并关闭当前 pane |
| **在 screen 中** | 自动打开新窗口恢复会话，并关闭当前窗口 |
| **两者都没有** | 显示 `claude --resume <session_id>` 命令，需手动执行 |

如果你想要无缝的自动恢复体验，请安装 tmux 或 screen：

```bash
# macOS
brew install tmux
# 或者
brew install screen

# Ubuntu/Debian
sudo apt install tmux
# 或者
sudo apt install screen
```

## 安装

在 Claude Code 中执行以下命令：

```bash
# 添加 marketplace
/plugin marketplace add wuliang142857/claude-stash

# 安装插件
/plugin install stash@wuliang142857
```

## 更新 / 卸载

```bash
# 更新
/plugin update stash@wuliang142857

# 卸载
/plugin uninstall stash@wuliang142857
```

## 许可证

MIT
