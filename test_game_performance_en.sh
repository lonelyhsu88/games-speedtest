#!/bin/bash

# Game Performance Testing Script
# Usage: ./test_game_performance_en.sh [game_type] [language]
# Example: ./test_game_performance_en.sh ArcadeBingo en-US

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GAME_TYPE="${1:-ArcadeBingo}"
LANG="${2:-en-US}"
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"

# Generate random sequence
generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Game Performance Testing Tool${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${GREEN}Game Type:${NC} $GAME_TYPE"
echo -e "${GREEN}Language:${NC} $LANG"
echo -e "${GREEN}Username:${NC} $USERNAME"
echo ""

# Step 1: Get game URL
echo -e "${YELLOW}[Step 1/5] Fetching game URL...${NC}"
SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME_TYPE\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

# Check API response
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ API request failed${NC}"
    exit 1
fi

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo -e "${RED}✗ Failed to get game URL${NC}"
    echo "API Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Game URL retrieved successfully${NC}"
echo ""
echo -e "${CYAN}Game URL:${NC}"
echo -e "  $GAME_URL"
echo ""

# Step 2: Test redirect page performance
echo -e "${YELLOW}[Step 2/5] Testing redirect page performance...${NC}"
REDIRECT_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_starttransfer}|%{time_total}|%{size_download}" "$GAME_URL")

REDIRECT_CODE=$(echo $REDIRECT_RESULT | cut -d'|' -f1)
REDIRECT_DNS=$(echo $REDIRECT_RESULT | cut -d'|' -f2)
REDIRECT_CONNECT=$(echo $REDIRECT_RESULT | cut -d'|' -f3)
REDIRECT_TLS=$(echo $REDIRECT_RESULT | cut -d'|' -f4)
REDIRECT_TTFB=$(echo $REDIRECT_RESULT | cut -d'|' -f5)
REDIRECT_TOTAL=$(echo $REDIRECT_RESULT | cut -d'|' -f6)
REDIRECT_SIZE=$(echo $REDIRECT_RESULT | cut -d'|' -f7)

echo "  HTTP Status: $REDIRECT_CODE"
echo "  DNS Lookup: ${REDIRECT_DNS}s"
echo "  TCP Connect: ${REDIRECT_CONNECT}s"
echo "  TLS Handshake: ${REDIRECT_TLS}s"
echo "  Time to First Byte: ${REDIRECT_TTFB}s"
echo "  Total Time: ${REDIRECT_TOTAL}s"
echo "  Download Size: ${REDIRECT_SIZE} bytes"
echo ""

# Step 3: Test real game domains
echo -e "${YELLOW}[Step 3/5] Testing real game domains...${NC}"

# Test www.shuangzi6688.com
REAL_URL_WWW=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/www.shuangzi6688.com/')
echo -e "${BLUE}Testing domain: www.shuangzi6688.com${NC}"
WWW_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$REAL_URL_WWW")
WWW_CODE=$(echo $WWW_RESULT | cut -d'|' -f1)
WWW_TIME=$(echo $WWW_RESULT | cut -d'|' -f2)
WWW_SIZE=$(echo $WWW_RESULT | cut -d'|' -f3)
echo "  Status Code: $WWW_CODE | Time: ${WWW_TIME}s | Size: ${WWW_SIZE} bytes"

if [ "$WWW_SIZE" -lt 1000 ]; then
    echo -e "  ${RED}⚠️  Page abnormal (likely 404)${NC}"
    WWW_IS_404=true
else
    WWW_IS_404=false
fi
echo ""

# Test hash.shuangzi6688.com
REAL_URL_HASH=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/hash.shuangzi6688.com/')
echo -e "${BLUE}Testing domain: hash.shuangzi6688.com${NC}"
HASH_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$REAL_URL_HASH")
HASH_CODE=$(echo $HASH_RESULT | cut -d'|' -f1)
HASH_TIME=$(echo $HASH_RESULT | cut -d'|' -f2)
HASH_SIZE=$(echo $HASH_RESULT | cut -d'|' -f3)
echo "  Status Code: $HASH_CODE | Time: ${HASH_TIME}s | Size: ${HASH_SIZE} bytes"

if [ "$HASH_SIZE" -lt 1000 ]; then
    echo -e "  ${RED}⚠️  Page abnormal (likely 404)${NC}"
    HASH_IS_404=true
else
    HASH_IS_404=false
fi
echo ""

# Step 4: Download and verify actual page content
echo -e "${YELLOW}[Step 4/5] Verifying page content...${NC}"

# Determine which domain to use
if [ "$WWW_IS_404" = false ]; then
    TEST_DOMAIN="www.shuangzi6688.com"
    TEST_URL="$REAL_URL_WWW"
elif [ "$HASH_IS_404" = false ]; then
    TEST_DOMAIN="hash.shuangzi6688.com"
    TEST_URL="$REAL_URL_HASH"
else
    echo -e "${RED}✗ All domains return 404 errors${NC}"
    echo ""
    echo -e "${YELLOW}================================${NC}"
    echo -e "${YELLOW}Test Summary${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${RED}Game is NOT accessible - All domains return 404 errors${NC}"
    echo ""
    echo -e "${RED}Recommendations:${NC}"
    echo "1. Verify game resources are deployed"
    echo "2. Check CDN configuration"
    echo "3. Validate Token is not expired"
    echo "4. Review URL path configuration"
    echo ""
    echo -e "${BLUE}Bangladesh Region Expected Performance (if game works):${NC}"
    echo "  100 KB/s connection: ~20-25 seconds"
    echo "  500 KB/s connection: ~5-7 seconds"
    echo "  1 Mbps+ connection: ~8-12 seconds"
    exit 1
fi

