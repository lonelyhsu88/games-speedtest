#!/bin/bash

# Script to add no-cache headers to all curl commands in test scripts
# This ensures we measure real loading time, not cached results

echo "════════════════════════════════════════════════════════"
echo "Adding No-Cache Headers to All Test Scripts"
echo "════════════════════════════════════════════════════════"
echo ""

# Define the no-cache headers
NOCACHE_HEADERS='-H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0"'

# List of scripts to update
SCRIPTS=(
    "test_multiple_with_vpn.sh"
    "test_with_vpn_workaround.sh"
    "test_real_page_load.sh"
    "test_multiple_games.sh"
    "test_with_ip_info.sh"
    "test_game_performance_en.sh"
    "test_full_game_load.sh"
    "test_full_game_load_with_vpn.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "Processing: $script"

        # Create backup
        cp "$script" "${script}.backup"

        # Count curl commands that need updating
        count=$(grep -c 'curl.*-s.*-w.*http' "$script" 2>/dev/null || echo "0")
        echo "  Found $count curl commands to update"

        # Add headers to curl commands
        # This is a placeholder - actual implementation will be manual

        echo "  ✓ Backup created: ${script}.backup"
        echo ""
    else
        echo "  ✗ Not found: $script"
        echo ""
    fi
done

echo "════════════════════════════════════════════════════════"
echo "Manual update required for each script"
echo "Please add these headers to all curl commands:"
echo ""
echo "  -H \"Cache-Control: no-cache, no-store, must-revalidate\" \\"
echo "  -H \"Pragma: no-cache\" \\"
echo "  -H \"Expires: 0\" \\"
echo ""
echo "════════════════════════════════════════════════════════"
