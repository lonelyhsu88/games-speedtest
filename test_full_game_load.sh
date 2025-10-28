#!/usr/bin/env bash

# Full Game Loading Test - Including "CLICK TO PLAY" and Game Assets
# This script measures the complete game loading time from initial page to playable game

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

GAME_TYPE="${1:-ArcadeBingo}"
LANG="${2:-en-US}"
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"

generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        FULL GAME LOADING TEST (WITH CLICK TO PLAY)     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Game Configuration:${NC}"
echo -e "  Game Type: ${GREEN}${GAME_TYPE}${NC}"
echo -e "  Language: ${GREEN}${LANG}${NC}"
echo ""

# Start total timer
TOTAL_START=$(date +%s.%N)

# Step 1: Get game URL from API
echo -e "${YELLOW}[Step 1/5] Getting game URL from API...${NC}"
STEP1_START=$(date +%s.%N)

SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME_TYPE\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo -e "${RED}✗ Failed to get game URL${NC}"
    echo "API Response: $RESPONSE"
    exit 1
fi

STEP1_END=$(date +%s.%N)
STEP1_TIME=$(echo "$STEP1_END - $STEP1_START" | bc)

echo -e "${GREEN}✓ Success${NC} (${STEP1_TIME}s)"
echo ""

# Build real URL
REAL_URL="https://www.shuangzi6688.com/ArcadeBingo/?ProductId=${PRODUCT_ID}&Lang=${LANG}&Token=${GAME_URL##*Token=}"

echo -e "${CYAN}Game URL:${NC}"
echo -e "  ${REAL_URL}"
echo ""

# Step 2: Load initial HTML page (with "CLICK TO PLAY" screen)
echo -e "${YELLOW}[Step 2/5] Loading initial page (CLICK TO PLAY screen)...${NC}"
STEP2_START=$(date +%s.%N)

HTML_RESULT=$(curl -s -w "|%{time_total}|%{size_download}|%{http_code}" -o /tmp/game_initial_$$.html "$REAL_URL")
HTML_TIME=$(echo "$HTML_RESULT" | cut -d'|' -f2)
HTML_SIZE=$(echo "$HTML_RESULT" | cut -d'|' -f3)
HTML_CODE=$(echo "$HTML_RESULT" | cut -d'|' -f4)

STEP2_END=$(date +%s.%N)

if [ "$HTML_CODE" != "200" ] || grep -q "404 Error" /tmp/game_initial_$$.html 2>/dev/null; then
    echo -e "${RED}✗ Failed (HTTP $HTML_CODE)${NC}"
    rm -f /tmp/game_initial_$$.html
    exit 1
fi

echo -e "${GREEN}✓ Success${NC}"
echo -e "  HTML Size: ${HTML_SIZE} bytes"
echo -e "  Load Time: ${HTML_TIME}s"
echo ""

# Extract all resources from HTML
JS_FILES=$(grep -o 'src="[^"]*\.js"' /tmp/game_initial_$$.html | sed 's/src="//;s/"$//')
CSS_FILES=$(grep -o 'href="[^"]*\.css"' /tmp/game_initial_$$.html | sed 's/href="//;s/"$//')

# Step 3: Load initial page resources (CSS, basic JS)
echo -e "${YELLOW}[Step 3/5] Loading initial page resources...${NC}"
STEP3_START=$(date +%s.%N)

INITIAL_RESOURCES=0
INITIAL_SIZE=0
INITIAL_TIME=0

