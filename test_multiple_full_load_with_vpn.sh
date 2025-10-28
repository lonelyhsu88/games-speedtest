#!/usr/bin/env bash

# Multiple Games FULL Loading Test with VPN Workaround
# Tests complete game loading (HTML + CSS + JS + Cocos2d) for multiple games

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

NUM_GAMES="${1:-3}"
LANG="${2:-en-US}"
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"

# All available game types
GAME_TYPES=(
    "ArcadeBingo" "BonusBingo" "CaribbeanBingo" "CaveBingo"
    "EggHuntBingo" "LostRuins" "MagicBingo" "MapleBingo"
    "OdinBingo" "Steampunk" "Steampunk2"
    "MultiPlayerAviator" "MultiPlayerAviator2" "MultiPlayerBoomersGR"
    "MultiPlayerCrash" "MultiPlayerCrashCL" "MultiPlayerCrashGR"
    "MultiPlayerCrashNE" "MultiPlayerMultiHilo"
    "StandAloneDiamonds" "StandAloneDice" "StandAloneDragonTower"
    "StandAloneEgyptHilo" "StandAloneHilo" "StandAloneHiloCL"
    "StandAloneHiloGR" "StandAloneHiloNE" "StandAloneKeno"
    "StandAloneLimbo" "StandAloneLimboCL" "StandAloneLimboGR"
    "StandAloneLimboNE" "StandAloneLuckyDropCOC" "StandAloneLuckyDropCOC2"
    "StandAloneLuckyDropGX" "StandAloneLuckyDropOLY" "StandAloneLuckyHilo"
    "StandAloneMines" "StandAloneMinesCA" "StandAloneMinesCL"
    "StandAloneMinesGR" "StandAloneMinesMA" "StandAloneMinesNE"
    "StandAloneMinesPM" "StandAloneMinesRaider" "StandAloneMinesSC"
    "StandAlonePlinko" "StandAlonePlinkoCL" "StandAlonePlinkoGR"
    "StandAlonePlinkoNE" "StandAloneVideoPoker" "StandAloneWheel"
    "StandAloneForestTeaParty"
)

generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

