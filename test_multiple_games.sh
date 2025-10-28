#!/bin/bash

# Multiple Random Games Performance Testing Script
# Usage: ./test_multiple_games.sh [number_of_games] [language]
# Example: ./test_multiple_games.sh 5 en-US

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
NUM_GAMES="${1:-3}"
LANG="${2:-en-US}"
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"

# All available game types
GAME_TYPES=(
    "ArcadeBingo"
    "BonusBingo"
    "CaribbeanBingo"
    "CaveBingo"
    "EggHuntBingo"
    "LostRuins"
    "MagicBingo"
    "MapleBingo"
    "OdinBingo"
    "Steampunk"
    "Steampunk2"
    "MultiPlayerAviator"
    "MultiPlayerAviator2"
    "MultiPlayerBoomersGR"
    "MultiPlayerCrash"
    "MultiPlayerCrashCL"
    "MultiPlayerCrashGR"
    "MultiPlayerCrashNE"
    "MultiPlayerMultiHilo"
    "StandAloneDiamonds"
    "StandAloneDice"
    "StandAloneDragonTower"
    "StandAloneEgyptHilo"
    "StandAloneHilo"
    "StandAloneHiloCL"
    "StandAloneHiloGR"
    "StandAloneHiloNE"
    "StandAloneKeno"
    "StandAloneLimbo"
    "StandAloneLimboCL"
    "StandAloneLimboGR"
    "StandAloneLimboNE"
    "StandAloneLuckyDropCOC"
    "StandAloneLuckyDropCOC2"
    "StandAloneLuckyDropGX"
    "StandAloneLuckyDropOLY"
    "StandAloneLuckyHilo"
    "StandAloneMines"
    "StandAloneMinesCA"
    "StandAloneMinesCL"
    "StandAloneMinesGR"
    "StandAloneMinesMA"
    "StandAloneMinesNE"
    "StandAloneMinesPM"
    "StandAloneMinesRaider"
    "StandAloneMinesSC"
    "StandAlonePlinko"
    "StandAlonePlinkoCL"
    "StandAlonePlinkoGR"
    "StandAlonePlinkoNE"
    "StandAloneVideoPoker"
    "StandAloneWheel"
    "StandAloneForestTeaParty"
)

# Generate random sequence
generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

# Shuffle array and pick N elements
shuffle_and_pick() {
    local n=$1
    shift
    local arr=("$@")
    local shuffled=()

    # Shuffle using random sort
    for i in "${arr[@]}"; do
        echo "$RANDOM $i"
    done | sort -n | cut -d' ' -f2- | head -n "$n"
}

# Test single game
test_game() {
    local game_type=$1
    local game_num=$2
    local total=$3

    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Testing Game [$game_num/$total]: $game_type${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════${NC}"

    # Get game URL
    SEQ=$(generate_seq)
    PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$game_type\",\"lang\":\"$LANG\"}"
    MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

    RESPONSE=$(curl -s -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -H "els-access-key: $MD5" \
      -d "$PAYLOAD")

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ API request failed${NC}"
        return 1
    fi

    GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

    if [ -z "$GAME_URL" ]; then
        echo -e "${RED}✗ Failed to get game URL${NC}"
        return 1
    fi

    echo -e "${CYAN}Game URL:${NC} $GAME_URL"

    # Test both domains
    REAL_URL_WWW=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/www.shuangzi6688.com/')
    REAL_URL_HASH=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/hash.shuangzi6688.com/')

    echo ""
    echo -e "${CYAN}Test URL (www):${NC}"
    echo -e "  ${REAL_URL_WWW}"
    echo ""
    echo -e "${YELLOW}Testing www.shuangzi6688.com...${NC}"
    WWW_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$REAL_URL_WWW")
    WWW_CODE=$(echo $WWW_RESULT | cut -d'|' -f1)
    WWW_TIME=$(echo $WWW_RESULT | cut -d'|' -f2)
    WWW_SIZE=$(echo $WWW_RESULT | cut -d'|' -f3)

    if [ "$WWW_SIZE" -lt 1000 ]; then
        echo -e "  Status: ${RED}404 Error${NC} | Time: ${WWW_TIME}s"
        WWW_STATUS="404"
    else
        echo -e "  Status: ${GREEN}OK${NC} | Time: ${WWW_TIME}s | Size: ${WWW_SIZE} bytes"
        WWW_STATUS="OK"
    fi

    echo -e "${YELLOW}Testing hash.shuangzi6688.com...${NC}"
    HASH_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$REAL_URL_HASH")
    HASH_CODE=$(echo $HASH_RESULT | cut -d'|' -f1)
    HASH_TIME=$(echo $HASH_RESULT | cut -d'|' -f2)
    HASH_SIZE=$(echo $HASH_RESULT | cut -d'|' -f3)

    if [ "$HASH_SIZE" -lt 1000 ]; then
        echo -e "  Status: ${RED}404 Error${NC} | Time: ${HASH_TIME}s"
        HASH_STATUS="404"
    else
        echo -e "  Status: ${GREEN}OK${NC} | Time: ${HASH_TIME}s | Size: ${HASH_SIZE} bytes"
        HASH_STATUS="OK"
    fi

    # Store results for summary
    if [ "$WWW_STATUS" = "OK" ] || [ "$HASH_STATUS" = "OK" ]; then
        BEST_TIME=$(echo "$WWW_TIME $HASH_TIME" | tr ' ' '\n' | sort -n | head -1)
        echo "$game_type|OK|$BEST_TIME" >> /tmp/game_test_results_$$.txt
        echo -e "${GREEN}✓ Game is accessible${NC}"
    else
        echo "$game_type|404|N/A" >> /tmp/game_test_results_$$.txt
        echo -e "${RED}✗ Game returns 404${NC}"
    fi
}

# Main script
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Multiple Games Performance Testing Tool           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Configuration:${NC}"
echo -e "  Number of games to test: ${YELLOW}$NUM_GAMES${NC}"
echo -e "  Language: ${YELLOW}$LANG${NC}"
echo -e "  Username: ${YELLOW}$USERNAME${NC}"
echo -e "  Total available games: ${YELLOW}${#GAME_TYPES[@]}${NC}"
echo ""

# Validate number of games
if [ "$NUM_GAMES" -gt "${#GAME_TYPES[@]}" ]; then
    echo -e "${YELLOW}Warning: Requested $NUM_GAMES games, but only ${#GAME_TYPES[@]} available.${NC}"
    echo -e "${YELLOW}Testing all ${#GAME_TYPES[@]} games instead.${NC}"
    NUM_GAMES="${#GAME_TYPES[@]}"
fi

# Select random games
echo -e "${CYAN}Selecting $NUM_GAMES random games...${NC}"
SELECTED_GAMES=($(shuffle_and_pick "$NUM_GAMES" "${GAME_TYPES[@]}"))

echo -e "${GREEN}Selected games:${NC}"
for i in "${!SELECTED_GAMES[@]}"; do
    echo "  $((i+1)). ${SELECTED_GAMES[$i]}"
done

# Clear previous results
rm -f /tmp/game_test_results_$$.txt

# Test each game
COUNTER=1
for game in "${SELECTED_GAMES[@]}"; do
    test_game "$game" "$COUNTER" "${#SELECTED_GAMES[@]}"
    COUNTER=$((COUNTER + 1))
    sleep 1  # Brief pause between tests
done

# Generate summary report
echo ""
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    TEST SUMMARY                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f /tmp/game_test_results_$$.txt ]; then
    echo -e "${RED}No test results found${NC}"
    exit 1
