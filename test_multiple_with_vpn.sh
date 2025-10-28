#!/usr/bin/env bash

# Multiple Random Games Testing with VPN Workaround
# Usage: ./test_multiple_with_vpn.sh [number_of_games] [language]
# Example: ./test_multiple_with_vpn.sh 5 en-US

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
echo -e "${BLUE}║   Multiple Games Testing with VPN Workaround          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  API Whitelist Strategy${NC}"
echo ""
echo "This script will:"
echo "  1. Get URLs for ALL games WITHOUT VPN (white-listed IP)"
echo "  2. Save all URLs"
echo "  3. Ask you to connect VPN to Bangladesh"
echo "  4. Test all games WITH Bangladesh IP"
echo ""

# Validate number
if [ "$NUM_GAMES" -gt "${#GAME_TYPES[@]}" ]; then
    echo -e "${YELLOW}Warning: Requested $NUM_GAMES games, but only ${#GAME_TYPES[@]} available.${NC}"
    echo -e "${YELLOW}Testing all ${#GAME_TYPES[@]} games instead.${NC}"
    NUM_GAMES="${#GAME_TYPES[@]}"
fi

echo -e "${CYAN}Test Configuration:${NC}"
echo -e "  Number of games: ${GREEN}${NUM_GAMES}${NC}"
echo -e "  Language: ${GREEN}${LANG}${NC}"
echo -e "  Total available: ${#GAME_TYPES[@]} games"
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

# Get URLs for all games - using temp file instead of associative array
URLS_FILE="/tmp/game_urls_$$.txt"
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
        # Save to file: GAME_NAME|URL
        echo "${GAME}|${GAME_URL}" >> "$URLS_FILE"
    fi
    
    sleep 0.5
done