shuffle_and_pick() {
    local n=$1
    shift
    local arr=("$@")
    for i in "${arr[@]}"; do
        echo "$RANDOM $i"
    done | sort -n | cut -d' ' -f2- | head -n "$n"
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Multiple Games FULL Loading Test (with VPN)         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  Complete Game Loading Test${NC}"
echo ""
echo "This script will:"
echo "  1. Get URLs for ALL games WITHOUT VPN (white-listed IP)"
echo "  2. Ask you to connect VPN to Bangladesh"
echo "  3. Test COMPLETE loading for each game (5 phases):"
echo "     • Phase 1: HTML page"
echo "     • Phase 2: CSS files"
echo "     • Phase 3: Initial JavaScript (settings, main)"
echo "     • Phase 4: Game engines (Cocos2d ~2MB, Physics ~200KB)"
echo "     • Phase 5: Cocos Creator bundles (internal, resources, main)"
echo "  4. Show detailed statistics"
echo ""

# Validate number
if [ "$NUM_GAMES" -gt "${#GAME_TYPES[@]}" ]; then
    echo -e "${YELLOW}Warning: Requested $NUM_GAMES games, but only ${#GAME_TYPES[@]} available.${NC}"
    NUM_GAMES="${#GAME_TYPES[@]}"
fi

echo -e "${CYAN}Test Configuration:${NC}"
echo -e "  Number of games: ${GREEN}${NUM_GAMES}${NC}"
echo -e "  Language: ${GREEN}${LANG}${NC}"
echo ""

# Check current IP
echo -e "${YELLOW}[Step 1] Checking your current IP (should be whitelisted)...${NC}"
CURRENT_IP=$(curl -s --max-time 3 "https://api.ipify.org" 2>/dev/null)
echo -e "  Your IP: ${GREEN}${CURRENT_IP}${NC}"
echo ""

# Select random games
echo -e "${YELLOW}[Step 2] Selecting ${NUM_GAMES} random games...${NC}"
SELECTED_GAMES=($(shuffle_and_pick "$NUM_GAMES" "${GAME_TYPES[@]}"))

echo -e "${GREEN}Selected games:${NC}"
for i in "${!SELECTED_GAMES[@]}"; do
    echo "  $((i+1)). ${SELECTED_GAMES[$i]}"
done
echo ""

# Get URLs for all games
URLS_FILE="/tmp/game_urls_full_$$.txt"
> "$URLS_FILE"

echo -e "${YELLOW}[Step 3] Getting game URLs (using whitelisted IP)...${NC}"
echo ""

FAILED_GAMES=()

for i in "${!SELECTED_GAMES[@]}"; do
    GAME="${SELECTED_GAMES[$i]}"
    echo -e "${CYAN}[$((i+1))/${NUM_GAMES}] Getting URL for ${GAME}...${NC}"

    SEQ=$(generate_seq)
    PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME\",\"lang\":\"$LANG\"}"
    MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

    RESPONSE=$(curl -s -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -H "els-access-key: $MD5" \
      -d "$PAYLOAD")

    GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

    if [ -z "$GAME_URL" ]; then
        echo -e "  ${RED}✗ Failed${NC}"
        FAILED_GAMES+=("$GAME")
    else
        echo -e "  ${GREEN}✓ Success${NC}"
        echo "${GAME}|${GAME_URL}" >> "$URLS_FILE"
    fi

    sleep 0.5
done

echo ""
SUCCESSFUL_COUNT=$(wc -l < "$URLS_FILE" | tr -d ' ')

if [ "$SUCCESSFUL_COUNT" -eq 0 ]; then
    echo -e "${RED}No game URLs retrieved. Cannot continue.${NC}"
    rm -f "$URLS_FILE"
    exit 1
fi

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   ALL GAME URLS READY - NOW CONNECT VPN                ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}         NOW CONNECT YOUR VPN TO BANGLADESH             ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Please:"
echo "  1. Connect your VPN to Bangladesh server"
echo "  2. Press Enter when ready to continue testing..."
echo ""

read -p "Press Enter to continue (or Ctrl+C to exit)..."

echo ""
echo -e "${YELLOW}[Step 4] Verifying VPN connection...${NC}"

VPN_IP=$(curl -s --max-time 5 "https://api.ipify.org" 2>/dev/null)

echo -e "  Original IP: ${CURRENT_IP}"
echo -e "  New IP: ${GREEN}${VPN_IP}${NC}"
echo ""

if [ "$VPN_IP" = "$CURRENT_IP" ]; then
    echo -e "${YELLOW}⚠️  Warning: Your IP hasn't changed!${NC}"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        rm -f "$URLS_FILE"
        exit 0
    fi
fi

echo ""
echo -e "${YELLOW}[Step 5] Testing COMPLETE game loading from Bangladesh IP...${NC}"
echo -e "${YELLOW}This will take a while (30-40s per game for Cocos2d engine)${NC}"
echo ""

START_TOTAL=$(date +%s.%N)
RESULTS_FILE="/tmp/vpn_full_test_results_$$.txt"
> "$RESULTS_FILE"

GAME_NUM=0

