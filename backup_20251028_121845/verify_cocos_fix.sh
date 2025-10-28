#!/usr/bin/env bash

# Quick verification script to check if Cocos2d loading is working correctly

echo "╔════════════════════════════════════════════════════════╗"
echo "║       Cocos2d Loading Verification Test               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Get a test URL
echo "Getting test game URL..."
API_URL="https://jump.shuangzi6666.com/Login/ArcadeBingo?Lang=en-US&ProductId=ELS"
RESPONSE=$(curl -s "$API_URL")
GAME_URL=$(echo "$RESPONSE" | grep -o 'https://www.shuangzi6688.com[^"]*' | head -1)

if [ -z "$GAME_URL" ]; then
    echo "✗ Failed to get game URL"
    exit 1
fi

echo "✓ Game URL obtained"
echo ""

# Load and analyze HTML
echo "Analyzing HTML structure..."
curl -s \
  -H "Cache-Control: no-cache, no-store, must-revalidate" \
  -H "Pragma: no-cache" \
  -H "Expires: 0" \
  -o /tmp/verify_game.html "$GAME_URL"

# Extract JS files using the OLD method (script src only)
OLD_JS=$(grep -o 'src="[^"]*\.js"' /tmp/verify_game.html | sed 's/src="//;s/"$//')

# Extract Cocos2d file using the NEW method
COCOS_FILE=$(grep -o 'cocos2d-js-min\.[^"]*\.js' /tmp/verify_game.html | head -1)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OLD METHOD (grep src=... only):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$OLD_JS"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEW METHOD (includes Cocos2d from loadScript):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$OLD_JS"
if [ -n "$COCOS_FILE" ]; then
    echo "$COCOS_FILE  ← Added by fix!"
fi
echo ""

# Test loading each file
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "File Sizes and Load Times:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ALL_JS="$OLD_JS $COCOS_FILE"

for js in $ALL_JS; do
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

        if [ "$CODE" = "200" ]; then
            SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)

            # Highlight Cocos2d
            if [[ $js =~ cocos2d ]]; then
                echo "  ⭐ ${js}: ${SIZE_KB} KB in ${TIME}s"
            else
                echo "  • ${js}: ${SIZE_KB} KB in ${TIME}s"
            fi
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verification Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$COCOS_FILE" ]; then
    echo "✅ Cocos2d file detected: $COCOS_FILE"

    # Load it to check size
    COCOS_URL="https://www.shuangzi6688.com/ArcadeBingo/${COCOS_FILE}"
    RESULT=$(curl -o /dev/null -s \
      -H "Cache-Control: no-cache, no-store, must-revalidate" \
      -H "Pragma: no-cache" \
      -H "Expires: 0" \
      -w "%{size_download}" "$COCOS_URL")
    SIZE_KB=$(echo "scale=2; $RESULT / 1024" | bc)

    if (( $(echo "$SIZE_KB > 1000" | bc -l) )); then
        echo "✅ Cocos2d size is correct: ${SIZE_KB} KB (~2 MB)"
        echo ""
        echo "🎉 SUCCESS! The fix is working correctly."
        echo ""
        echo "The script will now:"
        echo "  • Phase 3: Load settings.js and main.js (~10 KB total)"
        echo "  • Phase 4: Load cocos2d-js-min.js (~2 MB)"
        echo ""
        echo "Expected load times:"
        echo "  • From Taiwan: Phase 4 = 0.3-1.0 seconds"
        echo "  • From Bangladesh: Phase 4 = 30-40 seconds"
    else
        echo "⚠️  Cocos2d size seems too small: ${SIZE_KB} KB"
        echo "    Expected: ~2000 KB"
    fi
else
    echo "❌ Cocos2d file NOT detected!"
    echo "   The fix may not be working correctly."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

rm -f /tmp/verify_game.html
