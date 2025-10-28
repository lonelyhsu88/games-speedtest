#!/usr/bin/env bash

################################################################################
# Test Enhanced Click Strategy
#
# This script tests the enhanced click strategy with a few games
################################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"
USERNAME="optest01"
PRODUCT_ID="ELS"
LANG="en-US"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Testing Enhanced Click Strategy                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test games with different button positions
TEST_GAMES=(
    "StandAloneLimboCL"
    "EggHuntBingo"
    "ArcadeBingo"
)

echo -e "${CYAN}Test Games:${NC}"
for game in "${TEST_GAMES[@]}"; do
    echo "  • $game"
done
echo ""

# Create results directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results/enhanced_click_test_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

echo -e "${GREEN}Starting tests...${NC}"
echo ""

# Test each game
for game in "${TEST_GAMES[@]}"; do
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Testing: ${GREEN}$game${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Get game URL from API
    echo "Getting game URL from API..."

    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"$USERNAME\",
            \"gameName\": \"$game\",
            \"productId\": \"$PRODUCT_ID\",
            \"lang\": \"$LANG\"
        }")

    # Extract game URL
    GAME_URL=$(echo "$RESPONSE" | node -e "
        const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
        console.log(data.data?.gameUrl || '');
    ")

    if [ -z "$GAME_URL" ]; then
        echo -e "${RED}✗ Failed to get game URL${NC}"
        echo ""
        continue
    fi

    echo -e "${GREEN}✓ Got game URL${NC}"
    echo ""

    # Run test with enhanced strategy
    OUTPUT_JSON="$RESULTS_DIR/${game}.json"

    echo -e "${YELLOW}Running enhanced click test...${NC}"
    echo ""

    node puppeteer_game_test.js "$GAME_URL" \
        --wait=15000 \
        --output="$OUTPUT_JSON" \
        2>&1 | tee "$RESULTS_DIR/${game}_output.txt"

    # Extract and display key metrics
    if [ -f "$OUTPUT_JSON" ]; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Results for $game:${NC}"

        TOTAL_TIME=$(node -e "const data = require('$OUTPUT_JSON'); console.log((data.totalTime / 1000).toFixed(2));")
        TOTAL_SIZE=$(node -e "const data = require('$OUTPUT_JSON'); console.log((data.totalSize / 1024 / 1024).toFixed(2));")
        TOTAL_REQUESTS=$(node -e "const data = require('$OUTPUT_JSON'); console.log(data.totalRequests);")

        echo "  Time:     ${TOTAL_TIME}s"
        echo "  Size:     ${TOTAL_SIZE} MB"
        echo "  Requests: ${TOTAL_REQUESTS}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi

    echo ""
    echo "Waiting 3 seconds before next test..."
    sleep 3
    echo ""
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Test Complete                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Results saved to: ${GREEN}$RESULTS_DIR/${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo ""

for game in "${TEST_GAMES[@]}"; do
    OUTPUT_JSON="$RESULTS_DIR/${game}.json"
    if [ -f "$OUTPUT_JSON" ]; then
        TOTAL_TIME=$(node -e "const data = require('$OUTPUT_JSON'); console.log((data.totalTime / 1000).toFixed(2));")
        TOTAL_SIZE=$(node -e "const data = require('$OUTPUT_JSON'); console.log((data.totalSize / 1024 / 1024).toFixed(2));")
        TOTAL_REQUESTS=$(node -e "const data = require('$OUTPUT_JSON'); console.log(data.totalRequests);")

        printf "  ${GREEN}✓${NC} %-25s ${YELLOW}%7.2fs${NC} | %6.2f MB | %3d requests\n" \
               "$game" "$TOTAL_TIME" "$TOTAL_SIZE" "$TOTAL_REQUESTS"
    else
        printf "  ${RED}✗${NC} %-25s ${RED}Failed${NC}\n" "$game"
    fi
done

echo ""
echo -e "${CYAN}Output logs:${NC}"
echo "  ls -lh $RESULTS_DIR/*_output.txt"
echo ""
echo -e "${CYAN}JSON reports:${NC}"
echo "  cat $RESULTS_DIR/*.json | jq '.'"
echo ""
