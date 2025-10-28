# How to Test Bangladesh Region Performance

## Methods to Test Bangladesh Network Performance

### 🎯 Method 1: Using VPN/Proxy (Recommended)

The most accurate way to test Bangladesh performance is to use a Bangladesh-based VPN or proxy server.

#### Option A: Commercial VPN Services
```bash
# 1. Connect to a VPN service with Bangladesh servers
#    Popular services: ExpressVPN, NordVPN, Surfshark
#    Select Bangladesh (Dhaka) server

# 2. Verify your IP location
curl -s https://ipapi.co/json/ | grep -E '"country"|"city"'

# 3. Run the test script
cd /tmp/cdn/game-test/
./test_game_performance_en.sh ArcadeBingo en-US
```

#### Option B: Proxy Server
```bash
# Using curl with Bangladesh proxy
export https_proxy=http://bangladesh-proxy-server:port
export http_proxy=http://bangladesh-proxy-server:port

# Run test through proxy
./test_game_performance_en.sh ArcadeBingo en-US
```

---

### 🎯 Method 2: Network Simulation (Current Method)

Simulate Bangladesh network conditions using bandwidth and latency controls.

#### Simulating Slow Bangladesh Connection:

```bash
# Test with bandwidth limit (simulating 100 KB/s connection)
curl --limit-rate 100K -o /dev/null -s -w \
  "Time: %{time_total}s\nSpeed: %{speed_download} bytes/sec\n" \
  "https://www.shuangzi6688.com/path/to/game"

# Test with bandwidth limit (simulating 500 KB/s connection)
curl --limit-rate 500K -o /dev/null -s -w \
  "Time: %{time_total}s\nSpeed: %{speed_download} bytes/sec\n" \
  "https://www.shuangzi6688.com/path/to/game"
```

#### Using Network Throttling Tool:

**On macOS:**
```bash
# Install Network Link Conditioner
# 1. Download from Apple Developer Tools
# 2. Open System Preferences > Network Link Conditioner
# 3. Select "3G" or "Edge" profile for slow connection
# 4. Run tests
```

**On Linux:**
```bash
# Using tc (traffic control) to simulate latency
sudo tc qdisc add dev eth0 root netem delay 300ms 50ms
# 300ms delay (typical Bangladesh to US CDN)
# 50ms jitter

# Run tests
./test_game_performance_en.sh ArcadeBingo en-US

# Remove restriction when done
sudo tc qdisc del dev eth0 root
```

---

### 🎯 Method 3: AWS/Cloud Server in Bangladesh Region

Deploy a test server in Bangladesh or nearby regions.

#### Using AWS EC2:
```bash
# 1. Launch EC2 instance in ap-south-1 (Mumbai) - closest to Bangladesh
# 2. SSH into the instance
ssh -i your-key.pem ubuntu@ec2-instance-ip

# 3. Install dependencies
sudo apt-get update
sudo apt-get install curl bc

# 4. Copy test script to server
scp -i your-key.pem test_game_performance_en.sh ubuntu@ec2-instance-ip:~/

# 5. Run tests from Bangladesh region
./test_game_performance_en.sh ArcadeBingo en-US
```

---

### 🎯 Method 4: WebPageTest (Online Tool)

Use WebPageTest to test from real Bangladesh locations.

```
1. Visit: https://www.webpagetest.org/
2. Enter your game URL
3. Select location: "Mumbai, India - Chrome" (closest to Bangladesh)
4. Click "Start Test"
5. Analyze waterfall chart and performance metrics
```

---

### 🎯 Method 5: Real Device Testing

Test on actual devices in Bangladesh (most accurate).

#### Setup:
```bash
# On a device in Bangladesh:
# 1. Connect to local Bangladesh network
# 2. Open browser dev tools (F12)
# 3. Go to Network tab
# 4. Visit game URL
# 5. Record:
#    - Total load time
#    - Resource sizes
#    - Failed requests
```

---

## Current Test Method Explanation

### What We're Currently Doing:

Our test scripts measure performance from **your current location**, then estimate Bangladesh performance based on:

1. **Network Distance**
   - Measure latency to CDN (currently ~150ms)
   - Bangladesh to US CDN: typically 200-400ms
   - Add extra delay for estimation

2. **Bandwidth Simulation**
   - Use `curl --limit-rate` to simulate slow connections
   - Test at 100 KB/s, 500 KB/s, 1 Mbps
   - Common Bangladesh mobile speeds

3. **Resource Analysis**
   - Calculate total resource size
   - Estimate download time = Size / Bandwidth
   - Add overhead for latency and packet loss

### Formula Used:
```
Bangladesh Load Time = (Current Load Time) × (Bangladesh Latency / Current Latency) + (Resource Size / Bangladesh Bandwidth)

Example:
- Current: 2 seconds, 100ms latency
- Resource: 616 KB
- Bangladesh: 300ms latency, 500 KB/s bandwidth

Estimated Time = 2s × (300/100) + (616KB / 500KB/s)
                = 6s + 1.2s = 7.2s
```

---

## Recommended Approach

### For Most Accurate Results:
1. ✅ **Use Bangladesh VPN** (if available)
2. ✅ **Deploy test server in Mumbai** (closest AWS region)
3. ✅ **Use WebPageTest** (free, easy)
4. ✅ **Network simulation** (current method, estimates only)

### For Quick Testing:
```bash
# Test with current method (estimates)
cd /tmp/cdn/game-test/
./test_game_performance_en.sh ArcadeBingo en-US

# Test multiple games
./test_multiple_games.sh 5 en-US
```

---

## Understanding Bangladesh Network Conditions

### Typical Bangladesh Internet:

| Connection Type | Speed | Latency to US | Quality |
|----------------|-------|---------------|---------|
| Mobile 3G | 100-500 KB/s | 300-500ms | Poor |
| Mobile 4G | 1-5 Mbps | 200-400ms | Fair |
| Home Broadband | 2-10 Mbps | 150-300ms | Good |
| Fiber | 10+ Mbps | 100-200ms | Excellent |

### Common Issues:
- 🔴 High latency to US servers (200-400ms)
- 🔴 Packet loss during peak hours
- 🔴 Bandwidth throttling by ISPs
- 🔴 DNS resolution delays
- 🔴 Limited international bandwidth

---

## Testing Checklist

- [ ] Test from current location (baseline)
- [ ] Test with bandwidth limits (100KB/s, 500KB/s, 1Mbps)
- [ ] Test with added latency (300ms)
- [ ] Test multiple games
- [ ] Test during different times of day
- [ ] Use VPN/proxy if available
- [ ] Test on mobile devices
- [ ] Check CDN geographic routing

---

## Next Steps After Testing

### If Performance is Poor:

1. **Deploy Asian CDN Nodes**
   - Singapore (closest)
   - Mumbai, India
   - Use Cloudflare or Akamai Asia regions

2. **Optimize Resources**
   - Compress images further
   - Split large JavaScript files
   - Enable browser caching
   - Use lazy loading

3. **Add Performance Monitoring**
   - Track real user metrics from Bangladesh
   - Set up alerts for slow load times
   - Monitor CDN hit rates

4. **Implement Fallbacks**
   - Progressive loading
   - Offline mode
   - Low-bandwidth version

---

## Contact

For questions or issues:
- Review test logs in `/tmp/cdn/game-test/`
- Check detailed report: `FINAL_TEST_REPORT.md`
- Run tests with `-v` flag for verbose output