fi

TOTAL_TESTED=$(wc -l < /tmp/game_test_results_$$.txt)
ACCESSIBLE=$(grep "|OK|" /tmp/game_test_results_$$.txt | wc -l)
NOT_ACCESSIBLE=$(grep "|404|" /tmp/game_test_results_$$.txt | wc -l)

echo -e "${CYAN}Overall Statistics:${NC}"
echo -e "  Total games tested: ${YELLOW}$TOTAL_TESTED${NC}"
echo -e "  Accessible games: ${GREEN}$ACCESSIBLE${NC}"
echo -e "  404 errors: ${RED}$NOT_ACCESSIBLE${NC}"

if [ "$ACCESSIBLE" -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=1; $ACCESSIBLE * 100 / $TOTAL_TESTED" | bc)
    echo -e "  Success rate: ${GREEN}${SUCCESS_RATE}%${NC}"
else
    echo -e "  Success rate: ${RED}0%${NC}"
fi

echo ""
echo -e "${CYAN}Accessible Games:${NC}"
if [ "$ACCESSIBLE" -gt 0 ]; then
    grep "|OK|" /tmp/game_test_results_$$.txt | while IFS='|' read -r game status time; do
        echo -e "  ${GREEN}✓${NC} $game (${time}s)"
    done

    # Calculate average load time
    AVG_TIME=$(grep "|OK|" /tmp/game_test_results_$$.txt | cut -d'|' -f3 | awk '{sum+=$1; count++} END {printf "%.3f", sum/count}')
    echo ""
    echo -e "  ${CYAN}Average load time: ${YELLOW}${AVG_TIME}s${NC}"
else
    echo -e "  ${RED}None${NC}"
fi

echo ""
echo -e "${CYAN}Games with 404 Errors:${NC}"
if [ "$NOT_ACCESSIBLE" -gt 0 ]; then
    grep "|404|" /tmp/game_test_results_$$.txt | while IFS='|' read -r game status time; do
        echo -e "  ${RED}✗${NC} $game"
    done
else
    echo -e "  ${GREEN}None${NC}"
fi

echo ""
echo -e "${BLUE}Bangladesh Region Performance Estimate:${NC}"
if [ "$ACCESSIBLE" -gt 0 ]; then
    echo -e "  ${RED}100 KB/s${NC} connection: ~20-25 seconds"
    echo -e "  ${YELLOW}500 KB/s${NC} connection: ~5-7 seconds"
    echo -e "  ${YELLOW}1 Mbps+${NC} connection: ~8-12 seconds"
    echo -e "  ${GREEN}5 Mbps+${NC} connection: ~2-4 seconds"
else
    echo -e "  ${RED}Cannot estimate - No games are accessible${NC}"
fi

echo ""
if [ "$NOT_ACCESSIBLE" -gt 0 ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "  1. Check if game resources are properly deployed"
    echo "  2. Verify Token generation and validation"
    echo "  3. Review CDN configuration and path mappings"
    echo "  4. Check server logs for errors"
fi

echo ""
echo -e "${GREEN}Test completed!${NC}"
echo -e "Detailed results saved to: ${CYAN}/tmp/game_test_results_$$.txt${NC}"

# Cleanup
# Uncomment to auto-delete results file
# rm -f /tmp/game_test_results_$$.txt

# Note: IP information is shown in test_with_ip_info.sh
# This script focuses on testing multiple games quickly
# For detailed IP and location info, use: ./test_with_ip_info.sh
