# Testing Scripts Overview

## 📋 Available Scripts

### 1. `test_with_ip_info.sh` - Single Game with IP Information ⭐ NEW
**Best for:** Detailed analysis with IP and location information

```bash
./test_with_ip_info.sh [GameType] [Language]

# Example:
./test_with_ip_info.sh ArcadeBingo en-US
```

**Shows:**
- ✅ Your current IP address and location
- ✅ Server IP addresses (DNS resolution)
- ✅ Server geographic locations
- ✅ Connection details to each server
- ✅ Whether you're testing from Bangladesh or not
- ✅ Performance metrics

**Sample Output:**
```
YOUR CURRENT LOCATION INFO
  IP Address:        xxx.xxx.xxx.xxx
  Country:           Taiwan (TW)
  City:              Taipei
  ISP/Organization:  Your ISP Name

Server Information:
  www.shuangzi6688.com → 203.69.81.58
    Location: Unknown
  hash.shuangzi6688.com → 203.69.81.57
    Location: Unknown
```

---

### 2. `test_game_performance_en.sh` - Single Game (English)
**Best for:** Quick single game testing

```bash
./test_game_performance_en.sh [GameType] [Language]

# Example:
./test_game_performance_en.sh ArcadeBingo en-US
```

**Shows:**
- Game URL generation
- Redirect page performance
- Domain accessibility
- Bangladesh estimates
- (Does NOT show IP information)

---

### 3. `test_multiple_games.sh` - Multiple Random Games
**Best for:** Testing many games at once

```bash
./test_multiple_games.sh [NumberOfGames] [Language]

# Examples:
./test_multiple_games.sh 3 en-US
./test_multiple_games.sh 10 zh-CN
```

**Shows:**
- Random game selection
- Success rate statistics
- Average load times
- Summary report
- (Does NOT show IP information)

---

### 4. `test_game_performance.sh` - Single Game (Chinese)
**Best for:** Chinese-speaking users

```bash
./test_game_performance.sh [遊戲類型] [語言]
```

---

## 🎯 Which Script Should You Use?

| Scenario | Recommended Script |
|----------|-------------------|
| Want to see IP addresses and server locations | `test_with_ip_info.sh` ⭐ |
| Quick test of one game | `test_game_performance_en.sh` |
| Test multiple games for statistics | `test_multiple_games.sh` |
| Need Chinese interface | `test_game_performance.sh` |

---

## 📊 Server IP Information

From recent tests, the game servers are located at:

### Redirect Server (jump.shuangzi6666.com)
- DNS IPs: 203.69.81.50, 203.69.81.48
- Connected to: 210.71.227.186

### Game Server (www.shuangzi6688.com)
- DNS IPs: 203.69.81.40, 203.69.81.58
- Connected to: 203.69.81.58

### Game Server (hash.shuangzi6688.com)
- DNS IPs: 203.69.81.58, 203.69.81.57
- Connected to: 203.69.81.57

**Note:** These are Akamai CDN IPs. The exact IP you connect to may vary based on your location.

---

## 🌍 Bangladesh Testing Detection

The `test_with_ip_info.sh` script automatically detects if you're testing from Bangladesh:

**If testing FROM Bangladesh:**
```
✓ You are testing from Bangladesh!
  This is REAL Bangladesh performance testing.
```

**If testing from OTHER location:**
```
⚠ You are NOT testing from Bangladesh.
  Current location: Taiwan (TW)
  Results will be ESTIMATES for Bangladesh.
```

---

## 💡 Quick Usage Examples

```bash
cd /tmp/cdn/game-test/

# Show IP info for ArcadeBingo
./test_with_ip_info.sh ArcadeBingo en-US

# Show IP info for different game
./test_with_ip_info.sh StandAloneDice en-US

# Test 5 random games (no IP details)
./test_multiple_games.sh 5 en-US
```

---

## 📝 Summary

- **For detailed IP analysis:** Use `test_with_ip_info.sh`
- **For quick testing:** Use `test_game_performance_en.sh`
- **For batch testing:** Use `test_multiple_games.sh`
- **所有腳本都可用** ✅
