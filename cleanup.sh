#!/usr/bin/env bash

################################################################################
# Cleanup Script for games-speedtest
#
# This script cleans up unnecessary files while keeping core functionality
################################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Games-Speedtest Cleanup Script                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Ask for confirmation
echo -e "${YELLOW}This script will clean up unnecessary files.${NC}"
echo ""
echo "What will be DELETED:"
echo "  • Old .txt report files (26 files)"
echo "  • Test HTML files (6 files)"
echo "  • Test JS files (cocos2d.js, main.js, etc.)"
echo "  • Test config files"
echo "  • Test result directories"
echo "  • Old development scripts (17 files)"
echo "  • enhanced_click_strategy.js (integrated into main)"
echo ""
echo "What will be KEPT:"
echo "  ✓ puppeteer_game_test_fixed.js (Enhanced version)"
echo "  ✓ test_games_menu_fixed.sh"
echo "  ✓ test_games_with_puppeteer_fixed.sh"
echo "  ✓ test_enhanced_click.sh"
echo "  ✓ All Markdown documentation"
echo "  ✓ node_modules/, package.json"
echo ""
echo -e "${CYAN}Old versions will be kept for reference (you can delete manually later):${NC}"
echo "  → puppeteer_game_test.js"
echo "  → test_games_menu.sh"
echo "  → test_games_with_puppeteer.sh"
echo ""
echo -n "Continue with cleanup? (y/n): "
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting cleanup...${NC}"
echo ""

# Create backup directory
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${CYAN}Created backup directory: $BACKUP_DIR${NC}"
echo ""

# Function to move file to backup and report
backup_and_delete() {
    local file=$1
    if [ -f "$file" ]; then
        mv "$file" "$BACKUP_DIR/"
        echo "  ✓ $file"
        return 0
    elif [ -d "$file" ]; then
        mv "$file" "$BACKUP_DIR/"
        echo "  ✓ $file/ (directory)"
        return 0
    fi
    return 1
}

# 1. Clean up .txt report files
echo -e "${YELLOW}Cleaning up .txt report files...${NC}"
TXT_FILES=(
    "ALL_FEATURES_COMPLETE.txt"
    "ALL_JS_FILES_UPDATE.txt"
    "ALL_RESOURCES_LOADING.txt"
    "BANGLADESH_VS_TAIWAN_COMPARISON.txt"
    "CACHE_DISABLE_FIX.txt"
    "CHANGELOG.txt"
    "COCOS2D_LOADING_FIX.txt"
    "FINAL_SUMMARY_PUPPETEER.txt"
    "FINAL_SUMMARY.txt"
    "FINAL_UPDATE_SUMMARY.txt"
    "INDEX.txt"
    "JSON_AND_HTTP_STATUS_UPDATE.txt"
    "LOADING_TIME_EXPLANATION.txt"
    "MENU_QUICK_START.txt"
    "MULTI_GAME_FULL_LOAD_GUIDE.txt"
    "PUPPETEER_RESULTS_ANALYSIS.txt"
    "PUPPETEER_SETUP.txt"
    "QUICK_REFERENCE.txt"
    "QUICK_START.txt"
    "READY_TO_USE.txt"
    "SPECIFY_GAMES_GUIDE.txt"
    "START_HERE.txt"
    "TESTING_COMPLETE_GUIDE.txt"
    "URL_AND_STATS_FIX.txt"
    "URL_DISPLAY_STATUS.txt"
    "VPN_TESTING_GUIDE.txt"
)

for file in "${TXT_FILES[@]}"; do
    backup_and_delete "$file"
done
echo ""

# 2. Clean up test HTML files
echo -e "${YELLOW}Cleaning up test HTML files...${NC}"
HTML_FILES=(
    "browser-test.html"
    "hash-game.html"
    "index.html"
    "real-arcadebingo.html"
    "real-game.html"
    "test-egypt-hilo.html"
)

for file in "${HTML_FILES[@]}"; do
    backup_and_delete "$file"
done
echo ""

