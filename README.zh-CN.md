# Claude Session Saver

[English](README.md) | [简体中文](README.zh-CN.md)

保存和恢复命名的 Claude Code 会话，轻松切换工作上下文。

## 命令

| 命令 | 说明 |
|------|------|
| `/save "名称"` | 用指定名称保存当前会话 |
| `/sessions` | 列出所有已保存的会话 |
| `/back "名称"` | 恢复指定名称的会话 |

## 安装

### 方式一：一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main/install.sh | bash -s install
```

### 方式二：手动安装

```bash
# 克隆到 plugins 目录
git clone https://github.com/wuliang142857/claude-session-saver.git ~/.claude/plugins/claude-session-saver

# 创建符号链接到 commands 目录
ln -sf ~/.claude/plugins/claude-session-saver/commands/save.md ~/.claude/commands/
ln -sf ~/.claude/plugins/claude-session-saver/commands/sessions.md ~/.claude/commands/
ln -sf ~/.claude/plugins/claude-session-saver/commands/back.md ~/.claude/commands/
```

## 更新 / 卸载

```bash
# 更新
curl -fsSL https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main/install.sh | bash -s update

# 卸载
curl -fsSL https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main/install.sh | bash -s uninstall
```

## 依赖

- Python 3（macOS/Linux 预装）

## 许可证

MIT
