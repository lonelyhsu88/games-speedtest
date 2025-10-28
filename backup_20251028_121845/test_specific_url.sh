#!/usr/bin/env bash

# Test specific game URL provided by user
# https://www.shuangzi6688.com/Bingo/EggHuntBingo/?Lang=en-US&ProductId=ELS&Token=...

echo "════════════════════════════════════════════════════════"
echo "測試指定遊戲 URL 的完整加載時間"
echo "════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# User provided URL
GAME_URL="https://www.shuangzi6688.com/Bingo/EggHuntBingo/?Lang=en-US&ProductId=ELS&Token=397261d64dd20d6a4a534df6de5bf008327a80ed9b1112b3cbd83545645fe48a6030f04ab75c06c2deaa84361efdd476"

# Extract paths
GAME_PATH="/Bingo/EggHuntBingo/"
BASE_URL="https://www.shuangzi6688.com"

echo -e "${YELLOW}Game URL:${NC}"
echo "  $GAME_URL"
echo ""
echo -e "${YELLOW}Game Path:${NC} $GAME_PATH"
echo -e "${YELLOW}Base URL:${NC} $BASE_URL"
echo ""

# Start total timer
TOTAL_START=$(date +%s.%N)

# =============================================================================
# Phase 1: Load HTML
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[1/5] Loading HTML page...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE1_START=$(date +%s.%N)

RESULT=$(curl -o /tmp/game_test.html -s \
  -H "Cache-Control: no-cache, no-store, must-revalidate" \
  -H "Pragma: no-cache" \
  -H "Expires: 0" \
  -w "%{time_total}|%{size_download}|%{http_code}" "$GAME_URL")

TIME=$(echo $RESULT | cut -d'|' -f1)
SIZE=$(echo $RESULT | cut -d'|' -f2)
CODE=$(echo $RESULT | cut -d'|' -f3)
SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)

if [ "$CODE" != "200" ]; then
    echo -e "${RED}✗ HTML loading failed: HTTP $CODE${NC}"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} HTML: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"

HTML_TIME=$TIME
PHASE1_END=$(date +%s.%N)
PHASE1_TOTAL=$(echo "$PHASE1_END - $PHASE1_START" | bc)

echo -e "  ${BLUE}Phase 1 total: ${PHASE1_TOTAL}s${NC}"
echo ""

# =============================================================================
# Phase 2: Load CSS
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[2/5] Loading CSS files...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE2_START=$(date +%s.%N)

CSS_FILES=$(cat /tmp/game_test.html | grep -o '<link[^>]*rel="stylesheet"[^>]*href="[^"]*"' | grep -o 'href="[^"]*"' | sed 's/href="//;s/"$//')

CSS_COUNT=0
CSS_TIME=0

if [ -z "$CSS_FILES" ]; then
    echo -e "  ${YELLOW}⚠${NC} No CSS files found"
