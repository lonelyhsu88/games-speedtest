#!/usr/bin/env bash

# Full Game Loading Test with VPN Workaround
# Measures complete loading: Initial page → CLICK TO PLAY → Game Ready

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
echo -e "${BLUE}║   FULL GAME LOADING TEST (WITH VPN WORKAROUND)         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  API Whitelist Strategy${NC}"
echo ""
echo "This script will:"
echo "  1. Get game URL WITHOUT VPN (white-listed IP)"
echo "  2. Ask you to connect VPN to Bangladesh"
echo "  3. Test full game loading WITH Bangladesh IP"
echo "  4. Measure: Initial page + CLICK TO PLAY + Game ready"
echo ""

# Check current IP
echo -e "${YELLOW}[Step 1] Checking your current IP (should be whitelisted)...${NC}"
CURRENT_IP=$(curl -s --max-time 3 "https://api.ipify.org" 2>/dev/null)
echo -e "  Your IP: ${GREEN}${CURRENT_IP}${NC}"
echo ""

# Get game URL from API
echo -e "${YELLOW}[Step 2] Getting game URL from API (using whitelisted IP)...${NC}"
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

echo -e "${GREEN}✓ Game URL obtained successfully!${NC}"
echo ""

# Build real URL
REAL_URL="https://www.shuangzi6688.com/ArcadeBingo/?ProductId=${PRODUCT_ID}&Lang=${LANG}&Token=${GAME_URL##*Token=}"
GAME_URL_FILE="/tmp/game_url_${GAME_TYPE}_$$.txt"
echo "$REAL_URL" > "$GAME_URL_FILE"

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║              GAME URL READY FOR VPN TESTING            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Game:${NC} ${GAME_TYPE}"
echo -e "${CYAN}Language:${NC} ${LANG}"
echo ""
echo -e "${CYAN}Game URL:${NC}"
echo -e "  ${REAL_URL}"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}          NOW CONNECT YOUR VPN TO BANGLADESH            ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Please:"
echo "  1. Connect your VPN to Bangladesh server"
echo "  2. Press Enter when ready to continue testing..."
echo ""

read -p "Press Enter to continue (or Ctrl+C to exit)..."

echo ""
echo -e "${YELLOW}[Step 3] Verifying VPN connection...${NC}"

# Check new IP after VPN
VPN_IP=$(curl -s --max-time 5 "https://api.ipify.org" 2>/dev/null)
VPN_COUNTRY=$(curl -s --max-time 5 "https://ipapi.co/${VPN_IP}/country_name/" 2>/dev/null)

echo -e "  New IP: ${GREEN}${VPN_IP}${NC}"
echo -e "  Country: ${VPN_COUNTRY}"
echo ""

if [ "$VPN_IP" = "$CURRENT_IP" ]; then
    echo -e "${YELLOW}⚠️  Warning: Your IP hasn't changed!${NC}"
    echo "  You might not be connected to VPN yet."
    echo ""
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        echo "Test cancelled."
        rm -f "$GAME_URL_FILE"
        exit 0
    fi
else
    echo -e "${GREEN}✓ IP changed - VPN connection detected${NC}"

    if echo "$VPN_COUNTRY" | grep -qi "bangladesh"; then
        echo -e "${GREEN}✓✓✓ Connected to Bangladesh! ✓✓✓${NC}"
        IS_BANGLADESH=true
    else
        echo -e "${YELLOW}⚠️  Note: Connected to ${VPN_COUNTRY}, not Bangladesh${NC}"
        IS_BANGLADESH=false
    fi
fi

echo ""
echo -e "${YELLOW}[Step 4] Testing FULL game loading from Bangladesh IP...${NC}"
echo ""

# Start total timer
TOTAL_START=$(date +%s.%N)

# Phase 1: Load initial page (BEFORE CLICK TO PLAY)
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  PHASE 1: Loading page (before CLICK TO PLAY)     ${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}Test URL:${NC}"
echo -e "  ${REAL_URL}"
echo ""