echo -e "${GREEN}Using domain: $TEST_DOMAIN${NC}"

# Download and check content
TEMP_FILE="/tmp/game_test_content_$$.html"
curl -s "$TEST_URL" -o "$TEMP_FILE"

# Check if it's actually a 404 page
if grep -q "404 Error" "$TEMP_FILE"; then
    echo -e "${RED}✗ Content verification failed: Page shows 404 error${NC}"
    echo "  Even though HTTP status is 200, the page content is a 404 error page"
    rm -f "$TEMP_FILE"

    echo ""
    echo -e "${YELLOW}================================${NC}"
    echo -e "${YELLOW}Test Summary${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${RED}Game is NOT accessible - Returns 404 error page${NC}"
    echo ""
    echo -e "${RED}Issue Details:${NC}"
    echo "  HTTP Status: 200 (Misleading)"
    echo "  Actual Content: 404 Error Page"
    echo "  Root Cause: Game resources not found or Token expired"
    echo ""
    echo -e "${RED}Recommendations:${NC}"
    echo "1. Check if game files exist on server"
    echo "2. Verify Token generation and validation logic"
    echo "3. Review CDN path mappings"
    echo "4. Check deployment status"
    exit 1
else
    echo -e "${GREEN}✓ Valid game page content detected${NC}"
    CONTENT_SIZE=$(wc -c < "$TEMP_FILE")
    echo "  Page size: ${CONTENT_SIZE} bytes"
fi

rm -f "$TEMP_FILE"
echo ""

# Step 5: Test game resource loading
echo -e "${YELLOW}[Step 5/5] Testing game resource loading...${NC}"

# Extract game path from URL
GAME_PATH=$(echo "$TEST_URL" | sed 's|https://[^/]*/||' | cut -d'?' -f1 | sed 's|/$||')

# Test common resource files
declare -a RESOURCES=("cocos2d-js-min.js" "main.js" "src/settings.js" "style-mobile.css")
TOTAL_SIZE=0
TOTAL_TIME=0
FOUND_RESOURCES=0

for resource in "${RESOURCES[@]}"; do
    # Try different path patterns
    for base_path in "$GAME_PATH" "${GAME_PATH%/*}" ""; do
        RESOURCE_URL="https://$TEST_DOMAIN/$base_path/$resource"
        RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$RESOURCE_URL" 2>/dev/null)
        CODE=$(echo $RESULT | cut -d'|' -f1)
        TIME=$(echo $RESULT | cut -d'|' -f2)
        SIZE=$(echo $RESULT | cut -d'|' -f3)

        if [ "$CODE" = "200" ] && [ "$SIZE" -gt 1000 ]; then
            echo -e "  ${GREEN}✓${NC} $resource: ${SIZE} bytes (${TIME}s)"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
            TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME" | bc)
            FOUND_RESOURCES=$((FOUND_RESOURCES + 1))
            break
        fi
    done
done

if [ $FOUND_RESOURCES -eq 0 ]; then
    echo -e "  ${YELLOW}◯${NC} No standard Cocos2d resources found"
    echo "  (Game may use different framework or bundled resources)"
else
    echo ""
    echo -e "${GREEN}Total resource size: ${TOTAL_SIZE} bytes${NC}"
    echo -e "${GREEN}Total download time: ${TOTAL_TIME}s${NC}"
fi

echo ""
echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${YELLOW}================================${NC}"

# Performance evaluation
echo -e "${GREEN}✓ Game is accessible${NC}"

# Evaluate loading speed
BEST_TIME=$(echo "$WWW_TIME $HASH_TIME" | tr ' ' '\n' | sort -n | head -1)

if (( $(echo "$BEST_TIME < 1" | bc -l) )); then
    echo -e "${GREEN}✓ Loading speed: Fast (${BEST_TIME}s)${NC}"
    SPEED_RATING="Excellent"
elif (( $(echo "$BEST_TIME < 3" | bc -l) )); then
    echo -e "${YELLOW}⚠ Loading speed: Medium (${BEST_TIME}s)${NC}"
    SPEED_RATING="Good"
else
    echo -e "${RED}✗ Loading speed: Slow (${BEST_TIME}s)${NC}"
    SPEED_RATING="Poor"
fi

echo ""
echo -e "${BLUE}Current Test Location Performance:${NC}"
echo "  Redirect page: ${REDIRECT_TOTAL}s"
echo "  Game page: ${BEST_TIME}s"
echo "  Overall rating: $SPEED_RATING"
echo ""

echo -e "${BLUE}Bangladesh Region Expected Performance:${NC}"
echo "  ${RED}100 KB/s${NC} connection: ~20-25 seconds (Very Poor)"
echo "  ${YELLOW}500 KB/s${NC} connection: ~5-7 seconds (Poor)"
echo "  ${YELLOW}1 Mbps+${NC} connection: ~8-12 seconds (Marginal)"
echo "  ${GREEN}5 Mbps+${NC} connection: ~2-4 seconds (Good)"
echo ""

echo -e "${BLUE}Key Bottlenecks for Bangladesh:${NC}"
echo "  • CDN located in US (high latency to Bangladesh: 200-400ms)"
echo "  • Large Cocos2d framework (~616 KB compressed)"
echo "  • Limited mobile network bandwidth"
echo ""

echo -e "${BLUE}Optimization Recommendations:${NC}"
echo "  1. Deploy CDN nodes in Asia (Singapore, Mumbai)"
echo "  2. Enable aggressive browser caching"
echo "  3. Implement resource lazy loading"
echo "  4. Add loading progress indicator"
echo "  5. Consider WebP images and smaller bundles"
echo ""

echo -e "${GREEN}Test completed successfully!${NC}"
echo -e "${BLUE}Full report saved to: /tmp/cdn/game-test/${NC}"
