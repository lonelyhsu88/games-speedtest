#!/usr/bin/env bash

echo "════════════════════════════════════════════════════════"
echo "完整測試 EggHuntBingo 遊戲加載"
echo "模擬瀏覽器 Network 面板的所有請求"
echo "════════════════════════════════════════════════════════"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

GAME_URL="https://www.shuangzi6688.com/Bingo/EggHuntBingo/?Lang=en-US&ProductId=ELS&Token=397261d64dd20d6a4a534df6de5bf008327a80ed9b1112b3cbd83545645fe48a6030f04ab75c06c2deaa84361efdd476"
BASE_URL="https://www.shuangzi6688.com"

TOTAL_START=$(date +%s.%N)
TOTAL_SIZE=0
TOTAL_FILES=0
ALL_REQUESTS=""

# Function to load a file and track it
load_file() {
    local url=$1
    local name=$2

    RESULT=$(curl -o /dev/null -s \
      -H "Cache-Control: no-cache, no-store, must-revalidate" \
      -w "%{time_total}|%{size_download}|%{http_code}" "$url")

    TIME=$(echo $RESULT | cut -d'|' -f1)
    SIZE=$(echo $RESULT | cut -d'|' -f2)
    CODE=$(echo $RESULT | cut -d'|' -f3)

    if [ "$CODE" = "200" ]; then
        SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
        echo -e "  ${GREEN}✓${NC} $name: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        TOTAL_FILES=$((TOTAL_FILES + 1))
        ALL_REQUESTS="${ALL_REQUESTS}${name}|${SIZE}|${TIME}\n"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name: HTTP ${CODE}"
        return 1
    fi
}

echo -e "${CYAN}Step 1: Load HTML${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
load_file "$GAME_URL" "index.html"
echo ""

echo -e "${CYAN}Step 2: Load JavaScript modules from HTML${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
load_file "${BASE_URL}/assets/check_example-DBI48XH2.js" "check_example-DBI48XH2.js"
load_file "${BASE_URL}/assets/Error-t0OlWNc8.js" "Error-t0OlWNc8.js"
load_file "${BASE_URL}/Bingo/EggHuntBingo/main.ts" "main.ts"
echo ""

echo -e "${CYAN}Step 3: Check for Cocos Creator bundles${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
BUNDLES=("internal" "resources" "main")
for bundle in "${BUNDLES[@]}"; do
    echo -e "  ${YELLOW}Testing bundle: ${bundle}${NC}"

    # Try config.json
    CONFIG_URL="${BASE_URL}/Bingo/EggHuntBingo/${bundle}/config.json"
    RESULT=$(curl -o /dev/null -s -w "%{http_code}" "$CONFIG_URL")
    if [ "$RESULT" = "200" ]; then
        load_file "$CONFIG_URL" "${bundle}/config.json"
    else
        echo -e "    ${YELLOW}⚠${NC} ${bundle}/config.json not found (HTTP $RESULT)"
    fi

    # Try index.js
    INDEX_URL="${BASE_URL}/Bingo/EggHuntBingo/${bundle}/index.js"
    RESULT=$(curl -o /dev/null -s -w "%{http_code}" "$INDEX_URL")
    if [ "$RESULT" = "200" ]; then
        load_file "$INDEX_URL" "${bundle}/index.js"
    else
        echo -e "    ${YELLOW}⚠${NC} ${bundle}/index.js not found (HTTP $RESULT)"
    fi
done
echo ""

echo -e "${CYAN}Step 4: Check for other common assets${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test for CSS
CSS_URLS=(
    "${BASE_URL}/Bingo/EggHuntBingo/style.css"
    "${BASE_URL}/Bingo/EggHuntBingo/style-mobile.css"
    "${BASE_URL}/assets/index.css"
)

for css_url in "${CSS_URLS[@]}"; do
    CSS_NAME=$(basename "$css_url")
    RESULT=$(curl -o /dev/null -s -w "%{http_code}" "$css_url")
    if [ "$RESULT" = "200" ]; then
        load_file "$css_url" "$CSS_NAME"
    fi
done

# Test for Cocos2d engine
ENGINE_URLS=(
    "${BASE_URL}/Bingo/EggHuntBingo/cocos2d-js-min.js"
    "${BASE_URL}/Bingo/EggHuntBingo/physics-min.js"
    "${BASE_URL}/assets/cocos2d-js-min.js"
)

for engine_url in "${ENGINE_URLS[@]}"; do
    ENGINE_NAME=$(basename "$engine_url")
    RESULT=$(curl -o /dev/null -s -w "%{http_code}" "$engine_url")
    if [ "$RESULT" = "200" ]; then
        load_file "$engine_url" "$ENGINE_NAME"
    fi
done

echo ""

echo -e "${CYAN}Step 5: Test asset directories${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Try to find asset manifest or index files
MANIFEST_URLS=(
    "${BASE_URL}/Bingo/EggHuntBingo/assets/index.json"
    "${BASE_URL}/Bingo/EggHuntBingo/manifest.json"
    "${BASE_URL}/Bingo/EggHuntBingo/import-map.json"
)

for manifest_url in "${MANIFEST_URLS[@]}"; do
    MANIFEST_NAME=$(basename "$manifest_url")
    RESULT=$(curl -o /dev/null -s -w "%{http_code}" "$manifest_url")
    if [ "$RESULT" = "200" ]; then
        load_file "$manifest_url" "$MANIFEST_NAME"
    fi
done

echo ""

TOTAL_END=$(date +%s.%N)
TOTAL_TIME=$(echo "$TOTAL_END - $TOTAL_START" | bc)
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ 測試完成${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Total files loaded: ${TOTAL_FILES}"
echo "  Total size: ${TOTAL_SIZE_MB} MB"
echo "  Total time: ${TOTAL_TIME}s"
echo ""
echo -e "${YELLOW}分析：${NC}"
echo ""
echo "這個遊戲 (EggHuntBingo) 使用的是 ${CYAN}Vite${NC} 構建系統"
echo "不是傳統的 Cocos Creator 結構"
echo ""
echo "文件結構："
echo "  • HTML: 極簡（只有幾行）"
echo "  • JavaScript: 使用 ES modules (type=\"module\")"
echo "  • 路徑: /assets/ 而不是遊戲特定路徑"
echo "  • 構建: Vite minified bundles"
echo ""
echo "這種結構下，加載時間確實很快（約 ${TOTAL_TIME}s）"
echo "因為只有幾個小的 JS 文件"
echo ""
echo -e "${YELLOW}注意：${NC}"
echo "  如果你在瀏覽器看到更長的加載時間，"
echo "  可能是因為："
echo "    1. JavaScript 執行時間（初始化遊戲引擎）"
echo "    2. 動態加載的圖片/音頻資源"
echo "    3. WebGL 渲染初始化"
echo "    4. 遊戲邏輯初始化"
echo ""
echo "  我們的測試只測量 HTTP 下載時間"
echo "  不包含 JavaScript 執行和渲染時間"