PHASE1_START=$(date +%s.%N)

# Load HTML
echo -e "${CYAN}Loading initial HTML page...${NC}"
HTML_RESULT=$(curl -s \
  -H "Cache-Control: no-cache, no-store, must-revalidate" \
  -H "Pragma: no-cache" \
  -H "Expires: 0" \
  -w "|%{time_total}|%{size_download}|%{http_code}" \
  -o /tmp/game_html_vpn_$$.html "$REAL_URL")
HTML_TIME=$(echo "$HTML_RESULT" | cut -d'|' -f2)
HTML_SIZE=$(echo "$HTML_RESULT" | cut -d'|' -f3)
HTML_CODE=$(echo "$HTML_RESULT" | cut -d'|' -f4)

if [ "$HTML_CODE" != "200" ] || grep -q "404 Error" /tmp/game_html_vpn_$$.html 2>/dev/null; then
    echo -e "${RED}✗ Failed (HTTP $HTML_CODE)${NC}"
    rm -f /tmp/game_html_vpn_$$.html
    rm -f "$GAME_URL_FILE"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} HTML: ${HTML_SIZE} bytes in ${HTML_TIME}s"
echo ""

# Extract resources
JS_FILES=$(grep -o 'src="[^"]*\.js"' /tmp/game_html_vpn_$$.html | sed 's/src="//;s/"$//')
CSS_FILES=$(grep -o 'href="[^"]*\.css"' /tmp/game_html_vpn_$$.html | sed 's/href="//;s/"$//')
rm -f /tmp/game_html_vpn_$$.html

# Load CSS
echo -e "${CYAN}Loading CSS files...${NC}"
CSS_TIME=0
CSS_SIZE=0
CSS_COUNT=0