# Read URLs from file
while IFS='|' read -r GAME GAME_URL; do
    GAME_NUM=$((GAME_NUM + 1))

    echo -e "${MAGENTA}══════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Testing [$GAME_NUM/$SUCCESSFUL_COUNT]: ${GAME}${NC}"
    echo -e "${MAGENTA}══════════════════════════════════════════════════${NC}"

    # Convert jump.shuangzi6666.com to www.shuangzi6688.com but keep the game path
    # Original: https://jump.shuangzi6666.com/Hash/StandAloneHilo/?...
    # Convert:  https://www.shuangzi6688.com/Hash/StandAloneHilo/?...
    REAL_URL=$(echo "$GAME_URL" | sed 's|jump.shuangzi6666.com|www.shuangzi6688.com|')

    # Extract the game path (e.g., /Hash/StandAloneHilo/ or /Bingo/ArcadeBingo/)
    GAME_PATH=$(echo "$REAL_URL" | grep -o '/[^?]*' | head -1)

    # Extract base URL without path
    BASE_URL="https://www.shuangzi6688.com"

    echo -e "${CYAN}Test URL:${NC}"
    echo -e "  ${REAL_URL}"
    echo ""

    GAME_START=$(date +%s.%N)

    # Load HTML
    echo -e "${CYAN}[1/4] Loading HTML...${NC}"
    HTML_RESULT=$(curl -s \
      -H "Cache-Control: no-cache, no-store, must-revalidate" \
      -H "Pragma: no-cache" \
      -H "Expires: 0" \
      -w "|%{time_total}|%{size_download}|%{http_code}" \
      -o /tmp/game_test_full_$$.html "$REAL_URL")
    HTML_TIME=$(echo "$HTML_RESULT" | cut -d'|' -f2)
    HTML_SIZE=$(echo "$HTML_RESULT" | cut -d'|' -f3)
    HTML_CODE=$(echo "$HTML_RESULT" | cut -d'|' -f4)

    if [ "$HTML_CODE" != "200" ]; then
        echo -e "  ${RED}✗ Failed (HTTP $HTML_CODE)${NC}"
        echo "$GAME|ERROR|0|$HTML_CODE" >> "$RESULTS_FILE"
        rm -f /tmp/game_test_full_$$.html
        continue
    fi

    echo -e "  ${GREEN}✓${NC} HTML: ${HTML_SIZE} bytes in ${HTML_TIME}s"

    # Extract resources from HTML
    JS_FILES=$(grep -o 'src="[^"]*\.js"' /tmp/game_test_full_$$.html | sed 's/src="//;s/"$//')
    CSS_FILES=$(grep -o 'href="[^"]*\.css"' /tmp/game_test_full_$$.html | sed 's/href="//;s/"$//')

    # Extract ALL dynamically loaded JS files from loadScript() calls
    # This catches any JS loaded via JavaScript, not just Cocos2d and Physics
    # Pattern: loadScript(...".js") → extract the filename
    DYNAMIC_JS=$(grep -o 'loadScript([^)]*"[^"]*\.js"' /tmp/game_test_full_$$.html | \
                 sed 's/.*"\([^"]*\.js\)".*/\1/' | \
                 grep -v 'debug' | \
                 tr '\n' ' ')

    # Add all dynamically loaded files to JS_FILES
    if [ -n "$DYNAMIC_JS" ]; then
        JS_FILES="$JS_FILES $DYNAMIC_JS"
    fi

    rm -f /tmp/game_test_full_$$.html

    # Load CSS
    echo -e "${CYAN}[2/5] Loading CSS files...${NC}"
    CSS_TIME=0
    CSS_COUNT=0
    for css in $CSS_FILES; do
        if [[ ! $css =~ ^http ]]; then
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
                echo -e "  ${GREEN}✓${NC} ${css##*/}: ${SIZE_KB} KB (HTTP $CODE) in ${TIME}s"
                CSS_TIME=$(echo "$CSS_TIME + $TIME" | bc)
                CSS_COUNT=$((CSS_COUNT + 1))
            else
                echo -e "  ${RED}✗${NC} ${css##*/}: HTTP $CODE"
            fi
        fi
    done
    echo -e "  ${GREEN}✓${NC} Phase 2 complete: $CSS_COUNT files in ${CSS_TIME}s"

    # Load initial JS (settings.js, main.js - NOT Cocos2d)
    echo -e "${CYAN}[3/5] Loading initial JavaScript...${NC}"
    INIT_JS_TIME=0
    INIT_JS_COUNT=0
    for js in $JS_FILES; do
        # Skip Cocos2d engine (load it in Phase 4)
        if [[ $js =~ cocos2d ]]; then
            continue
        fi
        if [[ ! $js =~ ^http ]]; then
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
                echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (HTTP $CODE) in ${TIME}s"
                INIT_JS_TIME=$(echo "$INIT_JS_TIME + $TIME" | bc)
                INIT_JS_COUNT=$((INIT_JS_COUNT + 1))
            else
                echo -e "  ${RED}✗${NC} ${js##*/}: HTTP $CODE"
            fi
        fi
    done
    echo -e "  ${GREEN}✓${NC} Phase 3 complete: $INIT_JS_COUNT files in ${INIT_JS_TIME}s"

    # Load Cocos2d engine and Physics engine (the big files that take time)
    echo -e "${CYAN}[4/5] Loading game engines (Cocos2d + Physics)...${NC}"
    COCOS_TIME=0
    ENGINE_COUNT=0
    ENGINE_FOUND=0

    for js in $JS_FILES; do
        # Only load Cocos2d and Physics engine files
        if [[ ! $js =~ cocos2d ]] && [[ ! $js =~ physics ]]; then
            continue
        fi
        ENGINE_FOUND=1
        if [[ ! $js =~ ^http ]]; then
            JS_URL="${BASE_URL}${GAME_PATH}${js}"

            # Different message for different files
            if [[ $js =~ cocos2d ]]; then
                echo -e "  ${YELLOW}⏳ Loading ${js##*/} (~2MB, this takes 30-40s)...${NC}"
            elif [[ $js =~ physics ]]; then
                echo -e "  ${YELLOW}⏳ Loading ${js##*/} (~200KB)...${NC}"
            fi

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
                echo -e "  ${GREEN}✓${NC} ${js##*/}: ${SIZE_KB} KB (HTTP $CODE) in ${YELLOW}${TIME}s${NC}"
                COCOS_TIME=$(echo "$COCOS_TIME + $TIME" | bc)
                ENGINE_COUNT=$((ENGINE_COUNT + 1))
            else
                echo -e "  ${RED}✗${NC} Failed to load ${js##*/} (HTTP $CODE)"
            fi
        fi
    done

    echo -e "  ${GREEN}✓${NC} Phase 4 complete: $ENGINE_COUNT engine files in ${COCOS_TIME}s"

    # Warning if engines were not found
    if [ $ENGINE_FOUND -eq 0 ]; then
        echo -e "  ${YELLOW}⚠${NC} Warning: Game engine files not found in HTML"
        COCOS_TIME=0
    fi

    # Load Cocos Creator bundles (resources that load after game engine starts)
    echo -e "${CYAN}[5/5] Loading Cocos Creator bundles (config.json + index.js)...${NC}"
    BUNDLE_TIME=0
    BUNDLE_COUNT=0

    # Cocos Creator bundles (internal, resources, main)
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
            echo -e "    ${GREEN}✓${NC} config.json: ${SIZE_KB} KB (HTTP $CODE) in ${TIME}s"
            BUNDLE_TIME=$(echo "$BUNDLE_TIME + $TIME" | bc)
            BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
        else
            echo -e "    ${YELLOW}⚠${NC} config.json: HTTP $CODE (may not exist)"
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
            echo -e "    ${GREEN}✓${NC} index.js: ${SIZE_KB} KB (HTTP $CODE) in ${TIME}s"
            BUNDLE_TIME=$(echo "$BUNDLE_TIME + $TIME" | bc)
            BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
        else
            echo -e "    ${RED}✗${NC} index.js: HTTP $CODE"
        fi
    done

    echo -e "  ${GREEN}✓${NC} Phase 5 complete: $BUNDLE_COUNT files in ${BUNDLE_TIME}s"

    GAME_END=$(date +%s.%N)
    TOTAL_TIME=$(echo "$GAME_END - $GAME_START" | bc)

    echo ""
    echo -e "${GREEN}✓ Complete loading finished${NC}"
    echo -e "  Total Time: ${YELLOW}${TOTAL_TIME}s${NC}"
    echo ""

    # Write results with file counts: HTML time, CSS time, Init JS time, Engine time, Bundle time, HTML count (always 1), CSS count, JS count, Engine count, Bundle count
    echo "$GAME|SUCCESS|$TOTAL_TIME|$HTML_CODE|${HTML_TIME}|${CSS_TIME}|${INIT_JS_TIME}|${COCOS_TIME}|${BUNDLE_TIME}|1|${CSS_COUNT}|${INIT_JS_COUNT}|${ENGINE_COUNT}|${BUNDLE_COUNT}" >> "$RESULTS_FILE"

    sleep 1
