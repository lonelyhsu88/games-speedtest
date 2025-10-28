#!/usr/bin/env bash

################################################################################
# Interactive Game Testing Menu
# 
# This script provides an interactive menu to select games for testing
################################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

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

# Selected games array
SELECTED_GAMES=()

# Function to display menu
show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Interactive Game Selection Menu                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}Available Games:${NC}"
    echo ""
    
    for i in "${!ALL_GAMES[@]}"; do
        local game="${ALL_GAMES[$i]}"
        local num=$((i + 1))
        
        # Check if game is selected
        if [[ " ${SELECTED_GAMES[@]} " =~ " ${game} " ]]; then
            echo -e "  ${GREEN}[✓]${NC} ${num}. ${GREEN}${game}${NC}"
        else
            echo -e "  [ ] ${num}. ${game}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ ${#SELECTED_GAMES[@]} -gt 0 ]; then
        echo -e "${YELLOW}Selected: ${#SELECTED_GAMES[@]} games${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}Commands:${NC}"
    echo "  1-${#ALL_GAMES[@]}  - Toggle game selection"
    echo "  a     - Select all games"
    echo "  c     - Clear all selections"
    echo "  r     - Select random games"
    echo "  b     - Select all Bingo games"
    echo "  h     - Select all Hilo games"
    echo "  k     - Select all Keno games"
    echo "  d     - Done (start testing)"
    echo "  q     - Quit"
    echo ""
    echo -n "Enter command: "
}

# Function to toggle game selection
toggle_game() {
    local index=$1
    
    if [ $index -lt 1 ] || [ $index -gt ${#ALL_GAMES[@]} ]; then
        return
    fi
    
    local game="${ALL_GAMES[$((index - 1))]}"
    
    # Check if already selected
    local found=0
    local new_array=()
    
    for selected in "${SELECTED_GAMES[@]}"; do
        if [ "$selected" = "$game" ]; then
            found=1
        else
            new_array+=("$selected")
        fi
    done
    
    if [ $found -eq 1 ]; then
        # Remove from selection
        SELECTED_GAMES=("${new_array[@]}")
    else
        # Add to selection
        SELECTED_GAMES+=("$game")
    fi
}

# Function to select all games
select_all() {
    SELECTED_GAMES=("${ALL_GAMES[@]}")
}

# Function to clear all selections
clear_all() {
    SELECTED_GAMES=()
}

# Function to select random games
select_random() {
    echo ""
    echo -n "How many random games? (1-${#ALL_GAMES[@]}): "
    read num
    
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#ALL_GAMES[@]} ]; then
        return
    fi
    
    SELECTED_GAMES=()
    local temp_games=("${ALL_GAMES[@]}")
    
    for ((i=0; i<num; i++)); do
        if [ ${#temp_games[@]} -eq 0 ]; then
            break
        fi
        local idx=$(( RANDOM % ${#temp_games[@]} ))
        SELECTED_GAMES+=("${temp_games[$idx]}")
        temp_games=("${temp_games[@]:0:$idx}" "${temp_games[@]:$((idx+1))}")
    done
}

# Function to select by category
select_by_pattern() {
    local pattern=$1
    SELECTED_GAMES=()
    
    for game in "${ALL_GAMES[@]}"; do
        if [[ "$game" == *"$pattern"* ]]; then
            SELECTED_GAMES+=("$game")
        fi
    done
}

# Main menu loop
while true; do
    show_menu
    read -r choice
    
    case "$choice" in
        [1-9]|[1-5][0-9])
            # Match 1-9 and 10-59
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#ALL_GAMES[@]} ]; then
                toggle_game "$choice"
            fi
            ;;
        a|A)
            select_all
            ;;
        c|C)
            clear_all
            ;;
        r|R)
            select_random
            ;;
        b|B)
            select_by_pattern "Bingo"
            ;;
        h|H)
            select_by_pattern "Hilo"
            ;;
        k|K)
            select_by_pattern "Keno"
            ;;
        d|D)
            if [ ${#SELECTED_GAMES[@]} -eq 0 ]; then
                echo ""
                echo -e "${RED}✗ No games selected${NC}"
                echo ""
                echo -n "Press Enter to continue..."
                read
            else
                break
            fi
            ;;
        q|Q)
            echo ""
            echo "Cancelled."
            exit 0
            ;;
        *)
            ;;
    esac
done

# Ask for language
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Language Selection                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Select language:"
echo "  1. en-US (English)"
echo "  2. zh-CN (Simplified Chinese)"
echo "  3. zh-TW (Traditional Chinese)"
echo ""
echo -n "Enter choice (default: 1): "
read lang_choice

case "$lang_choice" in
    2)
        LANG="zh-CN"
        ;;
    3)
        LANG="zh-TW"
        ;;
    *)
        LANG="en-US"
        ;;
esac

# Ask for wait time
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Wait Time Configuration                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Maximum wait time after networkidle (milliseconds):"
echo "  1. 10000 ms (10 seconds) - Fast"
echo "  2. 15000 ms (15 seconds) - Standard"
echo "  3. 20000 ms (20 seconds) - Safe"
echo ""
echo -n "Enter choice (default: 2): "
read wait_choice

case "$wait_choice" in
    1)
        WAIT_TIME=10000
        ;;
    3)
        WAIT_TIME=20000
        ;;
    *)
        WAIT_TIME=15000
        ;;
esac

# Confirm and run
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Test Configuration Summary                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Selected Games (${#SELECTED_GAMES[@]}):${NC}"
for game in "${SELECTED_GAMES[@]}"; do
    echo -e "  ${GREEN}✓${NC} $game"
done
echo ""
echo -e "${CYAN}Language:${NC} $LANG"
echo -e "${CYAN}Max Wait Time:${NC} ${WAIT_TIME} ms"
echo ""
echo -n "Start testing? (y/n): "
read confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

# Build game list string
GAMES_STRING=$(IFS=,; echo "${SELECTED_GAMES[*]}")

# Run the test
echo ""
echo -e "${GREEN}Starting test...${NC}"
echo ""

./test_games_with_puppeteer.sh --games "$GAMES_STRING" "$LANG" "$WAIT_TIME"
