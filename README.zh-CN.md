# Claude Session Saver

保存、列出和恢复命名的 Claude Code 会话，轻松切换工作上下文。

## 概述

Claude Session Saver 是一个 Claude Code 插件，帮助你管理编码会话。当你在不同项目或任务之间切换时，不再需要丢失上下文 - 你可以用一个易记的名字保存当前会话，稍后随时恢复。

## 命令

### `/save "名称"`

用指定名称保存当前会话。

**用法：**
```bash
/save "认证功能"
/save "调试API问题"
/save "重构数据库"
```

**执行流程：**
1. 获取当前会话 ID
2. 将其与提供的名称关联
3. 存储映射到 `~/.claude/session-names.json`

### `/sessions`

列出所有已保存的会话。

**用法：**
```bash
/sessions
```

**输出示例：**
```
已命名的会话：
--------------------------------
  认证功能        ->  abc123...
  调试API问题     ->  def456...
  重构数据库      ->  ghi789...
```

### `/back "名称"`

恢复之前保存的会话。

**用法：**
```bash
/back "认证功能"
```

**执行流程：**
1. 根据名称查找会话 ID
2. 提供恢复会话的命令：
   - 在 tmux 中：`claude --resume <session_id>`
   - 不在 tmux 中：创建新的 tmux 会话并恢复上下文

## 安装

### 方式一：从 GitHub 克隆

```bash
cd ~/.claude/plugins
git clone https://github.com/wuliang142857/claude-session-saver.git
```

### 方式二：手动安装

1. 创建插件目录：
   ```bash
   mkdir -p ~/.claude/plugins/claude-session-saver
   ```

2. 将本仓库的所有文件复制到该目录

3. 重启 Claude Code

## 工作原理

会话存储在一个简单的 JSON 文件中，位于 `~/.claude/session-names.json`：

```json
{
  "认证功能": "abc123-def456-ghi789",
  "调试API问题": "xyz123-uvw456-rst789"
}
```

插件使用 Claude Code 原生的 `--resume` 参数来恢复会话，完整保留对话历史和上下文。

## 使用场景

### 多任务处理
在不同功能或 bug 之间切换而不丢失上下文：
```bash
/save "功能A"
# 处理其他事情
/back "功能A"  # 从离开的地方继续
```

### 长期项目
为复杂的重构保存里程碑会话：
```bash
/save "重构-阶段1完成"
# 继续工作...
/save "重构-阶段2完成"
```

### 团队协作
与队友分享会话名称：
```bash
/save "bug-123-排查"
# 分享会话 ID 以便一起调试
```

## 依赖要求

- Claude Code CLI
- `jq`（JSON 处理工具）
- 可选：`tmux`（用于会话管理）

## 常见问题

### 找不到会话
- 运行 `/sessions` 查看所有已保存的会话
- 检查 `~/.claude/session-names.json` 是否存在

### 无法恢复会话
- 确保会话没有过期
- 检查是否有权限访问会话文件

## 贡献

欢迎贡献！请随时提交 issue 或 pull request。

## 许可证

MIT License

## 作者

wuliang142857 (wuliang@wuliang142857.me)
