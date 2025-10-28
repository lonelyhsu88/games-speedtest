#!/usr/bin/env bash

# Test script to verify HTTP status codes and JSON loading
# Tests one game to verify the new features work correctly

echo "════════════════════════════════════════════════════════"
echo "Testing HTTP Status Display and JSON Loading"
echo "════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# API settings
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"
USERNAME="optest01"
PRODUCT_ID="ELS"
LANG="en-US"
GAME="StandAloneHilo"

# Generate sequence
generate_seq() {
    echo "$(date +%s)$(( RANDOM % 1000 ))"
}

echo -e "${CYAN}Getting game URL from API...${NC}"
SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo -e "${RED}✗ Failed to get game URL${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Got game URL${NC}"
echo ""

# Convert URL and extract paths
REAL_URL=$(echo "$GAME_URL" | sed 's|jump.shuangzi6666.com|www.shuangzi6688.com|')
GAME_PATH=$(echo "$REAL_URL" | grep -o '/[^?]*' | head -1)
BASE_URL="https://www.shuangzi6688.com"

echo -e "${YELLOW}Test URL:${NC}"
echo "  $REAL_URL"
echo ""
echo -e "${YELLOW}Game Path:${NC} $GAME_PATH"
echo -e "${YELLOW}Base URL:${NC} $BASE_URL"
echo ""

# Test Phase 1: HTML
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[1/5] Testing HTML loading...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESULT=$(curl -o /tmp/game.html -s \
  -H "Cache-Control: no-cache, no-store, must-revalidate" \
  -H "Pragma: no-cache" \
  -H "Expires: 0" \
  -w "%{time_total}|%{size_download}|%{http_code}" "$REAL_URL")

TIME=$(echo $RESULT | cut -d'|' -f1)
SIZE=$(echo $RESULT | cut -d'|' -f2)
CODE=$(echo $RESULT | cut -d'|' -f3)
SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)

echo -e "  ${GREEN}✓${NC} HTML: ${SIZE_KB} KB (HTTP ${CODE}) in ${TIME}s"
echo ""

# Test Phase 2: CSS
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[2/5] Testing CSS loading...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CSS_FILES=$(cat /tmp/game.html | grep -o '<link[^>]*rel="stylesheet"[^>]*href="[^"]*"' | grep -o 'href="[^"]*"' | sed 's/href="//;s/"$//')

CSS_COUNT=0
CSS_TIME=0

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
        echo -e "  ${GREEN}✓${NC} ${css##*/}: ${SIZE_KB} KB (HTTP ${CODE}) in ${TIME}s"
        CSS_TIME=$(echo "$CSS_TIME + $TIME" | bc)
        CSS_COUNT=$((CSS_COUNT + 1))
    else
        echo -e "  ${RED}✗${NC} ${css##*/}: HTTP ${CODE}"
    fi
done

echo -e "  ${GREEN}✓${NC} Phase 2 complete: $CSS_COUNT files in ${CSS_TIME}s"
echo ""

# Test Phase 3: Initial JS
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[3/5] Testing Initial JS loading...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INIT_JS_FILES=$(cat /tmp/game.html | grep -o '<script[^>]*src="[^"]*"' | grep -o 'src="[^"]*"' | sed 's/src="//;s/"$//' | grep -v 'cocos2d-js' | head -3)

INIT_JS_COUNT=0
INIT_JS_TIME=0

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
        echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (HTTP ${CODE}) in ${TIME}s"
        INIT_JS_TIME=$(echo "$INIT_JS_TIME + $TIME" | bc)
        INIT_JS_COUNT=$((INIT_JS_COUNT + 1))
    else
        echo -e "  ${RED}✗${NC} ${js##*/}: HTTP ${CODE}"
    fi
done

echo -e "  ${GREEN}✓${NC} Phase 3 complete: $INIT_JS_COUNT files in ${INIT_JS_TIME}s"
echo ""

# Test Phase 5: Bundles (with config.json)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}[5/5] Testing Cocos Creator bundles (config.json + index.js)...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
        echo -e "    ${GREEN}✓${NC} config.json: ${SIZE_KB} KB (HTTP ${CODE}) in ${TIME}s"
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
        echo -e "    ${GREEN}✓${NC} index.js: ${SIZE_KB} KB (HTTP ${CODE}) in ${TIME}s"
        BUNDLE_TIME=$(echo "$BUNDLE_TIME + $TIME" | bc)
        BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
    else
        echo -e "    ${RED}✗${NC} index.js: HTTP ${CODE}"
    fi
done

echo -e "  ${GREEN}✓${NC} Phase 5 complete: $BUNDLE_COUNT files in ${BUNDLE_TIME}s"
echo ""

# Summary
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Test Complete${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Summary:"
echo "  HTML:       1 file  (${SIZE_KB} KB)"
echo "  CSS:        $CSS_COUNT files"
echo "  Initial JS: $INIT_JS_COUNT files"
echo "  Bundles:    $BUNDLE_COUNT files (including config.json)"
echo ""
echo "All files show HTTP status codes and file sizes! ✅"

rm -f /tmp/game.html
