#!/bin/bash
# fp.sh - find project and open claude
# 使用:
#   fp              模糊搜索目录，打开 claude
#   fp -c           模糊搜索目录，打开 claude -c（带记忆）
#   fp scan         AI扫描所有项目，生成/更新 .fp_desc 描述文件
#   fp build        重建目录缓存（读取 .fp_desc）
#   fp tag "描述"   给当前目录手动打功能标签
#   fp tags         查看所有手动标签

FP_CACHE="$HOME/.fp_dirs"
FP_TAGS="$HOME/.fp_tags"
FP_SCAN_SCRIPT="/d/tools/sql-formatter/scan-projects.js"  # scan-projects.js 路径，按环境修改
FP_ROOTS=("/d" "/c/Users/xupeng0117")  # 搜索根目录，按环境修改
FP_DEPTH=4
FP_IGNORE="node_modules|\.git|\.cache|proc|sys|dev|run|snap|boot|AppData|\.nuget|\.vs|\.gradle|\.m2|\.cargo|\.idea|\.vscode|dist|build|target|vendor|venv|__pycache__|\$RECYCLE.BIN|System Volume Information"

fp() {
    case "$1" in
        scan)  fp_scan ;;
        build) fp_build ;;
        tag)   fp_tag "${@:2}" ;;
        tags)  fp_tags ;;
        -c)    fp_search 1 ;;
        *)     fp_search "" ;;
    esac
}

fp_scan() {
    if [ ! -f "$FP_SCAN_SCRIPT" ]; then
        echo "找不到 scan-projects.js，请设置 FP_SCAN_SCRIPT 变量"
        return 1
    fi
    echo "正在 AI 扫描项目..."
    node "$FP_SCAN_SCRIPT"
}

fp_build() {
    echo "正在构建目录缓存..."
    local dirs_tmp="$FP_CACHE.dirs"
    > "$dirs_tmp"
    for root in "${FP_ROOTS[@]}"; do
        [ -d "$root" ] && find "$root" -maxdepth $FP_DEPTH -type d 2>/dev/null
    done | grep -v -E "($FP_IGNORE)" | sort -u > "$dirs_tmp"

    # 读取 .fp_desc 合并到缓存
    awk '{
        dir = $0
        desc = ""
        descfile = dir "/.fp_desc"
        if ((getline line < descfile) > 0) desc = line
        close(descfile)
        print dir "\t" desc
    }' "$dirs_tmp" > "$FP_CACHE"

    rm -f "$dirs_tmp"
    echo "已缓存 $(wc -l < "$FP_CACHE") 个目录"
}

fp_tag() {
    local desc="$*"
    if [ -z "$desc" ]; then
        echo "用法: fp tag 描述内容"
        echo "例如: fp tag 数据清洗，ETL管道"
        return 1
    fi
    local dir="$(pwd)"
    [ -f "$FP_TAGS" ] && grep -v "^${dir}	" "$FP_TAGS" > "$FP_TAGS.tmp" && mv "$FP_TAGS.tmp" "$FP_TAGS"
    printf "%s\t%s\n" "$dir" "$desc" >> "$FP_TAGS"
    echo "已标记: $dir → $desc"
}

fp_tags() {
    if [ -f "$FP_TAGS" ] && [ -s "$FP_TAGS" ]; then
        while IFS=$'\t' read -r dir desc; do
            printf "  \033[33m%s\033[0m → %s\n" "$(basename "$dir")" "$desc"
            printf "    %s\n" "$dir"
        done < "$FP_TAGS"
    else
        echo "暂无标签，用 fp tag \"描述\" 给项目打标签"
    fi
}

fp_search() {
    local use_memory="$1"
    [ ! -f "$FP_CACHE" ] && fp_build

    # 合并缓存描述 + 手动标签，格式 "路径 | 描述"
    local display
    display=$(awk -F'\t' '
        NR==FNR {tags[$1]=$2; next}
        {desc = ($2 != "") ? $2 : ""; if (tags[$1] != "") desc = tags[$1]}
        {print $1 (desc ? "  |  " desc : "")}
    ' "$FP_TAGS" 2>/dev/null "$FP_CACHE")

    local selection
    selection=$(fzf --prompt="搜索> " --height=40% --reverse --no-mouse <<< "$display")

    if [ -n "$selection" ]; then
        local dir=$(echo "$selection" | sed 's/  |  .*//')
        printf "\033[32m→ %s\033[0m\n" "$dir"
        cd "$dir" || return
        if [ -n "$use_memory" ]; then
            claude -c
        else
            claude
        fi
    fi
}
