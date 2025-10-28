#!/bin/bash

# Game Performance Testing Script with IP Information
# Usage: ./test_with_ip_info.sh [game_type] [language]
# Example: ./test_with_ip_info.sh ArcadeBingo en-US

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
GAME_TYPE="${1:-ArcadeBingo}"
LANG="${2:-en-US}"
USERNAME="optest01"
PRODUCT_ID="ELS"
API_URL="https://wallet-api.geminiservice.cc/api/v1/operator/game/launch"

# Generate random sequence
generate_seq() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-' | fold -w 32 | head -n 1
}

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Game Performance Testing Tool (with IP Info)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Step 0: Get current IP information
echo -e "${YELLOW}[Step 0/6] Getting your IP location information...${NC}"
echo ""

# Try multiple IP detection services
echo -e "${CYAN}Checking your current IP address...${NC}"

# Method 1: ipapi.co
IP_INFO=$(curl -s --max-time 5 "https://ipapi.co/json/" 2>/dev/null)
if [ $? -eq 0 ] && [ ! -z "$IP_INFO" ]; then
    IP=$(echo "$IP_INFO" | grep -o '"ip":"[^"]*"' | cut -d'"' -f4)
    CITY=$(echo "$IP_INFO" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
    REGION=$(echo "$IP_INFO" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
    COUNTRY=$(echo "$IP_INFO" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
    COUNTRY_CODE=$(echo "$IP_INFO" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
    ORG=$(echo "$IP_INFO" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
    TIMEZONE=$(echo "$IP_INFO" | grep -o '"timezone":"[^"]*"' | cut -d'"' -f4)

    echo -e "${GREEN}✓ IP Detection Service: ipapi.co${NC}"
else
    # Method 2: ipinfo.io
    IP_INFO=$(curl -s --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
    if [ $? -eq 0 ] && [ ! -z "$IP_INFO" ]; then
        IP=$(echo "$IP_INFO" | grep -o '"ip":"[^"]*"' | cut -d'"' -f4)
        CITY=$(echo "$IP_INFO" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        REGION=$(echo "$IP_INFO" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
        COUNTRY=$(echo "$IP_INFO" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        COUNTRY_CODE="$COUNTRY"
        ORG=$(echo "$IP_INFO" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
        TIMEZONE=$(echo "$IP_INFO" | grep -o '"timezone":"[^"]*"' | cut -d'"' -f4)

        echo -e "${GREEN}✓ IP Detection Service: ipinfo.io${NC}"
    else
        # Method 3: Simple IP only
        IP=$(curl -s --max-time 5 "https://api.ipify.org" 2>/dev/null)
        CITY="Unknown"
        REGION="Unknown"
        COUNTRY="Unknown"
        COUNTRY_CODE="??"
        ORG="Unknown"
        TIMEZONE="Unknown"

        echo -e "${YELLOW}⚠ Limited IP info available${NC}"
    fi
fi

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║          YOUR CURRENT LOCATION INFO            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}IP Address:${NC}        ${GREEN}$IP${NC}"
echo -e "  ${CYAN}Country:${NC}           $COUNTRY ($COUNTRY_CODE)"
echo -e "  ${CYAN}Region/State:${NC}      $REGION"
echo -e "  ${CYAN}City:${NC}              $CITY"
echo -e "  ${CYAN}ISP/Organization:${NC}  $ORG"
echo -e "  ${CYAN}Timezone:${NC}          $TIMEZONE"
echo ""

# Check if testing from Bangladesh
if [ "$COUNTRY_CODE" = "BD" ]; then
    echo -e "${GREEN}✓ You are testing from Bangladesh!${NC}"
    echo -e "${GREEN}  This is REAL Bangladesh performance testing.${NC}"
    IS_BANGLADESH=true
else
    echo -e "${YELLOW}⚠ You are NOT testing from Bangladesh.${NC}"
    echo -e "${YELLOW}  Current location: $COUNTRY ($COUNTRY_CODE)${NC}"
    echo -e "${YELLOW}  Results will be ESTIMATES for Bangladesh.${NC}"
    IS_BANGLADESH=false
fi

echo ""
echo -e "${CYAN}Game Configuration:${NC}"
echo -e "  Game Type: ${GREEN}$GAME_TYPE${NC}"
echo -e "  Language: ${GREEN}$LANG${NC}"
echo -e "  Username: ${GREEN}$USERNAME${NC}"
echo ""

# Step 1: Get game URL
echo -e "${YELLOW}[Step 1/6] Fetching game URL...${NC}"
SEQ=$(generate_seq)
PAYLOAD="{\"seq\":\"$SEQ\",\"product_id\":\"$PRODUCT_ID\",\"username\":\"$USERNAME\",\"gametype\":\"$GAME_TYPE\",\"lang\":\"$LANG\"}"
MD5=$(echo -n "xdr56yhn${PAYLOAD}" | md5 -q)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "els-access-key: $MD5" \
  -d "$PAYLOAD")

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ API request failed${NC}"
    exit 1
fi

GAME_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | sed 's/\\u0026/\&/g')

if [ -z "$GAME_URL" ]; then
    echo -e "${RED}✗ Failed to get game URL${NC}"
    echo "API Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Game URL retrieved successfully${NC}"
echo ""
echo -e "${CYAN}Game URL:${NC}"
echo -e "  $GAME_URL"
echo ""

# Step 2: Test redirect page and get server IP
echo -e "${YELLOW}[Step 2/6] Testing redirect page & detecting server IPs...${NC}"

# Get redirect domain
REDIRECT_DOMAIN=$(echo "$GAME_URL" | sed 's|https://||' | cut -d'/' -f1)
echo -e "${CYAN}Redirect domain: $REDIRECT_DOMAIN${NC}"

# DNS lookup for redirect domain
REDIRECT_IPS=$(dig +short "$REDIRECT_DOMAIN" 2>/dev/null | grep -E '^[0-9]+\.')
if [ ! -z "$REDIRECT_IPS" ]; then
    echo -e "${CYAN}Redirect server IPs:${NC}"
    echo "$REDIRECT_IPS" | while read ip; do
        echo "  → $ip"
    done
else
    echo -e "${YELLOW}  Could not resolve redirect domain${NC}"
fi

# Test redirect page
REDIRECT_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_namelookup}|%{time_connect}|%{time_starttransfer}|%{time_total}|%{remote_ip}" "$GAME_URL")
REDIRECT_CODE=$(echo $REDIRECT_RESULT | cut -d'|' -f1)
REDIRECT_DNS=$(echo $REDIRECT_RESULT | cut -d'|' -f2)
REDIRECT_CONNECT=$(echo $REDIRECT_RESULT | cut -d'|' -f3)
REDIRECT_TTFB=$(echo $REDIRECT_RESULT | cut -d'|' -f4)
REDIRECT_TOTAL=$(echo $REDIRECT_RESULT | cut -d'|' -f5)
REDIRECT_IP=$(echo $REDIRECT_RESULT | cut -d'|' -f6)

echo -e "${CYAN}Connected to server IP: ${GREEN}$REDIRECT_IP${NC}"
echo "  HTTP Status: $REDIRECT_CODE"
echo "  DNS Lookup: ${REDIRECT_DNS}s"
echo "  TCP Connect: ${REDIRECT_CONNECT}s"
echo "  Time to First Byte: ${REDIRECT_TTFB}s"
echo "  Total Time: ${REDIRECT_TOTAL}s"
echo ""

# Step 3: Test game domains and their IPs
echo -e "${YELLOW}[Step 3/6] Testing game domains & server IPs...${NC}"

# Test www.shuangzi6688.com
echo -e "${CYAN}Domain: www.shuangzi6688.com${NC}"
WWW_IPS=$(dig +short www.shuangzi6688.com 2>/dev/null | grep -E '^[0-9]+\.')
if [ ! -z "$WWW_IPS" ]; then
    echo "  DNS IPs:"
    echo "$WWW_IPS" | while read ip; do
        echo "    → $ip"
    done
else
    echo -e "  ${YELLOW}DNS resolution failed${NC}"
fi

REAL_URL_WWW=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/www.shuangzi6688.com/')
WWW_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}|%{remote_ip}" "$REAL_URL_WWW")
WWW_CODE=$(echo $WWW_RESULT | cut -d'|' -f1)
WWW_TIME=$(echo $WWW_RESULT | cut -d'|' -f2)
WWW_SIZE=$(echo $WWW_RESULT | cut -d'|' -f3)
WWW_IP=$(echo $WWW_RESULT | cut -d'|' -f4)

echo "  Connected to: ${GREEN}$WWW_IP${NC}"
echo "  Status: $WWW_CODE | Time: ${WWW_TIME}s | Size: ${WWW_SIZE} bytes"

if [ "$WWW_SIZE" -lt 1000 ]; then
    echo -e "  ${RED}⚠️  Page abnormal (likely 404)${NC}"
    WWW_IS_404=true
else
    echo -e "  ${GREEN}✓ Valid content${NC}"
    WWW_IS_404=false
fi
echo ""

# Test hash.shuangzi6688.com
echo -e "${CYAN}Domain: hash.shuangzi6688.com${NC}"
HASH_IPS=$(dig +short hash.shuangzi6688.com 2>/dev/null | grep -E '^[0-9]+\.')
if [ ! -z "$HASH_IPS" ]; then
    echo "  DNS IPs:"
    echo "$HASH_IPS" | while read ip; do
        echo "    → $ip"
    done
else
    echo -e "  ${YELLOW}DNS resolution failed${NC}"
fi

REAL_URL_HASH=$(echo "$GAME_URL" | sed 's/jump.shuangzi6666.com/hash.shuangzi6688.com/')
HASH_RESULT=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}|%{remote_ip}" "$REAL_URL_HASH")
HASH_CODE=$(echo $HASH_RESULT | cut -d'|' -f1)
HASH_TIME=$(echo $HASH_RESULT | cut -d'|' -f2)
HASH_SIZE=$(echo $HASH_RESULT | cut -d'|' -f3)
HASH_IP=$(echo $HASH_RESULT | cut -d'|' -f4)

echo "  Connected to: ${GREEN}$HASH_IP${NC}"
echo "  Status: $HASH_CODE | Time: ${HASH_TIME}s | Size: ${HASH_SIZE} bytes"

if [ "$HASH_SIZE" -lt 1000 ]; then
    echo -e "  ${RED}⚠️  Page abnormal (likely 404)${NC}"
    HASH_IS_404=true
else
    echo -e "  ${GREEN}✓ Valid content${NC}"
    HASH_IS_404=false
fi
echo ""

# Step 4: Get geographic info for server IPs
echo -e "${YELLOW}[Step 4/6] Getting server geographic locations...${NC}"

if [ ! -z "$WWW_IP" ]; then
    echo -e "${CYAN}Server: $WWW_IP (www.shuangzi6688.com)${NC}"
    WWW_GEO=$(curl -s --max-time 3 "https://ipapi.co/$WWW_IP/json/" 2>/dev/null)
    if [ ! -z "$WWW_GEO" ]; then
        WWW_COUNTRY=$(echo "$WWW_GEO" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
        WWW_CITY=$(echo "$WWW_GEO" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        WWW_ORG=$(echo "$WWW_GEO" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
        echo "  Location: $WWW_CITY, $WWW_COUNTRY"
        echo "  CDN/ISP: $WWW_ORG"
    else
        echo "  Location: Unknown"
    fi
    echo ""
fi

if [ ! -z "$HASH_IP" ]; then
    echo -e "${CYAN}Server: $HASH_IP (hash.shuangzi6688.com)${NC}"
    HASH_GEO=$(curl -s --max-time 3 "https://ipapi.co/$HASH_IP/json/" 2>/dev/null)
    if [ ! -z "$HASH_GEO" ]; then
        HASH_COUNTRY=$(echo "$HASH_GEO" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
        HASH_CITY=$(echo "$HASH_GEO" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        HASH_ORG=$(echo "$HASH_GEO" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
        echo "  Location: $HASH_CITY, $HASH_COUNTRY"
        echo "  CDN/ISP: $HASH_ORG"
    else
        echo "  Location: Unknown"
    fi
    echo ""
fi

# Step 5: Verify content
echo -e "${YELLOW}[Step 5/6] Verifying page content...${NC}"

if [ "$WWW_IS_404" = false ] || [ "$HASH_IS_404" = false ]; then
    if [ "$WWW_IS_404" = false ]; then
        TEST_DOMAIN="www.shuangzi6688.com"
        TEST_URL="$REAL_URL_WWW"
    else
        TEST_DOMAIN="hash.shuangzi6688.com"
        TEST_URL="$REAL_URL_HASH"
    fi

    echo -e "${GREEN}✓ Using domain: $TEST_DOMAIN${NC}"

    # Download and check
    TEMP_FILE="/tmp/game_content_$$.html"
    curl -s "$TEST_URL" -o "$TEMP_FILE"

    if grep -q "404 Error" "$TEMP_FILE"; then
        echo -e "${RED}✗ Content is 404 error page${NC}"
        rm -f "$TEMP_FILE"
        HAS_VALID_CONTENT=false
    else
        echo -e "${GREEN}✓ Valid game content detected${NC}"
        CONTENT_SIZE=$(wc -c < "$TEMP_FILE")
        echo "  Page size: ${CONTENT_SIZE} bytes"
        rm -f "$TEMP_FILE"
        HAS_VALID_CONTENT=true
    fi
else
    echo -e "${RED}✗ Both domains return 404${NC}"
    HAS_VALID_CONTENT=false
fi
echo ""

# Step 6: Summary
echo -e "${MAGENTA}╔════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║              TEST SUMMARY                      ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Testing Location:${NC}"
echo "  Your IP: $IP"
echo "  Location: $CITY, $COUNTRY ($COUNTRY_CODE)"
echo "  ISP: $ORG"
echo ""

echo -e "${CYAN}Server Information:${NC}"
echo "  www.shuangzi6688.com → $WWW_IP"
if [ ! -z "$WWW_CITY" ]; then
    echo "    Location: $WWW_CITY, $WWW_COUNTRY"
    echo "    CDN: $WWW_ORG"
fi
echo ""
echo "  hash.shuangzi6688.com → $HASH_IP"
if [ ! -z "$HASH_CITY" ]; then
    echo "    Location: $HASH_CITY, $HASH_COUNTRY"
    echo "    CDN: $HASH_ORG"
fi
echo ""

echo -e "${CYAN}Performance Results:${NC}"
if [ "$HAS_VALID_CONTENT" = true ]; then
    echo -e "  ${GREEN}✓ Game is accessible${NC}"
    BEST_TIME=$(echo "$WWW_TIME $HASH_TIME" | tr ' ' '\n' | sort -n | head -1)
    echo "  Load time: ${BEST_TIME}s"

    if [ "$IS_BANGLADESH" = true ]; then
        echo ""
        echo -e "${GREEN}✓ This is REAL Bangladesh performance!${NC}"
    else
        echo ""
        echo -e "${YELLOW}Bangladesh Estimates (you are testing from $COUNTRY):${NC}"
        echo "  100 KB/s: ~20-25 seconds"
        echo "  500 KB/s: ~5-7 seconds"
        echo "  1 Mbps+: ~8-12 seconds"
    fi
else
    echo -e "  ${RED}✗ Game not accessible (404)${NC}"
fi

echo ""
echo -e "${GREEN}Test completed!${NC}"
