#!/bin/bash

# Show Client IP Information
# This script displays YOUR (client) IP address and location

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           CLIENT IP INFORMATION                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Detecting your IP address...${NC}"
echo ""

# Method 1: ipify.org (most reliable, IP only)
echo -e "${YELLOW}Method 1: Using ipify.org (most reliable)${NC}"
IP=$(curl -s --max-time 5 "https://api.ipify.org" 2>/dev/null)

if [ $? -eq 0 ] && [ ! -z "$IP" ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo ""
    echo -e "  ${CYAN}Your IP:${NC} ${GREEN}${IP}${NC}"
    echo ""
else
    echo -e "${RED}✗ Failed${NC}"
    echo ""
fi

# Method 2: ipinfo.io (detailed info)
echo -e "${YELLOW}Method 2: Using ipinfo.io (detailed info)${NC}"
IP_INFO2=$(curl -s --max-time 5 "https://ipinfo.io/json" 2>/dev/null)

if [ $? -eq 0 ] && [ ! -z "$IP_INFO2" ]; then
    IP2=$(echo "$IP_INFO2" | grep -o '"ip":"[^"]*"' | cut -d'"' -f4)
    CITY=$(echo "$IP_INFO2" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
    REGION=$(echo "$IP_INFO2" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
    COUNTRY_CODE=$(echo "$IP_INFO2" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
    ORG=$(echo "$IP_INFO2" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
    POSTAL=$(echo "$IP_INFO2" | grep -o '"postal":"[^"]*"' | cut -d'"' -f4)
    LOC=$(echo "$IP_INFO2" | grep -o '"loc":"[^"]*"' | cut -d'"' -f4)
    TIMEZONE=$(echo "$IP_INFO2" | grep -o '"timezone":"[^"]*"' | cut -d'"' -f4)

    echo -e "${GREEN}✓ Success${NC}"
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║              YOUR CLIENT IP DETAILS                    ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}IP Address:${NC}        ${GREEN}${IP2}${NC}"
    echo -e "  ${CYAN}Country:${NC}           ${COUNTRY_CODE}"
    echo -e "  ${CYAN}Region:${NC}            ${REGION}"
    echo -e "  ${CYAN}City:${NC}              ${CITY}"
    echo -e "  ${CYAN}ISP/Org:${NC}           ${ORG}"
    echo -e "  ${CYAN}Postal Code:${NC}       ${POSTAL}"
    echo -e "  ${CYAN}Timezone:${NC}          ${TIMEZONE}"
    echo -e "  ${CYAN}Coordinates:${NC}       ${LOC}"
    echo ""

    # Store primary IP if not already set
    if [ -z "$IP" ]; then
        IP="$IP2"
    fi
else
    echo -e "${RED}✗ Failed${NC}"
    echo ""
fi

# Method 3: ifconfig.me (backup)
echo -e "${YELLOW}Method 3: Using ifconfig.me (backup)${NC}"
IP3=$(curl -s --max-time 5 "https://ifconfig.me" 2>/dev/null)

if [ $? -eq 0 ] && [ ! -z "$IP3" ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo ""
    echo -e "  ${CYAN}IP Address:${NC}        ${GREEN}${IP3}${NC}"
    echo ""
    if [ -z "$IP" ]; then
        IP="$IP3"
    fi
else
    echo -e "${RED}✗ Failed${NC}"
    echo ""
fi

# Check if in Bangladesh
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Testing Location Analysis:${NC}"
echo ""

# Get country name from country code if we have it
if [ ! -z "$COUNTRY_CODE" ]; then
    case "$COUNTRY_CODE" in
        "BD") COUNTRY="Bangladesh" ;;
        "TW") COUNTRY="Taiwan" ;;
        "US") COUNTRY="United States" ;;
        "SG") COUNTRY="Singapore" ;;
        "IN") COUNTRY="India" ;;
        "CN") COUNTRY="China" ;;
        "HK") COUNTRY="Hong Kong" ;;
        "JP") COUNTRY="Japan" ;;
        *) COUNTRY="$COUNTRY_CODE" ;;
    esac
fi

if [ "$COUNTRY_CODE" = "BD" ]; then
    echo -e "${GREEN}✓✓✓ YOU ARE TESTING FROM BANGLADESH! ✓✓✓${NC}"
    echo -e "${GREEN}    This is REAL Bangladesh performance testing.${NC}"
    echo ""
    echo -e "${CYAN}Bangladesh Network Info:${NC}"
    echo -e "  Your IP: ${IP}"
    echo -e "  Your ISP: ${ORG}"
    echo -e "  Your Location: ${CITY}, ${REGION}"
    echo -e "  Timezone: ${TIMEZONE}"
else
    echo -e "${YELLOW}⚠ You are NOT testing from Bangladesh.${NC}"
    if [ ! -z "$COUNTRY" ] && [ ! -z "$COUNTRY_CODE" ]; then
        echo -e "${YELLOW}  Current location: ${COUNTRY} (${COUNTRY_CODE})${NC}"
    fi
    echo -e "${YELLOW}  Current IP: ${IP}${NC}"
    echo ""
    echo -e "${CYAN}To test from Bangladesh, you need to:${NC}"
    echo "  1. Use Bangladesh VPN"
    echo "  2. Deploy test server in Bangladesh or nearby (Mumbai/Singapore)"
    echo "  3. Test from actual Bangladesh network"
    echo ""
    echo -e "${CYAN}Your current test results will be ESTIMATES for Bangladesh.${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Client IP detection completed!${NC}"
echo ""
echo -e "${CYAN}To use this IP info in game testing, run:${NC}"
echo "  ./test_with_ip_info.sh ArcadeBingo en-US"
echo ""
