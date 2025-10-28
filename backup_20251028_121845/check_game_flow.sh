#!/bin/bash
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"
GAME_TYPE="ArcadeBingo"
LANG="en-US"

generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

echo "Step 1: Getting game URL from API..."
SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME_TYPE\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

echo "API Response:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo "Failed to get game URL"
    exit 1
fi

echo ""
echo "Step 2: Fetching initial page..."
REAL_URL="https://www.shuangzi6688.com/ArcadeBingo/?ProductId=${PRODUCT_ID}&Lang=${LANG}&Token=${GAME_URL##*Token=}"
echo "URL: $REAL_URL"

curl -s "$REAL_URL" -o /tmp/game_page.html

echo ""
echo "Step 3: Analyzing page content..."
echo "Page size: $(wc -c < /tmp/game_page.html) bytes"
echo ""

echo "Looking for 'CLICK' or 'PLAY' text..."
grep -i "click\|play" /tmp/game_page.html | head -10

echo ""
echo "Looking for game loading scripts..."
grep -o 'src="[^"]*\.js"' /tmp/game_page.html | head -10

echo ""
echo "Checking for canvas or game container..."
grep -i "canvas\|game.*container\|cocos" /tmp/game_page.html | head -5

rm -f /tmp/game_page.html
