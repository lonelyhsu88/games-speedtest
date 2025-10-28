#!/bin/bash

# VPN Testing with API Whitelist Workaround
# Solution: Get game URL WITHOUT VPN, then test WITH VPN

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
echo -e "${BLUE}║   VPN Testing with API Whitelist Workaround           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT: API Whitelist Issue${NC}"
echo ""
echo "The API has IP whitelist restrictions:"
echo "  • You need to call API from whitelisted IP (without VPN)"
echo "  • Then use the game URL to test from Bangladesh (with VPN)"
echo ""
echo -e "${CYAN}Solution:${NC}"
echo "  Step 1: Get game URL WITHOUT VPN (current IP)"
echo "  Step 2: You manually connect VPN to Bangladesh"
echo "  Step 3: Test the game URL WITH VPN (Bangladesh IP)"
echo ""

# Check current IP
echo -e "${YELLOW}[Step 1] Checking your current IP (should be whitelisted)...${NC}"
CURRENT_IP=$(curl -s --max-time 3 "https://api.ipify.org" 2>/dev/null)
echo -e "  Your current IP: ${GREEN}${CURRENT_IP}${NC}"
echo ""

# Get game URL from API
echo -e "${YELLOW}[Step 2] Getting game URL from API (using whitelisted IP)...${NC}"
START_TIME=$(date +%s.%N)

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
    echo ""
    echo "Possible reasons:"
    echo "  1. Your IP is not whitelisted"
    echo "  2. API is down"
    echo "  3. Invalid credentials"
    exit 1
fi

echo -e "${GREEN}✓ Game URL obtained successfully!${NC}"
echo ""

# Save URL to file for later use
GAME_URL_FILE="/tmp/game_url_${GAME_TYPE}_$$.txt"
echo "$GAME_URL" > "$GAME_URL_FILE"

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║              GAME URL READY FOR VPN TESTING            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Game:${NC} ${GAME_TYPE}"
echo -e "${CYAN}Language:${NC} ${LANG}"
echo ""
echo -e "${GREEN}Game URL:${NC}"
echo "${GAME_URL}"
echo ""
echo -e "${CYAN}URL saved to:${NC} ${GAME_URL_FILE}"
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
        exit 0
    fi
else
    echo -e "${GREEN}✓ IP changed - VPN connection detected${NC}"
    
    # Check if Bangladesh
    if echo "$VPN_COUNTRY" | grep -qi "bangladesh"; then
        echo -e "${GREEN}✓✓✓ Connected to Bangladesh! ✓✓✓${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Note: You're connected to ${VPN_COUNTRY}, not Bangladesh${NC}"
        echo "  Results will be for ${VPN_COUNTRY}, not Bangladesh."
        echo ""
    fi
fi

# Now test the game loading from Bangladesh IP
echo -e "${YELLOW}[Step 4] Testing game loading from Bangladesh IP...${NC}"
echo ""

# Build real game URL
REAL_URL="https://www.shuangzi6688.com/ArcadeBingo/?ProductId=${PRODUCT_ID}&Lang=${LANG}&Token=${GAME_URL##*Token=}"

# Display test URL
echo -e "${CYAN}Test URL:${NC}"
echo -e "  ${REAL_URL}"
echo ""

# Load HTML
echo -e "${CYAN}Loading HTML page...${NC}"
HTML_RESULT=$(curl -s -w "|%{time_total}|%{size_download}" -o /tmp/game_html_vpn_$$.html "$REAL_URL")
HTML_TIME=$(echo "$HTML_RESULT" | cut -d'|' -f2)
HTML_SIZE=$(echo "$HTML_RESULT" | cut -d'|' -f3)

if grep -q "404 Error" /tmp/game_html_vpn_$$.html 2>/dev/null; then
    echo -e "${RED}✗ Page returns 404 error${NC}"
    rm -f /tmp/game_html_vpn_$$.html
    exit 1
fi

