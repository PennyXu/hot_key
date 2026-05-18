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

    while true; do
        echo ""
        printf "\033[1;36m搜索目录> \033[0m"
        read -r query

        [ -z "$query" ] && continue

        # 用 awk 一次性完成匹配+评分+排序，速度快
        local results
        results=$(awk -v q="${query,,}" '
        BEGIN { FS="/"; qi=tolower(q) }
        {
            name=tolower($NF)
            path=tolower($0)
            score=0
            if (name==qi) score=10000
            else if (index(name, qi)==1) score=5000
            else if (index(name, qi)>0) score=3000
            else if (index(path, qi)>0) score=1000
            if (score>0) print score"\t"$0
        }' "$FP_CACHE" | sort -rn | head -20 | cut -f2-)

        if [ -z "$results" ]; then
            echo "没有匹配结果，换个关键字试试"
            continue
        fi

        # 显示编号列表
        local i=1
        while IFS= read -r line; do
            printf "  \033[33m%2d\033[0m) %s\n" "$i" "$line"
            ((i++))
        done <<< "$results"

        # 选择
        printf "\033[1;36m选择序号 (0重新搜索, q退出)> \033[0m"
        read -r num

        [ "$num" = "q" ] && return
        [ "$num" = "0" ] && continue

        local dir
        dir=$(echo "$results" | sed -n "${num}p")
        [ -z "$dir" ] && continue

        echo ""
        printf "\033[32m→ %s\033[0m\n" "$dir"
        cd "$dir" || return

        if [ -n "$use_memory" ]; then
            claude -c
        else
            claude
        fi
        return
    done
}
