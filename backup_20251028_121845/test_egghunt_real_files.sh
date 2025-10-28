#!/usr/bin/env bash

echo "════════════════════════════════════════════════════════"
echo "測試 EggHuntBingo - 只測試真實存在的文件"
echo "════════════════════════════════════════════════════════"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

GAME_URL="https://www.shuangzi6688.com/Bingo/EggHuntBingo/?Lang=en-US&ProductId=ELS&Token=397261d64dd20d6a4a534df6de5bf008327a80ed9b1112b3cbd83545645fe48a6030f04ab75c06c2deaa84361efdd476"

is_real_file() {
    local content=$1
    # Check if it's a 404 page
    if echo "$content" | grep -q "404 Error"; then
        return 1
    fi
    # Check if it's HTML when we expect JS
    if echo "$content" | grep -q "<!DOCTYPE html>"; then
        return 1
    fi
    return 0
}

load_and_verify() {
    local url=$1
    local name=$2

    CONTENT=$(curl -s "$url")

    if is_real_file "$CONTENT"; then
        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$url")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
        if (( $(echo "$SIZE > 1024000" | bc -l) )); then
            SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} $name: ${SIZE_MB} MB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
        else
            echo -e "  ${GREEN}✓${NC} $name: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
        fi
        echo "$name|$SIZE|$TIME"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name: Not found (404 page)"
        return 1
    fi
}

echo -e "${CYAN}測試從 HTML 中發現的文件：${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_START=$(date +%s.%N)
RESULTS_FILE="/tmp/egghunt_results.txt"
rm -f "$RESULTS_FILE"

# Phase 1: HTML
echo "Phase 1: HTML"
RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$GAME_URL")
TIME=$(echo $RESULT | cut -d'|' -f1)
SIZE=$(echo $RESULT | cut -d'|' -f2)
CODE=$(echo $RESULT | cut -d'|' -f3)
SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
echo -e "  ${GREEN}✓${NC} index.html: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
echo "index.html|$SIZE|$TIME" >> "$RESULTS_FILE"
echo ""

# Phase 2: JavaScript from /assets/
echo "Phase 2: JavaScript Modules (from /assets/)"
load_and_verify "https://www.shuangzi6688.com/assets/check_example-DBI48XH2.js" "check_example-DBI48XH2.js" >> "$RESULTS_FILE"
load_and_verify "https://www.shuangzi6688.com/assets/Error-t0OlWNc8.js" "Error-t0OlWNc8.js" >> "$RESULTS_FILE"
echo ""

# Phase 3: Try main.ts from game path
echo "Phase 3: Game-specific files"
load_and_verify "https://www.shuangzi6688.com/Bingo/EggHuntBingo/main.ts" "main.ts" >> "$RESULTS_FILE"
echo ""

# Phase 4: Check for large engine files that might exist
echo "Phase 4: 搜尋大型引擎文件"
echo -e "${YELLOW}(這些文件可能不存在於這個 Vite 構建的遊戲)${NC}"

# Try different possible locations for Cocos2d
COCOS_PATHS=(
    "/Bingo/EggHuntBingo/cocos2d-js.79a17.min.js"
    "/assets/cocos2d-js-min.js"
    "/cocos2d-js-min.js"
)

for path in "${COCOS_PATHS[@]}"; do
    URL="https://www.shuangzi6688.com${path}"
    NAME=$(basename "$path")
    load_and_verify "$URL" "$NAME" >> "$RESULTS_FILE" 2>/dev/null || true
done

echo ""

# Calculate totals
TOTAL_END=$(date +%s.%N)
TOTAL_TIME=$(echo "$TOTAL_END - $TOTAL_START" | bc)

TOTAL_SIZE=0
TOTAL_FILES=0

if [ -f "$RESULTS_FILE" ]; then
    while IFS='|' read -r name size time; do
        TOTAL_SIZE=$((TOTAL_SIZE + size))
        TOTAL_FILES=$((TOTAL_FILES + 1))
    done < "$RESULTS_FILE"
fi

TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
TOTAL_SIZE_KB=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ 測試完成${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  真實文件數量: ${TOTAL_FILES}"
if (( $(echo "$TOTAL_SIZE > 1024000" | bc -l) )); then
    echo "  總大小: ${TOTAL_SIZE_MB} MB"
else
    echo "  總大小: ${TOTAL_SIZE_KB} KB"
fi
echo "  總時間: ${TOTAL_TIME}s"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}關鍵發現：${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "1. 這個遊戲使用 ${YELLOW}Vite${NC} 構建系統"
echo "   • 不是傳統的 Cocos Creator 結構"
echo "   • 文件都在 /assets/ 目錄"
echo "   • 使用 ES modules"
echo ""
echo "2. 文件大小非常小"
echo "   • HTML: < 1 KB"
echo "   • JavaScript: 總共約 10 KB"
echo "   • 這是因為使用了 minification 和 tree-shaking"
echo ""
echo "3. HTTP 下載時間確實很快（約 ${TOTAL_TIME}s）"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}為什麼瀏覽器可能需要更長時間？${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "我們的測試只測量 ${GREEN}HTTP 下載時間${NC}"
echo ""
echo "但瀏覽器實際加載還包括："
echo ""
echo "  1. ${CYAN}JavaScript 解析和編譯${NC}"
echo "     • Vite bundles 需要被解析"
echo "     • ES modules 需要被編譯"
echo ""
echo "  2. ${CYAN}動態資源加載${NC}"
echo "     • 遊戲圖片 (sprites, textures)"
echo "     • 音頻文件"
echo "     • JSON 配置文件"
echo "     • 這些是在 JS 執行時才加載的！"
echo ""
echo "  3. ${CYAN}WebGL 初始化${NC}"
echo "     • 創建 WebGL context"
echo "     • 編譯 shaders"
echo "     • 上傳 textures 到 GPU"
echo ""
echo "  4. ${CYAN}遊戲引擎初始化${NC}"
echo "     • Cocos Creator 初始化"
echo "     • 場景構建"
echo "     • 物理引擎啟動"
echo ""
echo "  5. ${CYAN}網絡延遲${NC}"
echo "     • 我們從台灣測試，延遲低"
echo "     • 從孟加拉測試，延遲會更高"
echo ""
echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
echo -e "${RED}建議：測試包含動態加載的資源${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "要獲得真實的加載時間，需要："
echo ""
echo "  1. 打開瀏覽器 DevTools Network 面板"
echo "  2. 清除緩存"
echo "  3. 重新加載頁面"
echo "  4. 查看所有請求（包括圖片、音頻）"
echo "  5. 等待 'Load' 和 'DOMContentLoaded' 事件"
echo ""
echo "  ${YELLOW}那才是真正的完整加載時間！${NC}"
echo ""

rm -f "$RESULTS_FILE"