# Load CSS files
echo -e "${CYAN}Loading CSS files...${NC}"
for css in $CSS_FILES; do
    if [[ ! $css =~ ^http ]]; then
        CSS_URL="https://www.shuangzi6688.com/ArcadeBingo/${css}"
        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$CSS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${css##*/}: ${SIZE_KB} KB (${TIME}s)"
            INITIAL_RESOURCES=$((INITIAL_RESOURCES + 1))
            INITIAL_SIZE=$((INITIAL_SIZE + SIZE))
            INITIAL_TIME=$(echo "$INITIAL_TIME + $TIME" | bc)
        fi
    fi
done

# Load initial JavaScript (settings, config, etc - but not Cocos2d yet)
echo -e "${CYAN}Loading initial JavaScript files...${NC}"
for js in $JS_FILES; do
    # Skip Cocos2d main engine (loaded after "click to play")
    if [[ $js =~ cocos2d ]]; then
        continue
    fi

    if [[ ! $js =~ ^http ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"

        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (${TIME}s)"
            INITIAL_RESOURCES=$((INITIAL_RESOURCES + 1))
            INITIAL_SIZE=$((INITIAL_SIZE + SIZE))
            INITIAL_TIME=$(echo "$INITIAL_TIME + $TIME" | bc)
        fi
    fi
done

STEP3_END=$(date +%s.%N)
STEP3_TIME=$(echo "$STEP3_END - $STEP3_START" | bc)

echo ""
echo -e "${GREEN}✓ Initial page ready${NC} (${INITIAL_RESOURCES} resources, ${STEP3_TIME}s total)"
echo ""

# Step 4: Simulate "CLICK TO PLAY" - Load game engine and assets
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  [SIMULATING] User clicks 'CLICK TO PLAY' button  ${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[Step 4/5] Loading game engine and assets...${NC}"
STEP4_START=$(date +%s.%N)

GAME_RESOURCES=0
GAME_SIZE=0
GAME_TIME=0

# Now load Cocos2d and main game files
echo -e "${CYAN}Loading Cocos2d game engine...${NC}"
for js in $JS_FILES; do
    # Only load Cocos2d and main game files now
    if [[ ! $js =~ cocos2d ]] && [[ ! $js =~ main ]]; then
        continue
    fi

    if [[ ! $js =~ ^http ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"

        if [[ $js =~ cocos2d ]]; then
            echo -e "  ${CYAN}Loading large file: ${js##*/}${NC}"
        fi

        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
            SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_MB} MB (${TIME}s)"
            GAME_RESOURCES=$((GAME_RESOURCES + 1))
            GAME_SIZE=$((GAME_SIZE + SIZE))
            GAME_TIME=$(echo "$GAME_TIME + $TIME" | bc)
        fi
    fi
done

STEP4_END=$(date +%s.%N)
STEP4_TIME=$(echo "$STEP4_END - $STEP4_START" | bc)

echo ""
echo -e "${GREEN}✓ Game engine loaded${NC} (${GAME_RESOURCES} resources, ${STEP4_TIME}s total)"
echo ""

# Step 5: Additional game assets (if any)
echo -e "${YELLOW}[Step 5/5] Checking for additional game assets...${NC}"

# Try to load common game asset paths
ASSET_PATHS=(
    "res/config.json"
    "res/Default/config.json"
    "internal/config.json"
    "src/resource.js"
    "src/project.json"
)

ASSETS_FOUND=0
ASSETS_SIZE=0
ASSETS_TIME=0

for asset in "${ASSET_PATHS[@]}"; do
    ASSET_URL="https://www.shuangzi6688.com/ArcadeBingo/${asset}"
    RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$ASSET_URL" 2>/dev/null)
    TIME=$(echo $RESULT | cut -d'|' -f1)
    SIZE=$(echo $RESULT | cut -d'|' -f2)
    CODE=$(echo $RESULT | cut -d'|' -f3)

    if [ "$CODE" = "200" ] && [ "$SIZE" -gt 100 ]; then
        echo -e "  ${GREEN}✓${NC} ${asset}: ${SIZE} bytes (${TIME}s)"
        ASSETS_FOUND=$((ASSETS_FOUND + 1))
        ASSETS_SIZE=$((ASSETS_SIZE + SIZE))
        ASSETS_TIME=$(echo "$ASSETS_TIME + $TIME" | bc)
    fi
done

if [ $ASSETS_FOUND -eq 0 ]; then
    echo -e "  ${YELLOW}No additional assets found (or already loaded)${NC}"
fi

echo ""

# Calculate totals
TOTAL_END=$(date +%s.%N)
TOTAL_TIME=$(echo "$TOTAL_END - $TOTAL_START" | bc)

TOTAL_SIZE=$((HTML_SIZE + INITIAL_SIZE + GAME_SIZE + ASSETS_SIZE))
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)

CLICK_TO_PLAY_TIME=$(echo "$STEP3_END - $STEP2_START" | bc)
AFTER_CLICK_TIME=$(echo "$STEP4_TIME + $ASSETS_TIME" | bc)

# Display results
rm -f /tmp/game_initial_$$.html

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              FULL GAME LOADING RESULTS                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${MAGENTA}═══════ PHASE 1: Before CLICK TO PLAY ═══════${NC}"
echo -e "${CYAN}API Call:${NC}               ${STEP1_TIME}s"
echo -e "${CYAN}Initial HTML:${NC}           ${HTML_TIME}s"
echo -e "${CYAN}Initial Resources:${NC}      ${STEP3_TIME}s (${INITIAL_RESOURCES} files)"
echo -e "${CYAN}Phase 1 Total:${NC}          ${GREEN}${CLICK_TO_PLAY_TIME}s${NC}"
echo ""

echo -e "${MAGENTA}═══════ PHASE 2: After CLICK TO PLAY ═══════${NC}"
echo -e "${CYAN}Game Engine (Cocos2d):${NC}  ${STEP4_TIME}s (${GAME_RESOURCES} files)"
if [ $ASSETS_FOUND -gt 0 ]; then
    echo -e "${CYAN}Additional Assets:${NC}      ${ASSETS_TIME}s (${ASSETS_FOUND} files)"
fi
echo -e "${CYAN}Phase 2 Total:${NC}          ${GREEN}${AFTER_CLICK_TIME}s${NC}"
echo ""

echo -e "${MAGENTA}═══════════════ TOTAL LOADING ═══════════════${NC}"
echo -e "${CYAN}Total Time:${NC}             ${YELLOW}${TOTAL_TIME}s${NC}"
echo -e "${CYAN}Total Size:${NC}             ${TOTAL_SIZE_MB} MB"
echo -e "${CYAN}Total Resources:${NC}        $((INITIAL_RESOURCES + GAME_RESOURCES + ASSETS_FOUND)) files"
echo ""

# Time breakdown
echo -e "${CYAN}Time Breakdown:${NC}"
echo -e "  Before Click: ${CLICK_TO_PLAY_TIME}s ($(echo "scale=1; $CLICK_TO_PLAY_TIME * 100 / $TOTAL_TIME" | bc)%)"
echo -e "  After Click:  ${AFTER_CLICK_TIME}s ($(echo "scale=1; $AFTER_CLICK_TIME * 100 / $TOTAL_TIME" | bc)%)"
echo ""

# Performance rating
LOAD_INT=$(printf "%.0f" "$TOTAL_TIME")
if [ "$LOAD_INT" -lt 5 ]; then
    RATING="${GREEN}Excellent${NC}"
    COMMENT="Very fast - Ready to play quickly"
elif [ "$LOAD_INT" -lt 10 ]; then
    RATING="${GREEN}Good${NC}"
    COMMENT="Acceptable loading time"
elif [ "$LOAD_INT" -lt 15 ]; then
    RATING="${YELLOW}Fair${NC}"
    COMMENT="Noticeable delay - Users may notice"
elif [ "$LOAD_INT" -lt 25 ]; then
    RATING="${YELLOW}Poor${NC}"
    COMMENT="Slow loading - May lose impatient users"
else
    RATING="${RED}Very Poor${NC}"
    COMMENT="Unacceptable - Needs optimization"
fi

echo -e "${CYAN}Performance Rating:${NC} $RATING"
echo -e "${CYAN}Assessment:${NC} $COMMENT"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Full game loading test completed!${NC}"
echo ""

# Summary for user
echo -e "${CYAN}Key Metrics for Bangladesh Testing:${NC}"
echo -e "  • Time to 'CLICK TO PLAY' screen:  ${GREEN}${CLICK_TO_PLAY_TIME}s${NC}"
echo -e "  • Time after clicking:              ${GREEN}${AFTER_CLICK_TIME}s${NC}"
echo -e "  • Total time to playable:           ${YELLOW}${TOTAL_TIME}s${NC}"
echo ""
