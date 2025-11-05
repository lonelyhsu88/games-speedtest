#!/usr/bin/env bash

################################################################################
# Game Loading Test with Puppeteer (FIXED VERSION)
#
# This script:
# 1. Gets game URLs from API (using whitelisted IP)
# 2. Uses Puppeteer FIXED version with accurate size tracking
# 3. Captures ALL resources using Chrome DevTools Protocol (CDP)
# 4. Reports accurate loading times and resource sizes
#
# Usage:
#   ./test_games_with_puppeteer.sh <num_games> [lang] [wait_time]
#   ./test_games_with_puppeteer.sh --games "Game1,Game2,Game3" [lang] [wait_time]
#
# Examples:
#   ./test_games_with_puppeteer.sh 3 en-US 10000
#   ./test_games_with_puppeteer.sh 5 zh-CN 15000
#   ./test_games_with_puppeteer.sh --games "EggHuntBingo,MagicBingo" en-US 15000
#   ./test_games_with_puppeteer.sh --games "StandAloneHilo,StandAloneKeno,ArcadeBingo"
################################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"
USERNAME="optest01"
PRODUCT_ID="ELS"

# Show usage function
show_usage() {
    echo -e "${RED}Error: Missing required parameter${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <num_games> [lang] [wait_time]"
    echo "  $0 --games \"Game1,Game2,Game3\" [lang] [wait_time]"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 3              # Test 3 random games (default lang: en-US, wait: 10000ms)"
    echo "  $0 5 zh-CN        # Test 5 random games with Chinese language"
    echo "  $0 10 en-US 15000 # Test 10 random games with custom wait time"
    echo "  $0 --games \"StandAloneHilo,StandAloneLimbo\" en-US"
    echo ""
    echo -e "${YELLOW}Parameters:${NC}"
    echo "  num_games  : Number of games to test (1-54)"
    echo "  lang       : Language code (default: en-US)"
    echo "  wait_time  : Wait time after networkidle in ms (default: 10000)"
    echo ""
    exit 1
}

# Parse arguments
SPECIFIED_GAMES=""
if [ "$1" = "--games" ]; then
    if [ -z "$2" ]; then
        echo -e "${RED}Error: --games requires a game list${NC}"
        echo ""
        show_usage
    fi
    SPECIFIED_GAMES="$2"
    LANG=${3:-"en-US"}
    WAIT_TIME=${4:-10000}