echo ""
SUCCESSFUL_COUNT=$(wc -l < "$URLS_FILE" | tr -d ' ')
FAILED_COUNT=${#FAILED_GAMES[@]}

echo -e "${CYAN}URL Retrieval Summary:${NC}"
echo -e "  Successful: ${GREEN}${SUCCESSFUL_COUNT}${NC}"
echo -e "  Failed: ${RED}${FAILED_COUNT}${NC}"

if [ "$SUCCESSFUL_COUNT" -eq 0 ]; then
    echo -e "${RED}No game URLs retrieved. Cannot continue.${NC}"
    rm -f "$URLS_FILE"
    exit 1
fi

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Failed games:${NC}"
    for game in "${FAILED_GAMES[@]}"; do
        echo "  - $game"
    done
fi

echo ""
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
VPN_COUNTRY=$(curl -s --max-time 5 "https://ipapi.co/${VPN_IP}/country_name/" 2>/dev/null)

echo -e "  Original IP: ${CURRENT_IP}"
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
        rm -f "$URLS_FILE"
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
echo -e "${YELLOW}[Step 5] Testing all games from Bangladesh IP...${NC}"
echo ""

START_TOTAL=$(date +%s.%N)
RESULTS_FILE="/tmp/vpn_test_results_$$.txt"
> "$RESULTS_FILE"

GAME_NUM=0

# Read URLs from file
while IFS='|' read -r GAME GAME_URL; do
    GAME_NUM=$((GAME_NUM + 1))
    
    echo -e "${MAGENTA}══════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Testing [$GAME_NUM/$SUCCESSFUL_COUNT]: ${GAME}${NC}"
    echo -e "${MAGENTA}══════════════════════════════════════════════════${NC}"

    # Build real game URL
    REAL_URL="https://www.shuangzi6688.com/ArcadeBingo/?ProductId=${PRODUCT_ID}&Lang=${LANG}&Token=${GAME_URL##*Token=}"

    # Display test URL
    echo -e "${CYAN}Test URL:${NC}"
    echo -e "  ${REAL_URL}"
    echo ""

    # Test HTML load
    TEST_START=$(date +%s.%N)
    HTML_RESULT=$(curl -s -w "|%{time_total}|%{size_download}|%{http_code}" -o /tmp/game_test_$$.html "$REAL_URL")
    HTML_TIME=$(echo "$HTML_RESULT" | cut -d'|' -f2)
    HTML_SIZE=$(echo "$HTML_RESULT" | cut -d'|' -f3)
    HTML_CODE=$(echo "$HTML_RESULT" | cut -d'|' -f4)
    
    if [ "$HTML_CODE" != "200" ] || grep -q "404 Error" /tmp/game_test_$$.html 2>/dev/null; then
        echo -e "  ${RED}✗ Failed (404 or Error)${NC}"
        echo "$GAME|ERROR|0|$HTML_CODE" >> "$RESULTS_FILE"
        rm -f /tmp/game_test_$$.html
        continue
    fi
    
    TEST_END=$(date +%s.%N)
    TOTAL_TIME=$(echo "$TEST_END - $TEST_START" | bc)
    
    echo -e "  ${GREEN}✓ Success${NC}"
    echo -e "  HTML: ${HTML_SIZE} bytes in ${HTML_TIME}s"
    echo -e "  Total Time: ${GREEN}${TOTAL_TIME}s${NC}"
    
    echo "$GAME|SUCCESS|$TOTAL_TIME|$HTML_CODE" >> "$RESULTS_FILE"
    
    rm -f /tmp/game_test_$$.html
    echo ""
    
    sleep 1
done < "$URLS_FILE"

END_TOTAL=$(date +%s.%N)
TOTAL_TEST_TIME=$(echo "$END_TOTAL - $START_TOTAL" | bc)

# Generate summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            FINAL TEST RESULTS SUMMARY                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Test Information:${NC}"
echo -e "  Original IP (API): ${CURRENT_IP}"
echo -e "  Testing IP (VPN): ${GREEN}${VPN_IP}${NC}"
echo -e "  Location: ${VPN_COUNTRY}"
if [ "$IS_BANGLADESH" = true ]; then
    echo -e "  ${GREEN}✓ Real Bangladesh Testing${NC}"
fi
echo -e "  Test Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

SUCCESS_COUNT=$(grep "SUCCESS" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d ' ')
ERROR_COUNT=$(grep "ERROR" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_TESTED=$((SUCCESS_COUNT + ERROR_COUNT))

echo -e "${CYAN}Overall Statistics:${NC}"
echo -e "  Total games tested: ${YELLOW}${TOTAL_TESTED}${NC}"
echo -e "  Successful: ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "  Failed: ${RED}${ERROR_COUNT}${NC}"

if [ $TOTAL_TESTED -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=1; $SUCCESS_COUNT * 100 / $TOTAL_TESTED" | bc)
    echo -e "  Success rate: ${GREEN}${SUCCESS_RATE}%${NC}"
fi

echo -e "  Total test time: ${TOTAL_TEST_TIME}s"
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${CYAN}Successful Games (with load times):${NC}"
    grep "SUCCESS" "$RESULTS_FILE" | while IFS='|' read -r game status time code; do
        printf "  ${GREEN}✓${NC} %-30s %6.3fs\n" "$game" "$time"
    done
    echo ""
    
    AVG_TIME=$(grep "SUCCESS" "$RESULTS_FILE" | cut -d'|' -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.3f", sum/count; else print "0"}')
    echo -e "  ${CYAN}Average load time: ${YELLOW}${AVG_TIME}s${NC}"
    
    AVG_INT=$(printf "%.0f" "$AVG_TIME")
    if [ "$AVG_INT" -lt 3 ]; then
        RATING="${GREEN}Excellent${NC}"
    elif [ "$AVG_INT" -lt 5 ]; then
        RATING="${GREEN}Good${NC}"
    elif [ "$AVG_INT" -lt 10 ]; then
        RATING="${YELLOW}Fair${NC}"
    else
        RATING="${RED}Poor${NC}"
    fi
    
    echo -e "  ${CYAN}Overall Performance: ${RATING}${NC}"
fi

if [ $ERROR_COUNT -gt 0 ]; then
    echo ""
    echo -e "${CYAN}Failed Games:${NC}"
    grep "ERROR" "$RESULTS_FILE" | while IFS='|' read -r game status time code; do
        echo -e "  ${RED}✗${NC} $game (HTTP $code)"
    done
fi

echo ""
echo -e "${GREEN}✓ Multiple games test completed!${NC}"
echo ""
echo -e "${CYAN}Detailed results saved to:${NC} ${RESULTS_FILE}"

# Clean up
rm -f "$URLS_FILE"
