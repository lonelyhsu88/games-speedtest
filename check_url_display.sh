#!/bin/bash
echo "檢查所有測試腳本的URL顯示..."
echo ""

scripts=(
  "test_multiple_with_vpn.sh"
  "test_with_vpn_workaround.sh"
  "test_real_page_load.sh"
  "test_multiple_games.sh"
  "test_with_ip_info.sh"
  "test_game_performance_en.sh"
  "test_full_game_load.sh"
  "test_full_game_load_with_vpn.sh"
)

for script in "${scripts[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "檢查: $script"
  echo ""
  
  count=$(grep -c "Test URL\|Game URL" "$script" 2>/dev/null || echo "0")
  
  if [ "$count" -gt 0 ]; then
    echo "✓ 有顯示URL ($count 處)"
    grep -n "Test URL\|Game URL" "$script" | head -3
  else
    echo "✗ 沒有顯示URL"
  fi
  echo ""
done
