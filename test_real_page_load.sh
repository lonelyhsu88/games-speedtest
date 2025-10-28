#!/bin/bash

# Real Page Load Testing - Measures actual complete page load
# Usage: ./test_real_page_load.sh [game_type] [language]

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
echo -e "${BLUE}║    REAL PAGE LOAD TEST (Complete Loading Simulation)  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get client IP
echo -e "${CYAN}Client IP:${NC}"
CLIENT_IP=$(curl -s --max-time 3 "https://api.ipify.org" 2>/dev/null)
echo -e "  Your IP: ${GREEN}${CLIENT_IP:-Unknown}${NC}"
echo ""

echo -e "${CYAN}Test Configuration:${NC}"
echo -e "  Game: ${GREEN}${GAME_TYPE}${NC}"
echo -e "  Language: ${GREEN}${LANG}${NC}"
echo -e "  Test Start: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Get game URL
echo -e "${YELLOW}[1/5] Getting game URL from API...${NC}"
START_TOTAL=$(date +%s.%N)

SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME_TYPE\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo -e "${RED}✗ Failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Success${NC}"
echo ""

# Load HTML page
echo -e "${YELLOW}[2/5] Loading HTML page...${NC}"
REAL_URL="https://www.shuangzi6688.com/ArcadeBingo/?ProductId=${PRODUCT_ID}&Lang=${LANG}&Token=${GAME_URL##*Token=}"

echo -e "${CYAN}Test URL:${NC}"
echo -e "  ${REAL_URL}"
echo ""

HTML_RESULT=$(curl -s -w "|%{time_total}|%{size_download}" -o /tmp/game_html_$$.html "$REAL_URL")
HTML_TIME=$(echo "$HTML_RESULT" | cut -d'|' -f2)
HTML_SIZE=$(echo "$HTML_RESULT" | cut -d'|' -f3)

if grep -q "404 Error" /tmp/game_html_$$.html 2>/dev/null; then
    echo -e "${RED}✗ Page returns 404 error${NC}"
    rm -f /tmp/game_html_$$.html
    exit 1
fi

echo -e "  HTML: ${HTML_SIZE} bytes in ${GREEN}${HTML_TIME}s${NC}"

# Extract resources
JS_FILES=$(grep -o 'src="[^"]*\.js"' /tmp/game_html_$$.html | sed 's/src="//;s/"$//')
CSS_FILES=$(grep -o 'href="[^"]*\.css"' /tmp/game_html_$$.html | sed 's/href="//;s/"$//')
rm -f /tmp/game_html_$$.html

echo ""

# Load CSS
echo -e "${YELLOW}[3/5] Loading CSS files...${NC}"
CSS_TIME=0
CSS_SIZE=0
CSS_COUNT=0

for css in $CSS_FILES; do
    if [[ ! $css =~ ^http ]]; then
        CSS_URL="https://www.shuangzi6688.com/ArcadeBingo/${css}"
        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$CSS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ]; then
            echo -e "  ${GREEN}✓${NC} ${css}: ${SIZE} bytes (${TIME}s)"
            CSS_TIME=$(echo "$CSS_TIME + $TIME" | bc)
            CSS_SIZE=$((CSS_SIZE + SIZE))
            CSS_COUNT=$((CSS_COUNT + 1))
        fi
    fi
done
echo ""

# Load small JS files
echo -e "${YELLOW}[4/5] Loading JavaScript files (small)...${NC}"
SMALL_JS_TIME=0
SMALL_JS_SIZE=0
SMALL_JS_COUNT=0

