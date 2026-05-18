#!/bin/bash
# fp.sh - find project and open claude
# 使用: source fp.sh 加载，然后:
#   fp          模糊搜索目录，打开 claude
#   fp -c       模糊搜索目录，打开 claude -c（带记忆）
#   fp build    重建目录缓存

FP_CACHE="$HOME/.fp_dirs"
FP_ROOTS=("/")  # 搜索根目录，可改为 ("/home" "/data" "/workspace")
FP_DEPTH=4
FP_IGNORE="node_modules|\.git|\.cache|proc|sys|dev|run|snap|boot"

fp() {
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

    # fzf 搜索
    local dir
    dir=$(fzf --prompt="搜索目录> " --height=40% --reverse < "$FP_CACHE")

    if [ -n "$dir" ]; then
        cd "$dir" || return
        if [ "$1" = "-c" ]; then
            claude -c
        else
            claude
        fi
    fi
}
