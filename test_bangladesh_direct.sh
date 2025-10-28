#!/usr/bin/env bash

echo "════════════════════════════════════════════════════════"
echo "從孟加拉測試遊戲加載（使用預先獲取的 URL）"
echo "════════════════════════════════════════════════════════"
echo ""

# Check IP
MY_IP=$(curl -s https://api.ipify.org)
LOCATION=$(curl -s "http://ip-api.com/json/${MY_IP}")
COUNTRY=$(echo "$LOCATION" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)

echo "當前 IP: $MY_IP"
echo "當前位置: $COUNTRY"
echo ""

if [ "$COUNTRY" != "Bangladesh" ]; then
    echo "⚠️  警告：你不在孟加拉！當前位置：$COUNTRY"
    echo "請先連接到孟加拉 VPN"
    echo ""
    read -p "是否繼續測試？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 使用之前獲取的遊戲 URL（這些 Token 可能已過期，但可以測試網絡性能）
GAME_URLS=(
    "https://www.shuangzi6688.com/Hash/StandAloneDice/?Lang=en-US&ProductId=ELS&Token=868b6933a94a46906338ed0dc68d64cb3a3aa541b758b4b547733bed1f07aefd99f0f085d0c95ade6487d201793a95e8"
    "https://www.shuangzi6688.com/Hash/StandAloneHilo/?Lang=en-US&ProductId=ELS&Token=868b6933a94a46906338ed0dc68d64cbb7191187c95ecf42a3568c11ec95c72799f0f085d0c95ade6487d201793a95e8"
    "https://www.shuangzi6688.com/Bingo/EggHuntBingo/?Lang=en-US&ProductId=ELS&Token=397261d64dd20d6a4a534df6de5bf008327a80ed9b1112b3cbd83545645fe48a6030f04ab75c06c2deaa84361efdd476"
)

GAME_NAMES=(
    "StandAloneDice"
    "StandAloneHilo"
    "EggHuntBingo"
)

RESULTS_DIR="./puppeteer_results_bangladesh"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "測試 ${#GAME_URLS[@]} 個遊戲..."
echo ""

for i in "${!GAME_URLS[@]}"; do
    game="${GAME_NAMES[$i]}"
    url="${GAME_URLS[$i]}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$((i+1))/${#GAME_URLS[@]}] 測試: $game"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    OUTPUT_JSON="$RESULTS_DIR/${game}_bangladesh_${TIMESTAMP}.json"
    
    node puppeteer_game_test.js "$url" \
        --wait=10000 \
        --output="$OUTPUT_JSON"
    
    echo ""
    
    if [ $i -lt $((${#GAME_URLS[@]} - 1)) ]; then
        echo "等待 3 秒後繼續..."
        sleep 3
    fi
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "✓ 所有測試完成"
echo "════════════════════════════════════════════════════════"
echo ""
echo "結果保存在: $RESULTS_DIR/"