for js in $JS_FILES; do
    if [[ ! $js =~ cocos2d ]] && [[ ! $js =~ ^http ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"
        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ]; then
            echo -e "  ${GREEN}✓${NC} ${js}: ${SIZE} bytes (${TIME}s)"
            SMALL_JS_TIME=$(echo "$SMALL_JS_TIME + $TIME" | bc)
            SMALL_JS_SIZE=$((SMALL_JS_SIZE + SIZE))
            SMALL_JS_COUNT=$((SMALL_JS_COUNT + 1))
        fi
    fi
done
echo ""

# Load Cocos2d framework (large file)
echo -e "${YELLOW}[5/5] Loading Cocos2d framework (LARGE FILE)...${NC}"
COCOS_TIME=0
COCOS_SIZE=0

for js in $JS_FILES; do
    if [[ $js =~ cocos2d ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"
        echo -e "  Loading: ${CYAN}${js}${NC}"
        
        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}|%{speed_download}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)
        SPEED=$(echo $RESULT | cut -d'|' -f4)

        if [ "$CODE" = "200" ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            SPEED_KBPS=$(echo "scale=2; $SPEED / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} Downloaded: ${SIZE_KB} KB in ${GREEN}${TIME}s${NC}"
            echo -e "    Speed: ${SPEED_KBPS} KB/s"
            COCOS_TIME=$TIME
            COCOS_SIZE=$SIZE
        else
            echo -e "  ${RED}✗${NC} Failed (HTTP $CODE)"
        fi
    fi
done

END_TOTAL=$(date +%s.%N)
TOTAL_TIME=$(echo "$END_TOTAL - $START_TOTAL" | bc)

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║           COMPLETE PAGE LOAD RESULTS                   ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Client Information:${NC}"
echo -e "  Your IP: ${CLIENT_IP}"
echo -e "  Test Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo -e "${CYAN}Loading Timeline:${NC}"
echo -e "  [1] HTML Page:        ${HTML_SIZE} bytes in ${HTML_TIME}s"
echo -e "  [2] CSS Files:        ${CSS_SIZE} bytes in ${CSS_TIME}s (${CSS_COUNT} files)"
echo -e "  [3] Small JS:         ${SMALL_JS_SIZE} bytes in ${SMALL_JS_TIME}s (${SMALL_JS_COUNT} files)"
echo -e "  [4] Cocos2d:          ${COCOS_SIZE} bytes in ${COCOS_TIME}s"
echo ""

TOTAL_SIZE=$((HTML_SIZE + CSS_SIZE + SMALL_JS_SIZE + COCOS_SIZE))
TOTAL_SIZE_KB=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)

echo -e "${CYAN}Total Statistics:${NC}"
echo -e "  Total Size:           ${GREEN}${TOTAL_SIZE_KB} KB${NC}"
echo -e "  Total Time:           ${GREEN}${TOTAL_TIME}s${NC}"
echo -e "  Total Files:          $((CSS_COUNT + SMALL_JS_COUNT + 2))"
echo ""

# Performance rating
LOAD_INT=$(printf "%.0f" "$TOTAL_TIME")
if [ "$LOAD_INT" -lt 3 ]; then
    RATING="${GREEN}Excellent${NC}"
elif [ "$LOAD_INT" -lt 5 ]; then
    RATING="${YELLOW}Good${NC}"
elif [ "$LOAD_INT" -lt 10 ]; then
    RATING="${YELLOW}Fair${NC}"
else
    RATING="${RED}Poor${NC}"
fi

echo -e "${CYAN}Performance Rating:${NC} $RATING"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Bangladesh Network Estimates:${NC}"
echo ""

BD_100K=$(echo "scale=1; $TOTAL_SIZE_KB / 100 + 3" | bc)
BD_500K=$(echo "scale=1; $TOTAL_SIZE_KB / 500 + 1.5" | bc)
BD_1M=$(echo "scale=1; $TOTAL_SIZE_KB / 1000 + 1" | bc)
BD_5M=$(echo "scale=1; $TOTAL_SIZE_KB / 5000 + 0.5" | bc)

echo -e "  Based on ${TOTAL_SIZE_KB} KB total content:"
echo ""
echo -e "  ${RED}100 KB/s${NC} (Slow 3G):      ~${BD_100K}s ${RED}(Very Poor)${NC}"
echo -e "  ${YELLOW}500 KB/s${NC} (Fast 3G):      ~${BD_500K}s ${YELLOW}(Poor)${NC}"
echo -e "  ${YELLOW}1 Mbps${NC} (4G):            ~${BD_1M}s ${YELLOW}(Fair)${NC}"
echo -e "  ${GREEN}5 Mbps+${NC} (Good 4G/WiFi): ~${BD_5M}s ${GREEN}(Good)${NC}"
echo ""

echo -e "${GREEN}✓ Real page load test completed!${NC}"
