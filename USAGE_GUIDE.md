# Game Performance Testing - Usage Guide

## ⚠️ Important Clarification

**Q: Are you actually testing from Bangladesh?**

**A: No, I am NOT connecting from Bangladesh.**

I am testing from **your current location** (based on your machine's network), and then:
1. Measuring the actual performance from here
2. **Estimating** what Bangladesh performance would be like based on:
   - Known Bangladesh network conditions
   - Geographic distance calculations
   - Bandwidth simulation

This is **simulation and estimation**, not real Bangladesh testing.

---

## 📊 What These Tests Actually Do

### Current Testing Method:
```
Your Location (Taiwan/US/etc.)
    ↓
    Testing game load speed
    ↓
    Estimating Bangladesh performance by:
    - Adding latency (Bangladesh to US CDN = 200-400ms)
    - Limiting bandwidth (100KB/s, 500KB/s, 1Mbps)
    - Calculating expected load times
```

### What It Does NOT Do:
- ❌ Does not connect from Bangladesh
- ❌ Does not use Bangladesh ISP
- ❌ Does not test Bangladesh mobile networks
- ❌ Does not account for Bangladesh-specific issues (DNS blocking, packet loss, etc.)

---

## 🚀 Available Test Scripts

### 1. Single Game Test (English Version)
```bash
cd /tmp/cdn/game-test/
./test_game_performance_en.sh [GameType] [Language]

# Examples:
./test_game_performance_en.sh ArcadeBingo en-US
./test_game_performance_en.sh StandAloneDice zh-CN
./test_game_performance_en.sh BonusBingo en-US
```

**What it tests:**
- Game URL generation
- Redirect page performance
- Both game domains (www and hash)
- Page content verification
- Resource loading
- Bangladesh performance estimation

---

### 2. Multiple Random Games Test
```bash
cd /tmp/cdn/game-test/
./test_multiple_games.sh [NumberOfGames] [Language]

# Examples:
./test_multiple_games.sh 3 en-US   # Test 3 random games
./test_multiple_games.sh 5 zh-CN   # Test 5 random games
./test_multiple_games.sh 10 en-US  # Test 10 random games
```

**What it tests:**
- Randomly selects N games from available 56 games
- Tests each game for accessibility
- Generates summary report with:
  - Success rate
  - Average load time
  - List of accessible vs 404 games

---

### 3. Chinese Version (Original)
```bash
cd /tmp/cdn/game-test/
./test_game_performance.sh [遊戲類型] [語言]
```

---

## 📋 Available Game Types

### Bingo Games (11 games):
- ArcadeBingo
- BonusBingo
- CaribbeanBingo
- CaveBingo
- EggHuntBingo
- LostRuins
- MagicBingo
- MapleBingo
- OdinBingo
- Steampunk
- Steampunk2

### Multiplayer Games (8 games):
- MultiPlayerAviator
- MultiPlayerAviator2
- MultiPlayerBoomersGR
- MultiPlayerCrash
- MultiPlayerCrashCL
- MultiPlayerCrashGR
- MultiPlayerCrashNE
- MultiPlayerMultiHilo

### StandAlone Games (37 games):
- StandAloneDiamonds
- StandAloneDice
- StandAloneDragonTower
- StandAloneEgyptHilo
- StandAloneHilo, StandAloneHiloCL, StandAloneHiloGR, StandAloneHiloNE
- StandAloneKeno
- StandAloneLimbo, StandAloneLimboCL, StandAloneLimboGR, StandAloneLimboNE
- StandAloneLuckyDropCOC, StandAloneLuckyDropCOC2, StandAloneLuckyDropGX, StandAloneLuckyDropOLY
- StandAloneLuckyHilo
- StandAloneMines (and 8 variants)
- StandAlonePlinko, StandAlonePlinkoCL, StandAlonePlinkoGR, StandAlonePlinkoNE
- StandAloneVideoPoker
- StandAloneWheel
- StandAloneForestTeaParty

**Total: 56 games available**

---

## 📝 Example Usage Scenarios

### Scenario 1: Quick Single Game Test
```bash
cd /tmp/cdn/game-test/
./test_game_performance_en.sh ArcadeBingo en-US
```

**Output includes:**
- ✅ Game URL
- ✅ Redirect page timing
- ✅ Domain availability
- ✅ Content verification
- ✅ Bangladesh estimates

---

### Scenario 2: Test Multiple Random Games
```bash
cd /tmp/cdn/game-test/
./test_multiple_games.sh 5 en-US
```

**Example output:**
```
Testing 5 random games:
1. ArcadeBingo
2. StandAloneDice
3. BonusBingo
4. MultiPlayerCrash
5. StandAlonePlinko

Results:
✓ Accessible: 3/5 (60%)
✗ 404 Errors: 2/5 (40%)
Average load time: 0.234s
```

---

### Scenario 3: Test All Bingo Games
```bash
# Create custom script
for game in ArcadeBingo BonusBingo CaribbeanBingo CaveBingo; do
    echo "Testing $game..."
    ./test_game_performance_en.sh $game en-US
    sleep 2
done
```

---

## 🔍 How to Test REAL Bangladesh Performance

Since my tests are estimates, here's how to get **real** Bangladesh data:

### Method 1: VPN (Easiest)
```bash
# 1. Connect to Bangladesh VPN server
# 2. Verify location:
curl -s https://ipapi.co/json/ | grep country

# 3. Run test:
./test_game_performance_en.sh ArcadeBingo en-US
```

### Method 2: Cloud Server in Asia
```bash
# Deploy on AWS Mumbai (ap-south-1) or Singapore (ap-southeast-1)
# These are closest to Bangladesh

# On the server:
git clone [your-repo]
cd /tmp/cdn/game-test/
./test_game_performance_en.sh ArcadeBingo en-US
```

### Method 3: Ask Bangladesh Users
Send them this one-liner:
```bash
curl -o /dev/null -s -w "Load Time: %{time_total}s\n" \
  "YOUR_GAME_URL_HERE"
```

---

## 📊 Understanding Test Results

### Example Output Explanation:
```
[Step 1/5] Fetching game URL...
✓ Game URL retrieved successfully
```
→ API call successful, game URL generated

```
[Step 2/5] Testing redirect page performance...
DNS Lookup: 0.289s
TCP Connect: 0.298s
TLS Handshake: 0.321s
Time to First Byte: 1.347s
Total Time: 1.348s
```
→ Redirect page takes 1.35 seconds to respond

```
[Step 3/5] Testing real game domains...
Testing domain: www.shuangzi6688.com
  Status Code: 200 | Time: 0.281s | Size: 324 bytes
  ⚠️  Page abnormal (likely 404)
```
→ Domain responds but content is small (404 page)

```
Testing domain: hash.shuangzi6688.com
  Status Code: 200 | Time: 0.212s | Size: 5006 bytes
```
→ This domain has actual content (not 404)

```
Bangladesh Region Expected Performance:
  100 KB/s connection: ~20-25 seconds (Very Poor)
  500 KB/s connection: ~5-7 seconds (Poor)
  1 Mbps+ connection: ~8-12 seconds (Marginal)
```
→ **Estimated** Bangladesh performance based on simulations

---

## 🎯 Current Test Limitations

### What We CAN Measure:
✅ Game URL generation
✅ Server response times
✅ Domain availability
✅ Resource sizes
✅ Load times from current location

### What We CANNOT Measure (without Bangladesh connection):
❌ Real Bangladesh network latency
❌ Bangladesh ISP throttling
❌ Bangladesh DNS resolution issues
❌ Bangladesh mobile network performance
❌ Peak hour performance in Bangladesh
❌ Bangladesh-specific blocking/filtering

---

## 💡 Recommendations

### For Development/Staging:
1. Use these scripts for quick checks
2. Estimates are good enough for development
3. Test multiple games to find patterns

### For Production/Release:
1. **Must** test from actual Bangladesh network
2. Use VPN or cloud server in Asia
3. Test during Bangladesh peak hours (7-10 PM local time)
4. Test on mobile networks (not just WiFi)
5. Get feedback from real Bangladesh users

---

## 📁 File Locations

```
/tmp/cdn/game-test/
├── test_game_performance_en.sh      # Single game test (English)
├── test_game_performance.sh         # Single game test (Chinese)
├── test_multiple_games.sh           # Multiple games test
├── FINAL_TEST_REPORT.md             # Detailed analysis report
├── README_BANGLADESH_TESTING.md     # Bangladesh testing guide
└── USAGE_GUIDE.md                   # This file
```

---

## 🆘 Troubleshooting

### Problem: "Failed to get game URL"
**Solution:** Check API credentials, Token may be expired

### Problem: All games return 404
**Solution:** Games not deployed, or Token invalid

### Problem: "Permission denied"
**Solution:** Make scripts executable:
```bash
chmod +x /tmp/cdn/game-test/*.sh
```

### Problem: Results don't match Bangladesh user reports
**Solution:** Your estimates are just that - estimates. Use VPN or cloud server for real data.

---

## 🔄 Regular Testing Workflow

```bash
# Weekly test routine:
cd /tmp/cdn/game-test/

# 1. Test 10 random games
./test_multiple_games.sh 10 en-US > weekly_test_$(date +%Y%m%d).log

# 2. Test key games individually
./test_game_performance_en.sh ArcadeBingo en-US
./test_game_performance_en.sh StandAloneDice en-US

# 3. Review results
cat weekly_test_*.log | grep "Success rate"
```

---

## 📞 Questions?

- All scripts include detailed comments
- Check FINAL_TEST_REPORT.md for analysis
- Read README_BANGLADESH_TESTING.md for real testing methods