done < "$URLS_FILE"

END_TOTAL=$(date +%s.%N)
TOTAL_TEST_TIME=$(echo "$END_TOTAL - $START_TOTAL" | bc)

# Generate summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        COMPLETE LOADING TEST RESULTS SUMMARY           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

SUCCESS_COUNT=$(grep "SUCCESS" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d ' ')
ERROR_COUNT=$(grep "ERROR" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_TESTED=$((SUCCESS_COUNT + ERROR_COUNT))

echo -e "${CYAN}Test Information:${NC}"
echo -e "  Original IP: ${CURRENT_IP}"
echo -e "  Testing IP: ${GREEN}${VPN_IP}${NC}"
echo -e "  Games tested: ${TOTAL_TESTED}"
echo ""

echo -e "${CYAN}Overall Statistics:${NC}"
echo -e "  Successful: ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "  Failed: ${RED}${ERROR_COUNT}${NC}"
echo -e "  Success rate: $(echo "scale=1; $SUCCESS_COUNT * 100 / $TOTAL_TESTED" | bc)%"
echo -e "  Total test time: ${TOTAL_TEST_TIME}s"
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${CYAN}Complete Loading Times (all 5 phases):${NC}"
    grep "SUCCESS" "$RESULTS_FILE" | while IFS='|' read -r game status time code html css initjs cocos bundle htmlc cssc jsc enginc bundlc; do
        printf "  ${GREEN}✓${NC} %-30s ${YELLOW}%7.2fs${NC}\n" "$game" "$time"
        printf "     HTML:%.2fs (1 file) | CSS:%.2fs (%s files) | JS:%.2fs (%s files) | Engines:%.2fs (%s files) | Bundles:%.2fs (%s files)\n" \
               "$html" "$css" "$cssc" "$initjs" "$jsc" "$cocos" "$enginc" "$bundle" "$bundlc"
    done
    echo ""

    AVG_TIME=$(grep "SUCCESS" "$RESULTS_FILE" | cut -d'|' -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
    echo -e "  ${CYAN}Average COMPLETE load time: ${YELLOW}${AVG_TIME}s${NC}"

    # This is the real loading time users experience!
    AVG_INT=$(printf "%.0f" "$AVG_TIME")
    if [ "$AVG_INT" -lt 10 ]; then
        RATING="${GREEN}Good${NC}"
    elif [ "$AVG_INT" -lt 20 ]; then
        RATING="${YELLOW}Fair${NC}"
    elif [ "$AVG_INT" -lt 40 ]; then
        RATING="${YELLOW}Poor${NC}"
    else
        RATING="${RED}Very Poor${NC}"
    fi

    echo -e "  ${CYAN}Overall Performance: ${RATING}${NC}"
fi

echo ""
echo -e "${GREEN}✓ Complete loading test completed!${NC}"
echo ""

# Clean up
rm -f "$URLS_FILE"
rm -f "$RESULTS_FILE"
