#!/bin/bash
# fp.sh - find project and open claude
# 使用: fp          模糊搜索目录，打开 claude
#       fp -c       模糊搜索目录，打开 claude -c（带记忆）
#       fp build    重建目录缓存

FP_CACHE="$HOME/.fp_dirs"
FP_ROOTS=("/d" "/c/Users/xupeng0117")  # 搜索根目录，按环境修改
FP_DEPTH=4
FP_IGNORE="node_modules|\.git|\.cache|proc|sys|dev|run|snap|boot|AppData|\.nuget|\.vs|\.gradle|\.m2|\.cargo|\.idea|\.vscode|dist|build|target|vendor|venv|__pycache__|\$RECYCLE.BIN|System Volume Information"

fp() {
    local use_memory=""
    [ "$1" = "-c" ] && use_memory="1"

    # 重建缓存
    if [ "$1" = "build" ]; then
        echo "正在构建目录缓存..."
        local tmp="$FP_CACHE.tmp"
        > "$tmp"
        for root in "${FP_ROOTS[@]}"; do
            [ -d "$root" ] && find "$root" -maxdepth $FP_DEPTH -type d 2>/dev/null
        done | grep -v -E "($FP_IGNORE)" >> "$tmp"
        sort -u "$tmp" > "$FP_CACHE"
        rm -f "$tmp"
        local count
        count=$(wc -l < "$FP_CACHE")
        echo "已缓存 $count 个目录"
        return
    fi

    # 首次使用自动构建
    if [ ! -f "$FP_CACHE" ]; then
        fp build
    fi

    # fzf 搜索，回车选择
    local dir
    dir=$(fzf --prompt="搜索目录> " --height=40% --reverse --no-mouse < "$FP_CACHE")

    if [ -n "$dir" ]; then
        printf "\033[32m→ %s\033[0m\n" "$dir"
        cd "$dir" || return
        if [ -n "$use_memory" ]; then
            claude -c
        else
            claude
        fi
    fi
}