else
    # Check if num_games parameter is provided
    if [ $# -eq 0 ]; then
        show_usage
    fi

    NUM_GAMES=$1

    # Validate num_games is a positive integer
    if ! [[ "$NUM_GAMES" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Number of games must be a positive integer${NC}"
        echo ""
        show_usage
    fi

    if [ "$NUM_GAMES" -lt 1 ]; then
        echo -e "${RED}Error: Number of games must be at least 1${NC}"
        exit 1
    fi

    if [ "$NUM_GAMES" -gt 54 ]; then
        echo -e "${YELLOW}Warning: Maximum 54 games available. Setting to 54.${NC}"
        NUM_GAMES=54
    fi

    LANG=${2:-"en-US"}
    WAIT_TIME=${3:-10000}
fi

# Available games
ALL_GAMES=(
    # Bingo Games
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
    # Arcade Games
    "MultiPlayerBoomersGR"
    "StandAloneForestTeaParty"
    "StandAloneWildDigGR"
    "StandAloneGoldenClover"
    # Hash Games - MultiPlayer
    "MultiPlayerAviator"
    "MultiPlayerAviator2"
    "MultiPlayerAviator2XIN"
    "MultiPlayerCrash"
    "MultiPlayerCrashCL"
    "MultiPlayerCrashGR"
    "MultiPlayerCrashNE"
    # Hash Games - StandAlone
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
)

# Generate sequence number
generate_seq() {
    echo "$(date +%s)$(( RANDOM % 1000 ))"
}

# Get game URL from API
get_game_url() {
    local game=$1
    local seq=$(generate_seq)
    local payload="{\"seq\":\"$seq\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$game\",\"lang\":\"$LANG\"}"
    # Compatible with both macOS (md5) and Linux (md5sum)
    if command -v md5 &> /dev/null; then
        local md5=$(echo -n "xdr56yhn${payload}" | md5 -q)
    else
        local md5=$(echo -n "xdr56yhn${payload}" | md5sum | awk '{print $1}')
    fi

    local response=$(curl -s -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -H "els-access-key: $md5" \
      -d "$payload")

    local url=$(echo "$response" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

    if [ -z "$url" ]; then
        echo ""
        return 1
    fi

    # Convert jump domain to www domain
    echo "$url" | sed 's|jump.shuangzi6666.com|www.shuangzi6688.com|'
}

# Main script
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Puppeteer Game Loading Test (Real Browser)          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
if [ -n "$SPECIFIED_GAMES" ]; then
    echo -e "  Mode: ${GREEN}Specified games${NC}"
    echo -e "  Games: ${GREEN}$SPECIFIED_GAMES${NC}"
else
    echo -e "  Mode: ${GREEN}Random selection${NC}"
    echo -e "  Number of games: ${GREEN}$NUM_GAMES${NC}"
fi
echo -e "  Language: ${GREEN}$LANG${NC}"
echo -e "  Wait time after networkidle: ${GREEN}${WAIT_TIME}ms${NC}"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js is not installed${NC}"
    echo "  Please install Node.js first"
    exit 1
fi

# Check if Puppeteer is installed
if [ ! -d "node_modules/puppeteer" ]; then
    echo -e "${RED}✗ Puppeteer is not installed${NC}"
    echo "  Run: npm install puppeteer"
    exit 1
fi

echo -e "${YELLOW}[Step 1] Checking your current IP...${NC}"
MY_IP=$(curl -s https://api.ipify.org)
MY_LOCATION=$(curl -s "http://ip-api.com/json/${MY_IP}" 2>/dev/null)
MY_COUNTRY=$(echo "$MY_LOCATION" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
if [ -n "$MY_COUNTRY" ]; then
    echo -e "  Your IP: ${GREEN}$MY_IP${NC} (${CYAN}$MY_COUNTRY${NC})"
else
    echo -e "  Your IP: ${GREEN}$MY_IP${NC}"
fi
echo ""

# Select games
SELECTED_GAMES=()
if [ -n "$SPECIFIED_GAMES" ]; then
    # Use specified games
    echo -e "${YELLOW}[Step 2] Using specified games...${NC}"
    IFS=',' read -ra SELECTED_GAMES <<< "$SPECIFIED_GAMES"

    # Validate game names
    echo -e "${CYAN}Validating game names...${NC}"
    VALID_GAMES=()
    for game in "${SELECTED_GAMES[@]}"; do
        # Trim whitespace
        game=$(echo "$game" | xargs)
        # Check if game exists in ALL_GAMES
        if [[ " ${ALL_GAMES[@]} " =~ " ${game} " ]]; then
            VALID_GAMES+=("$game")
            echo -e "  ${GREEN}✓${NC} $game"
        else
            echo -e "  ${RED}✗${NC} $game (not found in available games)"
        fi
    done

    if [ ${#VALID_GAMES[@]} -eq 0 ]; then
        echo ""
        echo -e "${RED}✗ No valid games specified${NC}"
        echo ""
        echo "Available games:"
        for game in "${ALL_GAMES[@]}"; do
            echo "  - $game"
        done
        exit 1
    fi

    SELECTED_GAMES=("${VALID_GAMES[@]}")
    echo ""
else
    # Random selection
    echo -e "${YELLOW}[Step 2] Selecting $NUM_GAMES random games...${NC}"

    # Shuffle and select games
    TEMP_GAMES=("${ALL_GAMES[@]}")

    for ((i=0; i<NUM_GAMES; i++)); do
        if [ ${#TEMP_GAMES[@]} -eq 0 ]; then
            break
        fi
        idx=$(( RANDOM % ${#TEMP_GAMES[@]} ))
        SELECTED_GAMES+=("${TEMP_GAMES[$idx]}")
        TEMP_GAMES=("${TEMP_GAMES[@]:0:$idx}" "${TEMP_GAMES[@]:$((idx+1))}")
    done
fi

echo -e "${GREEN}Selected games:${NC}"
for ((i=0; i<${#SELECTED_GAMES[@]}; i++)); do
    echo "  $((i+1)). ${SELECTED_GAMES[$i]}"
done
echo ""

echo -e "${YELLOW}[Step 3] Getting game URLs from API...${NC}"
echo ""

GAME_URLS=()
GAME_NAMES=()

for ((i=0; i<${#SELECTED_GAMES[@]}; i++)); do
    game=${SELECTED_GAMES[$i]}
    echo -e "${CYAN}[$((i+1))/${#SELECTED_GAMES[@]}] Getting URL for $game...${NC}"

    url=$(get_game_url "$game")

    if [ -z "$url" ]; then
        echo -e "  ${RED}✗ Failed to get URL${NC}"
    else
        echo -e "  ${GREEN}✓ Success${NC}"
        GAME_URLS+=("$url")
        GAME_NAMES+=("$game")
    fi
done

echo ""

if [ ${#GAME_URLS[@]} -eq 0 ]; then
    echo -e "${RED}✗ No game URLs were retrieved${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Retrieved ${#GAME_URLS[@]} game URLs${NC}"
echo ""

# Save URLs to temporary file for reference
URLS_FILE="/tmp/game_urls_temp.txt"
> "$URLS_FILE"
for ((i=0; i<${#GAME_URLS[@]}; i++)); do
    echo "${GAME_NAMES[$i]}|${GAME_URLS[$i]}" >> "$URLS_FILE"
done

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   URLs Retrieved - Ready for VPN Switch                ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Now switch to Bangladesh VPN!${NC}"
echo ""
echo "Step-by-step:"
echo "  1. The game URLs have been retrieved (using whitelisted IP)"
echo -e "  2. ${YELLOW}Connect your VPN to Bangladesh now${NC}"
echo "  3. Press Enter when VPN is connected to start testing"
echo ""
echo -e "${CYAN}Game URLs saved to: $URLS_FILE${NC}"
echo ""
read -p "Press Enter when VPN is connected to Bangladesh..."
echo ""

# Verify VPN connection
echo -e "${YELLOW}Verifying VPN connection...${NC}"
NEW_IP=$(curl -s https://api.ipify.org)
LOCATION=$(curl -s "http://ip-api.com/json/${NEW_IP}" 2>/dev/null)
COUNTRY=$(echo "$LOCATION" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)

echo -e "  Current IP: ${GREEN}$NEW_IP${NC}"
if [ -n "$COUNTRY" ]; then
    echo -e "  Location: ${GREEN}$COUNTRY${NC}"

    if [ "$COUNTRY" = "Bangladesh" ]; then
        echo -e "  ${GREEN}✓ VPN connected to Bangladesh!${NC}"
    else
        echo -e "  ${YELLOW}⚠ Warning: You are in $COUNTRY, not Bangladesh${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Test cancelled"
            exit 1
        fi
    fi
fi
echo ""

# Create results directory
RESULTS_DIR="./puppeteer_results"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/results_${TIMESTAMP}.txt"

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   Starting Puppeteer Tests from Bangladesh            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test each game
for ((i=0; i<${#GAME_URLS[@]}; i++)); do
    game=${GAME_NAMES[$i]}
    url=${GAME_URLS[$i]}

    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Testing [$((i+1))/${#GAME_URLS[@]}]: $game${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Run Puppeteer test
    OUTPUT_JSON="$RESULTS_DIR/${game}_${TIMESTAMP}.json"

    node puppeteer_game_test.js "$url" \
        --wait=$WAIT_TIME \
        --output="$OUTPUT_JSON" \
        2>&1 | tee /tmp/puppeteer_output.txt

    # Extract results from JSON (including new fields from fixed version)
    if [ -f "$OUTPUT_JSON" ]; then
        TOTAL_TIME=$(node -e "console.log(require('$OUTPUT_JSON').totalTime)")
        TOTAL_SIZE=$(node -e "console.log(require('$OUTPUT_JSON').totalSize)")
        ENCODED_SIZE=$(node -e "const data = require('$OUTPUT_JSON'); console.log(data.totalEncodedSize || 0);")
        TOTAL_REQUESTS=$(node -e "console.log(require('$OUTPUT_JSON').totalRequests)")

        # Save to results file (including encoded size)
        echo "$game|$TOTAL_TIME|$TOTAL_SIZE|$ENCODED_SIZE|$TOTAL_REQUESTS" >> "$RESULTS_FILE"
    fi

    echo ""
    echo -e "${GREEN}✓ Test complete for $game${NC}"
    echo ""

    # Short pause between tests
    if [ $i -lt $((${#GAME_URLS[@]} - 1)) ]; then
        echo "Waiting 3 seconds before next test..."
        sleep 3
        echo ""
    fi
done

# Generate summary report
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Summary Report                                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display test environment info
echo -e "${CYAN}Test Environment:${NC}"
if [ -n "$MY_COUNTRY" ]; then
    echo -e "  Initial IP:  ${GREEN}$MY_IP${NC} (${CYAN}$MY_COUNTRY${NC})"
else
    echo -e "  Initial IP:  ${GREEN}$MY_IP${NC}"
fi

if [ -n "$NEW_IP" ] && [ "$NEW_IP" != "$MY_IP" ]; then
    if [ -n "$COUNTRY" ]; then
        echo -e "  Testing IP:  ${GREEN}$NEW_IP${NC} (${CYAN}$COUNTRY${NC})"
    else
        echo -e "  Testing IP:  ${GREEN}$NEW_IP${NC}"
    fi
fi

echo -e "  Language:    ${GREEN}$LANG${NC}"
echo -e "  Max Wait:    ${GREEN}${WAIT_TIME}ms${NC}"
echo ""

if [ -f "$RESULTS_FILE" ]; then
    echo -e "${YELLOW}Complete Loading Times (Real Browser with Accurate Size Tracking):${NC}"
    echo ""

    while IFS='|' read -r game time size encoded requests; do
        time_s=$(echo "scale=2; $time / 1000" | bc)
        size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc)

        # Handle both old format (4 fields) and new format (5 fields)
        if [ -z "$requests" ]; then
            # Old format: game|time|size|requests
            requests=$encoded
            printf "  ${GREEN}✓${NC} %-30s ${YELLOW}%7.2fs${NC} | %6.2f MB | %3d requests\n" \
                   "$game" "$time_s" "$size_mb" "$requests"
        else
            # New format: game|time|size|encoded|requests
            encoded_mb=$(echo "scale=2; $encoded / 1024 / 1024" | bc)
            printf "  ${GREEN}✓${NC} %-30s ${YELLOW}%7.2fs${NC} | ${CYAN}%6.2f MB${NC} (${MAGENTA}%6.2f MB${NC} transferred) | %3d requests\n" \
                   "$game" "$time_s" "$size_mb" "$encoded_mb" "$requests"
        fi
    done < "$RESULTS_FILE"

    echo ""
    echo -e "${CYAN}Note:${NC} Using FIXED version with accurate resource tracking via CDP"
    echo ""
    echo -e "${CYAN}Comparison with old tests:${NC}"
    echo ""
    echo -e "  ${YELLOW}Old version${NC} used content-length headers (often missing/wrong)"
    echo -e "  ${YELLOW}Fixed version${NC} uses Chrome DevTools Protocol (CDP) to get:"
    echo "    • Actual response body sizes (accurate)"
    echo "    • Transferred sizes (after compression)"
    echo "    • Cache information"
    echo "    • Complete resource tracking"
    echo ""
    echo -e "  ${GREEN}This matches what Chrome DevTools shows!${NC}"
    echo ""
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Test Complete                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Results saved to: ${GREEN}$RESULTS_DIR/${NC}"
echo -e "Detailed reports: ${GREEN}$RESULTS_DIR/*_${TIMESTAMP}.json${NC}"
echo ""