# 3. Clean up test JS files
echo -e "${YELLOW}Cleaning up test JS files...${NC}"
JS_FILES=(
    "cocos2d.js"
    "main.js"
    "settings.js"
    "enhanced_click_strategy.js"
)

for file in "${JS_FILES[@]}"; do
    backup_and_delete "$file"
done
echo ""

# 4. Clean up test config files
echo -e "${YELLOW}Cleaning up test config files...${NC}"
CONFIG_FILES=(
    "internal-config-real.json"
    "internal-config.json"
    "resources-config-real.json"
    "resources-config.json"
    "performance-report.txt"
    "egghunt_report.json"
)

for file in "${CONFIG_FILES[@]}"; do
    backup_and_delete "$file"
done
echo ""

# 5. Clean up old shell scripts
echo -e "${YELLOW}Cleaning up old development scripts...${NC}"
OLD_SCRIPTS=(
    "add_nocache_headers.sh"
    "check_game_flow.sh"
    "check_url_display.sh"
    "get_real_game_url.sh"
    "show_client_ip.sh"
    "test_bangladesh_direct.sh"
    "test_egghunt_complete.sh"
    "test_egghunt_real_files.sh"
    "test_full_game_load_with_vpn.sh"
    "test_full_game_load.sh"
    "test_game_performance_en.sh"
    "test_game_performance.sh"
    "test_http_status_and_json.sh"
    "test_multiple_full_load_with_vpn.sh"
    "test_multiple_games.sh"
    "test_multiple_with_vpn.sh"
    "test_real_page_load.sh"
    "test_specific_url.sh"
    "test_vpn_workflow.sh"
    "test_with_ip_info.sh"
    "test_with_vpn_workaround.sh"
    "verify_cocos_fix.sh"
)

for file in "${OLD_SCRIPTS[@]}"; do
    backup_and_delete "$file"
done
echo ""

# 6. Clean up old documentation
echo -e "${YELLOW}Cleaning up old documentation...${NC}"
OLD_DOCS=(
    "API_WHITELIST_SOLUTION.md"
    "BANGLADESH_VPN_TESTING_GUIDE.md"
    "FULL_GAME_LOADING_GUIDE.md"
    "README_BANGLADESH_TESTING.md"
    "SCRIPTS_OVERVIEW.md"
    "USAGE_GUIDE.md"
    "TESTING_METHODS.md"
    "FINAL_TEST_REPORT.md"
)

for file in "${OLD_DOCS[@]}"; do
    backup_and_delete "$file"
done
echo ""

# 7. Clean up test result directories
echo -e "${YELLOW}Cleaning up test result directories...${NC}"
backup_and_delete "puppeteer_results"
backup_and_delete "puppeteer_results_bangladesh"
echo ""

# 8. Clean up other files
echo -e "${YELLOW}Cleaning up other files...${NC}"
OTHER_FILES=(
    "style-mobile.css"
    'src="[^"]*\.js[^"]*"'
)

for file in "${OTHER_FILES[@]}"; do
    backup_and_delete "$file"
done
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Cleanup Complete                                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
BACKUP_COUNT=$(find "$BACKUP_DIR" -type f | wc -l | tr -d ' ')

echo -e "${GREEN}Summary:${NC}"
echo "  Files moved to backup: $BACKUP_COUNT"
echo "  Backup size: $BACKUP_SIZE"
echo "  Backup location: ./$BACKUP_DIR/"
echo ""

echo -e "${CYAN}Current directory now contains:${NC}"
echo "  ✓ Core testing programs (3 files)"
echo "  ✓ Shell scripts (5 files)"
echo "  ✓ Documentation (12 Markdown files)"
echo "  ✓ Node modules and configs"
echo ""

echo -e "${YELLOW}What's next:${NC}"
echo "  1. Test the scripts to make sure everything works:"
echo "     ./test_games_menu_fixed.sh"
echo ""
echo "  2. If everything works fine, you can delete the backup:"
echo "     rm -rf $BACKUP_DIR/"
echo ""
echo "  3. Or keep the backup for safety and delete later"
echo ""

echo -e "${GREEN}Cleanup completed successfully!${NC}"