for css in $CSS_FILES; do
    if [[ ! $css =~ ^http ]]; then
        CSS_URL="https://www.shuangzi6688.com/ArcadeBingo/${css}"
        RESULT=$(curl -o /dev/null -s \
          -H "Cache-Control: no-cache, no-store, must-revalidate" \
          -H "Pragma: no-cache" \
          -H "Expires: 0" \
          -w "%{time_total}|%{size_download}|%{http_code}" "$CSS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${css##*/}: ${SIZE_KB} KB (${TIME}s)"
            CSS_TIME=$(echo "$CSS_TIME + $TIME" | bc)
            CSS_SIZE=$((CSS_SIZE + SIZE))
            CSS_COUNT=$((CSS_COUNT + 1))
        fi
    fi
done

echo ""

# Load initial JavaScript (settings, config - NOT Cocos2d yet)
echo -e "${CYAN}Loading initial JavaScript files...${NC}"
INITIAL_JS_TIME=0
INITIAL_JS_SIZE=0
INITIAL_JS_COUNT=0

for js in $JS_FILES; do
    # Skip Cocos2d engine (loaded after click)
    if [[ $js =~ cocos2d ]]; then
        continue
    fi

    if [[ ! $js =~ ^http ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"
        RESULT=$(curl -o /dev/null -s \
          -H "Cache-Control: no-cache, no-store, must-revalidate" \
          -H "Pragma: no-cache" \
          -H "Expires: 0" \
          -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (${TIME}s)"
            INITIAL_JS_TIME=$(echo "$INITIAL_JS_TIME + $TIME" | bc)
            INITIAL_JS_SIZE=$((INITIAL_JS_SIZE + SIZE))
            INITIAL_JS_COUNT=$((INITIAL_JS_COUNT + 1))
        fi
    fi
done

PHASE1_END=$(date +%s.%N)
PHASE1_TIME=$(echo "$PHASE1_END - $PHASE1_START" | bc)

PHASE1_SIZE=$((HTML_SIZE + CSS_SIZE + INITIAL_JS_SIZE))
PHASE1_SIZE_KB=$(echo "scale=2; $PHASE1_SIZE / 1024" | bc)

echo ""
echo -e "${GREEN}✓ Phase 1 Complete - 'CLICK TO PLAY' screen ready${NC}"
echo -e "  Time: ${GREEN}${PHASE1_TIME}s${NC}"
echo -e "  Size: ${PHASE1_SIZE_KB} KB"
echo -e "  Files: $((CSS_COUNT + INITIAL_JS_COUNT + 1)) (HTML + CSS + initial JS)"
echo ""

# Phase 2: Load game engine (AFTER CLICK TO PLAY)
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  [SIMULATING] User clicks 'CLICK TO PLAY'         ${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo ""

echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  PHASE 2: Loading game engine and assets          ${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo ""

PHASE2_START=$(date +%s.%N)

# Load Cocos2d and main game files
echo -e "${CYAN}Loading game engine (Cocos2d) and main game files...${NC}"
GAME_JS_TIME=0
GAME_JS_SIZE=0
GAME_JS_COUNT=0

for js in $JS_FILES; do
    # Only load Cocos2d and main files now
    if [[ ! $js =~ cocos2d ]] && [[ ! $js =~ main ]]; then
        continue
    fi

    if [[ ! $js =~ ^http ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"

        if [[ $js =~ cocos2d ]]; then
            echo -e "  ${CYAN}Loading large file: ${js##*/}${NC}"
        fi

        RESULT=$(curl -o /dev/null -s \
          -H "Cache-Control: no-cache, no-store, must-revalidate" \
          -H "Pragma: no-cache" \
          -H "Expires: 0" \
          -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
            if [ "$SIZE" -gt 1000000 ]; then
                SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
                echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_MB} MB (${TIME}s)"
            else
                SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
                echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (${TIME}s)"
            fi
            GAME_JS_TIME=$(echo "$GAME_JS_TIME + $TIME" | bc)
            GAME_JS_SIZE=$((GAME_JS_SIZE + SIZE))
            GAME_JS_COUNT=$((GAME_JS_COUNT + 1))
        fi
    fi
done

PHASE2_END=$(date +%s.%N)
PHASE2_TIME=$(echo "$PHASE2_END - $PHASE2_START" | bc)

PHASE2_SIZE=$GAME_JS_SIZE
PHASE2_SIZE_MB=$(echo "scale=2; $PHASE2_SIZE / 1024 / 1024" | bc)

echo ""
echo -e "${GREEN}✓ Phase 2 Complete - Game ready to play!${NC}"
echo -e "  Time: ${GREEN}${PHASE2_TIME}s${NC}"
echo -e "  Size: ${PHASE2_SIZE_MB} MB"
echo -e "  Files: ${GAME_JS_COUNT} (Game engine + main scripts)"
echo ""

# Calculate totals
TOTAL_END=$(date +%s.%N)
TOTAL_TIME=$(echo "$TOTAL_END - $TOTAL_START" | bc)

TOTAL_SIZE=$((PHASE1_SIZE + PHASE2_SIZE))
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)

# Display final results
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        FULL GAME LOADING RESULTS (BANGLADESH)          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Test Information:${NC}"
echo -e "  Original IP (API): ${CURRENT_IP}"
echo -e "  Testing IP (VPN): ${GREEN}${VPN_IP}${NC}"
echo -e "  Location: ${VPN_COUNTRY}"
if [ "$IS_BANGLADESH" = true ]; then
    echo -e "  ${GREEN}✓ Real Bangladesh Testing${NC}"
fi
echo -e "  Game: ${GAME_TYPE}"
echo -e "  Language: ${LANG}"
echo ""

echo -e "${MAGENTA}═══════ PHASE 1: Before CLICK TO PLAY ═══════${NC}"
echo -e "  Initial HTML:       ${HTML_TIME}s"
echo -e "  CSS Files:          ${CSS_TIME}s (${CSS_COUNT} files)"
echo -e "  Initial JS:         ${INITIAL_JS_TIME}s (${INITIAL_JS_COUNT} files)"
echo -e "  ${CYAN}Phase 1 Total:${NC}      ${GREEN}${PHASE1_TIME}s${NC} (${PHASE1_SIZE_KB} KB)"
echo ""

echo -e "${MAGENTA}═══════ PHASE 2: After CLICK TO PLAY ═══════${NC}"
echo -e "  Game Engine:        ${GAME_JS_TIME}s (${GAME_JS_COUNT} files)"
echo -e "  ${CYAN}Phase 2 Total:${NC}      ${GREEN}${PHASE2_TIME}s${NC} (${PHASE2_SIZE_MB} MB)"
echo ""

echo -e "${MAGENTA}═══════════════ TOTAL LOADING ═══════════════${NC}"
echo -e "  ${CYAN}Total Time:${NC}         ${YELLOW}${TOTAL_TIME}s${NC}"
echo -e "  ${CYAN}Total Size:${NC}         ${TOTAL_SIZE_MB} MB"
echo -e "  ${CYAN}Total Files:${NC}        $((CSS_COUNT + INITIAL_JS_COUNT + GAME_JS_COUNT + 1))"
echo ""

# Time breakdown percentages
PHASE1_PERCENT=$(echo "scale=1; $PHASE1_TIME * 100 / $TOTAL_TIME" | bc)
PHASE2_PERCENT=$(echo "scale=1; $PHASE2_TIME * 100 / $TOTAL_TIME" | bc)

echo -e "${CYAN}Time Breakdown:${NC}"
echo -e "  Before Click: ${PHASE1_TIME}s (${PHASE1_PERCENT}%)"
echo -e "  After Click:  ${PHASE2_TIME}s (${PHASE2_PERCENT}%)"
echo ""

# Performance rating
LOAD_INT=$(printf "%.0f" "$TOTAL_TIME")
PHASE2_INT=$(printf "%.0f" "$PHASE2_TIME")

if [ "$LOAD_INT" -lt 5 ]; then
    RATING="${GREEN}Excellent${NC}"
    COMMENT="Very fast - Users can start playing quickly"
elif [ "$LOAD_INT" -lt 10 ]; then
    RATING="${GREEN}Good${NC}"
    COMMENT="Acceptable loading time"
elif [ "$LOAD_INT" -lt 15 ]; then
    RATING="${YELLOW}Fair${NC}"
    COMMENT="Noticeable delay - Some users may notice"
elif [ "$LOAD_INT" -lt 25 ]; then
    RATING="${YELLOW}Poor${NC}"
    COMMENT="Slow loading - May lose impatient users"
else
    RATING="${RED}Very Poor${NC}"
    COMMENT="Unacceptable - Needs CDN optimization"
fi

echo -e "${CYAN}Overall Performance:${NC} $RATING"
echo -e "${CYAN}Assessment:${NC} $COMMENT"
echo ""

# User experience assessment
echo -e "${CYAN}User Experience Analysis:${NC}"
if [ "$PHASE2_INT" -lt 3 ]; then
    echo -e "  After clicking PLAY: ${GREEN}Instant - Users won't notice delay${NC}"
elif [ "$PHASE2_INT" -lt 5 ]; then
    echo -e "  After clicking PLAY: ${GREEN}Quick - Acceptable for most users${NC}"
elif [ "$PHASE2_INT" -lt 10 ]; then
    echo -e "  After clicking PLAY: ${YELLOW}Noticeable - Users will wait${NC}"
else
    echo -e "  After clicking PLAY: ${RED}Long - Users may abandon${NC}"
fi
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Full game loading test completed!${NC}"
echo ""

echo -e "${CYAN}Key Metrics:${NC}"
echo -e "  • Time to see 'CLICK TO PLAY':  ${GREEN}${PHASE1_TIME}s${NC}"
echo -e "  • Time after clicking:          ${GREEN}${PHASE2_TIME}s${NC} ${YELLOW}← Most important!${NC}"
echo -e "  • Total time to playable:       ${YELLOW}${TOTAL_TIME}s${NC}"
echo ""

# Clean up
rm -f "$GAME_URL_FILE"
