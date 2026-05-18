# Hot Key Tools

AutoHotkey v2 + Node.js 全局快捷键工具集。

## 快捷键

| 快捷键 | 功能 | 脚本 |
|--------|------|------|
| `Ctrl+Alt+F` | 格式化选中的 SQL | FormatSQL.ahk |
| `Ctrl+Alt+T` | 翻译选中中文为 snake_case 字段名 | TranslateField.ahk |

## 安装

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)
2. 安装 [Node.js](https://nodejs.org/)
3. 克隆仓库到 `D:\tools\sql-formatter\`（或修改 `.ahk` 中的路径）
4. 安装依赖：

```bash
cd D:\tools\sql-formatter
npm install
```

5. 双击 `.ahk` 文件运行，或将快捷方式放到启动文件夹（`Win+R` → `shell:startup`）

## 说明

- **SQL 格式化**：使用 sql-formatter 库，自动识别 Hive/Spark 方言（LATERAL VIEW、数组下标、${var} 等），关键字大写，逗号 trailing 风格
- **字段翻译**：调用千问 3.5 大模型，将中文短语翻译为 snake_case 英文字段名
