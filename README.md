# Hot Key Tools

AutoHotkey v2 + Node.js 全局快捷键工具集。

## 使用前准备

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)
2. 安装 [Node.js](https://nodejs.org/)（v18+）
3. 安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)（`npm install -g @anthropic-ai/claude-code`）
4. 安装 [VS Code](https://code.visualstudio.com/)（可选，用于 VS Code 打开模式）
5. 克隆本仓库到本地：
```bash
git clone https://github.com/PennyXu/hot_key.git D:\tools\sql-formatter
```
6. 安装 Node 依赖：
```bash
cd D:\tools\sql-formatter
npm install
```

## 使用方式

### 方式一：直接运行
双击 `.ahk` 文件即可启动对应功能。

### 方式二：开机自启动
1. 按 `Win+R`，输入 `shell:startup`，回车打开启动文件夹
2. 将 `.ahk` 文件的快捷方式放入该文件夹
3. 之后每次开机会自动运行

## 快捷键

| 快捷键 | 功能 | 脚本 |
|--------|------|------|
| `Ctrl+Alt+F` | 格式化选中的 SQL | FormatSQL.ahk |
| `Ctrl+Alt+T` | 翻译选中中文为 snake_case 字段名 | TranslateField.ahk |
| `Ctrl+Alt+P` | 模糊搜索文件夹并打开 Claude | OpenClaude.ahk |

## 功能说明

### SQL 格式化（Ctrl+Alt+F）
选中任意 SQL 文本，按快捷键自动格式化并替换原文。
- 使用 sql-formatter 库解析，自动识别 Hive/Spark 方言（`LATERAL VIEW`、数组下标 `[0]`、`${var}` 变量等）
- 关键字、函数名大写
- 行内注释 `--` 后的逗号自动修正为 trailing comma 风格

### 中文翻译字段名（Ctrl+Alt+T）
选中中文文本，按快捷键翻译为 snake_case 英文字段名并替换。
- 调用千问 3.5 大模型翻译
- 示例：`成立年限标签` → `establishment_years_tag`，`是否优质客户` → `is_quality_customer`

### 模糊搜索打开 Claude（Ctrl+Alt+P）
弹出搜索窗口，输入关键字模糊匹配文件夹，选中后打开 Claude Code。
- 搜索优先级：精确匹配 > 前缀匹配 > 包含匹配 > 模糊匹配
- 两个选项可组合：
  - **带记忆打开**：执行 `claude -c`，继续上次对话
  - **VS Code 打开**：在 VS Code 中打开项目，并自动在终端中启动 Claude

## 配置

### 搜索范围配置（search_config.json）
可自定义文件夹搜索的根目录和忽略规则：
```json
{
  "searchRoots": ["D:\\", "C:\\Users\\用户名"],
  "maxDepth": 3,
  "ignoreDirs": ["node_modules", ".git", "dist", ...]
}
```
修改后点击搜索窗口中的「重建索引」按钮生效。

## 注意事项

- 如需修改脚本路径，编辑 `.ahk` 文件中对应的路径配置
- 翻译功能依赖内部千问 API，需网络通畅
- 首次使用搜索功能时会自动构建文件夹索引，可能需要几秒钟

---

## Linux / Docker 环境使用

容器内没有 GUI，提供 CLI 版本的搜索目录打开 Claude。

### 使用前准备

1. 安装 [fzf](https://github.com/junegunn/fzf)：
```bash
# Debian/Ubuntu
apt install fzf

# 或直接下载
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
```

2. 安装 Claude Code CLI：
```bash
npm install -g @anthropic-ai/claude-code
```

### 安装

将 `fp.sh` 加载到 `.bashrc`：

```bash
# 下载
curl -o ~/fp.sh https://raw.githubusercontent.com/PennyXu/hot_key/main/fp.sh

# 加到 .bashrc 末尾
echo 'source ~/fp.sh' >> ~/.bashrc
source ~/.bashrc
```

### 使用

```bash
fp            # 模糊搜索目录，打开 claude
fp -c         # 模糊搜索目录，打开 claude -c（带记忆）
fp build      # 重建目录缓存
```

### 配置

编辑 `fp.sh` 顶部的变量自定义搜索行为：

```bash
FP_ROOTS=("/")              # 搜索根目录，如 ("/home" "/data" "/workspace")
FP_DEPTH=4                  # 搜索深度
FP_IGNORE="node_modules|..." # 忽略的目录模式
```