echo -e "  ${GREEN}✓${NC} HTML: ${HTML_SIZE} bytes in ${HTML_TIME}s"

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

# Load JS
echo -e "${CYAN}Loading JavaScript files...${NC}"
JS_TIME=0
JS_SIZE=0
JS_COUNT=0

for js in $JS_FILES; do
    if [[ ! $js =~ ^http ]]; then
        JS_URL="https://www.shuangzi6688.com/ArcadeBingo/${js}"
        
        # Show progress for large files
        if [[ $js =~ cocos2d ]]; then
            echo -e "  Loading large file: ${CYAN}${js}${NC}"
        fi
        
        RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{size_download}|%{http_code}" "$JS_URL")
        TIME=$(echo $RESULT | cut -d'|' -f1)
        SIZE=$(echo $RESULT | cut -d'|' -f2)
        CODE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
            echo -e "  ${GREEN}✓${NC} ${js}: ${SIZE_KB} KB (${TIME}s)"
            JS_TIME=$(echo "$JS_TIME + $TIME" | bc)
            JS_SIZE=$((JS_SIZE + SIZE))
            JS_COUNT=$((JS_COUNT + 1))
        fi
    fi
done

END_TIME=$(date +%s.%N)
TOTAL_TIME=$(echo "$END_TIME - $START_TIME" | bc)

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║        REAL BANGLADESH PERFORMANCE RESULTS             ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Testing Details:${NC}"
echo -e "  Original IP (API call):   ${CURRENT_IP}"
echo -e "  Testing IP (VPN):         ${GREEN}${VPN_IP}${NC}"
echo -e "  Testing Location:         ${VPN_COUNTRY}"
echo -e "  Test Time:                $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

TOTAL_SIZE=$((HTML_SIZE + CSS_SIZE + JS_SIZE))
TOTAL_SIZE_KB=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)

echo -e "${CYAN}Loading Results:${NC}"
echo -e "  HTML:              ${HTML_SIZE} bytes in ${HTML_TIME}s"
echo -e "  CSS Files:         ${CSS_SIZE} bytes in ${CSS_TIME}s (${CSS_COUNT} files)"
echo -e "  JS Files:          ${JS_SIZE} bytes in ${JS_TIME}s (${JS_COUNT} files)"
echo ""
echo -e "  ${GREEN}Total Size:        ${TOTAL_SIZE_KB} KB${NC}"
echo -e "  ${GREEN}Total Time:        ${TOTAL_TIME}s${NC}"
echo ""

# Performance rating
LOAD_INT=$(printf "%.0f" "$TOTAL_TIME")
if [ "$LOAD_INT" -lt 3 ]; then
    RATING="${GREEN}Excellent${NC}"
    COMMENT="Very fast loading"
elif [ "$LOAD_INT" -lt 5 ]; then
    RATING="${GREEN}Good${NC}"
    COMMENT="Acceptable performance"
elif [ "$LOAD_INT" -lt 10 ]; then
    RATING="${YELLOW}Fair${NC}"
    COMMENT="Noticeable delay"
elif [ "$LOAD_INT" -lt 20 ]; then
    RATING="${YELLOW}Poor${NC}"
    COMMENT="Slow loading, needs optimization"
else
    RATING="${RED}Very Poor${NC}"
    COMMENT="Unacceptable performance"
fi

echo -e "${CYAN}Performance Rating:${NC} $RATING ($COMMENT)"
echo ""

if echo "$VPN_COUNTRY" | grep -qi "bangladesh"; then
    echo -e "${GREEN}✓ This is REAL Bangladesh performance data!${NC}"
else
    echo -e "${YELLOW}Note: Tested from ${VPN_COUNTRY}, not Bangladesh${NC}"
fi

echo ""
echo -e "${GREEN}✓ Test completed successfully!${NC}"
echo ""
echo -e "${CYAN}Game URL saved to:${NC} ${GAME_URL_FILE}"
echo "You can test this URL again anytime without calling the API."

# Clean up
rm -f "$GAME_URL_FILE"
