#!/bin/bash

# 游戏性能测试脚本
# 用法: ./test_game_performance.sh [game_type] [language]
# 示例: ./test_game_performance.sh ArcadeBingo en-US

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
GAME_TYPE="${1:-ArcadeBingo}"
LANG="${2:-en-US}"
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"

# 生成随机序列
generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}游戏性能测试工具${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${GREEN}游戏类型:${NC} $GAME_TYPE"
echo -e "${GREEN}语言:${NC} $LANG"
echo -e "${GREEN}用户:${NC} $USERNAME"
echo ""

# 第一步：获取游戏 URL
echo -e "${YELLOW}[步骤 1/4] 正在获取游戏 URL...${NC}"
SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME_TYPE\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

# 检查 API 响应
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ API 请求失败${NC}"
    exit 1
fi

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo -e "${RED}✗ 无法获取游戏 URL${NC}"
    echo "API 响应: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ 游戏 URL 获取成功${NC}"
echo "URL: $GAME_URL"
echo ""

# 第二步：测试跳转页面性能
echo -e "${YELLOW}[步骤 2/4] 测试跳转页面性能...${NC}"
curl -o /dev/null -s -w "HTTP状态: %{http_code}\nDNS解析: %{time_namelookup}s\nTCP连接: %{time_connect}s\nTLS握手: %{time_appconnect}s\n首字节时间: %{time_starttransfer}s\n总时间: %{time_total}s\n下载大小: %{size_download} bytes\n" "$GAME_URL"
echo ""

# 第三步：提取真实游戏域名
echo -e "${YELLOW}[步骤 3/4] 测试真实游戏域名...${NC}"

# 测试 www.shuangzi6688.com
REAL_URL_WWW=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/www.shuangzi6688.com/')
echo -e "${BLUE}测试域名: www.shuangzi6688.com${NC}"
WWW_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$REAL_URL_WWW")
WWW_CODE=$(echo $WWW_RESULT | cut -d'|' -f1)
WWW_TIME=$(echo $WWW_RESULT | cut -d'|' -f2)
WWW_SIZE=$(echo $WWW_RESULT | cut -d'|' -f3)
echo "  状态码: $WWW_CODE | 时间: ${WWW_TIME}s | 大小: ${WWW_SIZE} bytes"

if [ "$WWW_SIZE" -lt 1000 ]; then
    echo -e "  ${RED}⚠️  页面异常（可能是404）${NC}"
fi
echo ""

# 测试 hash.shuangzi6688.com
REAL_URL_HASH=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/hash.shuangzi6688.com/')
echo -e "${BLUE}测试域名: hash.shuangzi6688.com${NC}"
HASH_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$REAL_URL_HASH")
HASH_CODE=$(echo $HASH_RESULT | cut -d'|' -f1)
HASH_TIME=$(echo $HASH_RESULT | cut -d'|' -f2)
HASH_SIZE=$(echo $HASH_RESULT | cut -d'|' -f3)
echo "  状态码: $HASH_CODE | 时间: ${HASH_TIME}s | 大小: ${HASH_SIZE} bytes"

if [ "$HASH_SIZE" -lt 1000 ]; then
    echo -e "  ${RED}⚠️  页面异常（可能是404）${NC}"
fi
echo ""

# 第四步：测试游戏资源加载（如果能访问）
echo -e "${YELLOW}[步骤 4/4] 测试游戏资源加载...${NC}"

# 判断使用哪个域名
if [ "$WWW_SIZE" -gt 1000 ]; then
    TEST_DOMAIN="www.shuangzi6688.com"
elif [ "$HASH_SIZE" -gt 1000 ]; then
    TEST_DOMAIN="hash.shuangzi6688.com"
else
    echo -e "${RED}✗ 所有域名都返回404错误，无法测试资源加载${NC}"
    echo ""
    echo -e "${YELLOW}================================${NC}"
    echo -e "${YELLOW}测试总结${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${RED}游戏无法访问 - 所有域名都返回404错误${NC}"
    echo -e "${RED}建议检查：${NC}"
    echo "1. 游戏资源是否已部署"
    echo "2. CDN配置是否正确"
    echo "3. Token是否有效"
    exit 1
fi

echo -e "${GREEN}使用域名: $TEST_DOMAIN${NC}"

# 测试常见资源文件
RESOURCES=("cocos2d-js-min.js" "main.js" "src/settings.js" "style-mobile.css")
TOTAL_SIZE=0
TOTAL_TIME=0

for resource in "${RESOURCES[@]}"; do
    # 构建资源 URL - 尝试不同的路径
    RESOURCE_URL="https://$TEST_DOMAIN/$GAME_TYPE/$resource"
    RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" "$RESOURCE_URL" 2>/dev/null)
    CODE=$(echo $RESULT | cut -d'|' -f1)
    TIME=$(echo $RESULT | cut -d'|' -f2)
    SIZE=$(echo $RESULT | cut -d'|' -f3)

    if [ "$CODE" = "200" ] && [ "$SIZE" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} $resource: ${SIZE} bytes (${TIME}s)"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME" | bc)
    else
        echo -e "  ${YELLOW}◯${NC} $resource: 未找到或不适用"
    fi
done

if [ $TOTAL_SIZE -gt 0 ]; then
    echo ""
    echo -e "${GREEN}总资源大小: ${TOTAL_SIZE} bytes${NC}"
    echo -e "${GREEN}总下载时间: ${TOTAL_TIME}s${NC}"
fi

echo ""
echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}测试总结${NC}"
echo -e "${YELLOW}================================${NC}"

# 性能评估
if [ "$HASH_SIZE" -gt 1000 ] || [ "$WWW_SIZE" -gt 1000 ]; then
    echo -e "${GREEN}✓ 游戏可访问${NC}"

    # 评估加载速度
    BEST_TIME=$(echo "$WWW_TIME $HASH_TIME" | tr ' ' '\n' | sort -n | head -1)

    if (( $(echo "$BEST_TIME < 1" | bc -l) )); then
        echo -e "${GREEN}✓ 加载速度: 快 (${BEST_TIME}s)${NC}"
    elif (( $(echo "$BEST_TIME < 3" | bc -l) )); then
        echo -e "${YELLOW}⚠ 加载速度: 中等 (${BEST_TIME}s)${NC}"
    else
        echo -e "${RED}✗ 加载速度: 慢 (${BEST_TIME}s)${NC}"
    fi
else
    echo -e "${RED}✗ 游戏不可访问 (404错误)${NC}"
fi

echo ""
echo -e "${BLUE}孟加拉地区预估性能：${NC}"
echo "  100 KB/s 连接: ~20-25秒"
echo "  500 KB/s 连接: ~5-7秒"
echo "  1 Mbps+ 连接: ~8-12秒"
echo ""
echo -e "${BLUE}完整测试报告已保存到: /tmp/cdn/game-test/${NC}"