else
    for css in $CSS_FILES; do
        CSS_URL="${BASE_URL}${GAME_PATH}${css}"

        RESULT=$(curl -o /dev/null -s \
          -H "Cache-Control: no-cache, no-store, must-revalidate" \
          -H "Pragma: no-cache" \
          -H "Expires: 0" \
          -w "%{time_total}|%{size_download}|%{http_code}" "$CSS_URL")

        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${css##*/}: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
            CSS_TIME=$(echo "$CSS_TIME + $TIME" | bc)
            CSS_COUNT=$((CSS_COUNT + 1))
        else
            echo -e "  ${RED}✗${NC} ${css##*/}: HTTP ${CODE}"
        fi
    done
fi

PHASE2_END=$(date +%s.%N)
PHASE2_TOTAL=$(echo "$PHASE2_END - $PHASE2_START" | bc)

echo -e "  ${GREEN}✓${NC} Phase 2 complete: $CSS_COUNT files, curl time: ${CSS_TIME}s"
echo -e "  ${BLUE}Phase 2 total: ${PHASE2_TOTAL}s${NC}"
echo ""

# =============================================================================
# Phase 3: Load Initial JavaScript
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[3/5] Loading Initial JavaScript...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE3_START=$(date +%s.%N)

INIT_JS_FILES=$(cat /tmp/game_test.html | grep -o '<script[^>]*src="[^"]*"' | grep -o 'src="[^"]*"' | sed 's/src="//;s/"$//' | grep -v 'cocos2d-js' | head -5)

INIT_JS_COUNT=0
INIT_JS_TIME=0

if [ -z "$INIT_JS_FILES" ]; then
    echo -e "  ${YELLOW}⚠${NC} No initial JS files found"
else
    for js in $INIT_JS_FILES; do
        JS_URL="${BASE_URL}${GAME_PATH}${js}"

        RESULT=$(curl -o /dev/null -s \
          -H "Cache-Control: no-cache, no-store, must-revalidate" \
          -H "Pragma: no-cache" \
          -H "Expires: 0" \
          -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")

        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
            INIT_JS_TIME=$(echo "$INIT_JS_TIME + $TIME" | bc)
            INIT_JS_COUNT=$((INIT_JS_COUNT + 1))
        else
            echo -e "  ${RED}✗${NC} ${js##*/}: HTTP ${CODE}"
        fi
    done
fi

PHASE3_END=$(date +%s.%N)
PHASE3_TOTAL=$(echo "$PHASE3_END - $PHASE3_START" | bc)

echo -e "  ${GREEN}✓${NC} Phase 3 complete: $INIT_JS_COUNT files, curl time: ${INIT_JS_TIME}s"
echo -e "  ${BLUE}Phase 3 total: ${PHASE3_TOTAL}s${NC}"
echo ""

# =============================================================================
# Phase 4: Load Game Engines (Cocos2d + Physics)
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[4/5] Loading Game Engines (Cocos2d + Physics)...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE4_START=$(date +%s.%N)

# Extract Cocos2d engine files
ENGINE_JS_FILES=$(cat /tmp/game_test.html | grep -o '<script[^>]*src="[^"]*cocos2d[^"]*"' | grep -o 'src="[^"]*"' | sed 's/src="//;s/"$//')

ENGINE_COUNT=0
ENGINE_TIME=0

if [ -z "$ENGINE_JS_FILES" ]; then
    echo -e "  ${YELLOW}⚠${NC} No engine files found in HTML"
else
    for js in $ENGINE_JS_FILES; do
        JS_URL="${BASE_URL}${GAME_PATH}${js}"

        RESULT=$(curl -o /dev/null -s \
          -H "Cache-Control: no-cache, no-store, must-revalidate" \
          -H "Pragma: no-cache" \
          -H "Expires: 0" \
          -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")

        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_MB} MB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
            ENGINE_TIME=$(echo "$ENGINE_TIME + $TIME" | bc)
            ENGINE_COUNT=$((ENGINE_COUNT + 1))
        else
            echo -e "  ${RED}✗${NC} ${js##*/}: HTTP ${CODE}"
        fi
    done
fi

PHASE4_END=$(date +%s.%N)
PHASE4_TOTAL=$(echo "$PHASE4_END - $PHASE4_START" | bc)

echo -e "  ${GREEN}✓${NC} Phase 4 complete: $ENGINE_COUNT files, curl time: ${ENGINE_TIME}s"
echo -e "  ${BLUE}Phase 4 total: ${PHASE4_TOTAL}s${NC}"
echo ""

# =============================================================================
# Phase 5: Load Cocos Creator Bundles
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[5/5] Loading Cocos Creator bundles (config.json + index.js)...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHASE5_START=$(date +%s.%N)

BUNDLE_TIME=0
BUNDLE_COUNT=0

BUNDLES=("internal" "resources" "main")
for bundle in "${BUNDLES[@]}"; do
    echo -e "  ${YELLOW}Bundle: ${bundle}${NC}"

    # Load bundle config.json
    CONFIG_URL="${BASE_URL}${GAME_PATH}${bundle}/config.json"
    RESULT=$(curl -o /dev/null -s \
      -H "Cache-Control: no-cache, no-store, must-revalidate" \
      -H "Pragma: no-cache" \
      -H "Expires: 0" \
      -w "%{time_total}|%{size_download}|%{http_code}" "$CONFIG_URL")
    TIME=$(echo $RESULT | cut -d'|' -f1)
    SIZE=$(echo $RESULT | cut -d'|' -f2)
    CODE=$(echo $RESULT | cut -d'|' -f3)

    if [ "$CODE" = "200" ]; then
        SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
        echo -e "    ${GREEN}✓${NC} config.json: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
        BUNDLE_TIME=$(echo "$BUNDLE_TIME + $TIME" | bc)
        BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
    else
        echo -e "    ${YELLOW}⚠${NC} config.json: HTTP ${CODE} (may not exist)"
    fi

    # Load bundle index.js
    INDEX_URL="${BASE_URL}${GAME_PATH}${bundle}/index.js"
    RESULT=$(curl -o /dev/null -s \
      -H "Cache-Control: no-cache, no-store, must-revalidate" \
      -H "Pragma: no-cache" \
      -H "Expires: 0" \
      -w "%{time_total}|%{size_download}|%{http_code}" "$INDEX_URL")
    TIME=$(echo $RESULT | cut -d'|' -f1)
    SIZE=$(echo $RESULT | cut -d'|' -f2)
    CODE=$(echo $RESULT | cut -d'|' -f3)

    if [ "$CODE" = "200" ]; then
        SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
        echo -e "    ${GREEN}✓${NC} index.js: ${SIZE_KB} KB (HTTP ${CODE}) in ${YELLOW}${TIME}s${NC}"
        BUNDLE_TIME=$(echo "$BUNDLE_TIME + $TIME" | bc)
        BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
    else
        echo -e "    ${RED}✗${NC} index.js: HTTP ${CODE}"
    fi
done

PHASE5_END=$(date +%s.%N)
PHASE5_TOTAL=$(echo "$PHASE5_END - $PHASE5_START" | bc)

echo -e "  ${GREEN}✓${NC} Phase 5 complete: $BUNDLE_COUNT files, curl time: ${BUNDLE_TIME}s"
echo -e "  ${BLUE}Phase 5 total: ${PHASE5_TOTAL}s${NC}"
echo ""

# =============================================================================
# Total Summary
# =============================================================================
TOTAL_END=$(date +%s.%N)
TOTAL_ELAPSED=$(echo "$TOTAL_END - $TOTAL_START" | bc)

TOTAL_CURL_TIME=$(echo "$HTML_TIME + $CSS_TIME + $INIT_JS_TIME + $ENGINE_TIME + $BUNDLE_TIME" | bc)
TOTAL_FILES=$((1 + $CSS_COUNT + $INIT_JS_COUNT + $ENGINE_COUNT + $BUNDLE_COUNT))

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Complete Loading Test Finished${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}Results:${NC}"
echo ""
echo "Phase-by-Phase Breakdown:"
echo "  Phase 1 (HTML):      ${HTML_TIME}s (curl) | ${PHASE1_TOTAL}s (total)"
echo "  Phase 2 (CSS):       ${CSS_TIME}s (curl) | ${PHASE2_TOTAL}s (total) - $CSS_COUNT files"
echo "  Phase 3 (Init JS):   ${INIT_JS_TIME}s (curl) | ${PHASE3_TOTAL}s (total) - $INIT_JS_COUNT files"
echo "  Phase 4 (Engines):   ${ENGINE_TIME}s (curl) | ${PHASE4_TOTAL}s (total) - $ENGINE_COUNT files"
echo "  Phase 5 (Bundles):   ${BUNDLE_TIME}s (curl) | ${PHASE5_TOTAL}s (total) - $BUNDLE_COUNT files"
echo ""
echo -e "${CYAN}Total Files Loaded:${NC} $TOTAL_FILES"
echo -e "${CYAN}Total Curl Time:${NC} ${TOTAL_CURL_TIME}s (純 HTTP 請求時間)"
echo -e "${CYAN}Total Script Time:${NC} ${TOTAL_ELAPSED}s (包含腳本處理時間)"
echo ""
echo -e "${YELLOW}說明：${NC}"
echo "  • Curl Time = 實際 HTTP 請求下載時間"
echo "  • Total Time = Curl Time + 腳本處理時間（grep, sed, bc 等）"
echo "  • 實際瀏覽器加載會更快（並行下載）"
echo ""

rm -f /tmp/game_test.html
