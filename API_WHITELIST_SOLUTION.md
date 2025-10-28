# API 白名單問題解決方案

## 🔴 問題說明

**情況：**
- API 有 IP 白名單限制
- 只有特定 IP 可以調用 API 獲取遊戲 URL
- 如果連接 VPN 到孟加拉，IP 會改變
- 白名單會阻擋來自孟加拉 IP 的 API 請求

**結果：**
```
你的白名單 IP → ✅ 可以調用 API
孟加拉 VPN IP → ❌ 被 API 阻擋
```

---

## ✅ 解決方案：兩步驟測試法

### 方案概述

**第 1 步：不使用 VPN**
- 用你的白名單 IP 調用 API
- 獲取遊戲 URL 和 Token

**第 2 步：連接 VPN**
- 連接到孟加拉 VPN
- 用獲取的 URL 直接測試遊戲加載

**關鍵：** 遊戲 URL 不需要白名單！只有 API 調用需要。

---

## 🚀 使用方法

### 方法 1：自動化腳本（推薦）

```bash
cd /tmp/cdn/game-test/
./test_with_vpn_workaround.sh ArcadeBingo en-US
```

**腳本流程：**
1. ✅ 自動檢測你的當前 IP（白名單 IP）
2. ✅ 調用 API 獲取遊戲 URL
3. ⏸️  暫停，提示你連接 VPN
4. ✅ 等待你按 Enter 繼續
5. ✅ 驗證 VPN 連接（檢查 IP 是否改變）
6. ✅ 使用孟加拉 IP 測試遊戲加載
7. ✅ 顯示真實的孟加拉性能數據

---

### 方法 2：手動步驟

#### 步驟 1：獲取遊戲 URL（不使用 VPN）

```bash
cd /tmp/cdn/game-test/

# 確認你的 IP（應該是白名單 IP）
./show_client_ip.sh

# 獲取遊戲 URL
./test_real_page_load.sh ArcadeBingo en-US

# 複製顯示的遊戲 URL
# 例如：https://jump.shuangzi6666.com/Bingo/ArcadeBingo/?Lang=en-US&ProductId=ELS&Token=xxx...
```

#### 步驟 2：連接 VPN 到孟加拉

1. 啟動你的 VPN client
2. 選擇孟加拉伺服器
3. 確認連接成功

#### 步驟 3：驗證 VPN 連接

```bash
# 確認 IP 已改變
./show_client_ip.sh

# 你應該看到孟加拉 IP
```

#### 步驟 4：測試遊戲（使用之前獲取的 URL）

```bash
# 直接測試遊戲 URL（不需要再調用 API）
GAME_URL="貼上你之前複製的遊戲 URL"

# 測試頁面加載
curl -o /dev/null -s -w "Time: %{time_total}s\nSize: %{size_download} bytes\n" "$GAME_URL"
```

---

## 📊 完整測試範例

### 使用自動化腳本：

```bash
cd /tmp/cdn/game-test/

# 運行自動化腳本
./test_with_vpn_workaround.sh ArcadeBingo en-US
```

**輸出示例：**
```
[Step 1] Checking your current IP (should be whitelisted)...
  Your current IP: 61.218.59.85

[Step 2] Getting game URL from API (using whitelisted IP)...
✓ Game URL obtained successfully!

Game URL: https://jump.shuangzi6666.com/...

════════════════════════════════════════════════════════
          NOW CONNECT YOUR VPN TO BANGLADESH            
════════════════════════════════════════════════════════

Please:
  1. Connect your VPN to Bangladesh server
  2. Press Enter when ready to continue testing...

（你連接 VPN 後按 Enter）

[Step 3] Verifying VPN connection...
  New IP: 103.xxx.xxx.xxx
  Country: Bangladesh

✓✓✓ Connected to Bangladesh! ✓✓✓

[Step 4] Testing game loading from Bangladesh IP...

Loading HTML page...
  ✓ HTML: 7333 bytes in 0.245s
Loading CSS files...
  ✓ style-mobile.css: 2565 bytes (0.312s)
Loading JavaScript files...
  ✓ settings.js: 318 bytes (0.198s)
  ✓ main.js: 10251 bytes (0.234s)
  Loading large file: cocos2d-js-min.js
  ✓ cocos2d-js-min.js: 1992 KB (8.234s)

════════════════════════════════════════════════════════
        REAL BANGLADESH PERFORMANCE RESULTS             
════════════════════════════════════════════════════════

Testing Details:
  Original IP (API call):   61.218.59.85
  Testing IP (VPN):         103.xxx.xxx.xxx
  Testing Location:         Bangladesh

Loading Results:
  Total Size:        2005 KB
  Total Time:        9.223s

Performance Rating: Fair (Noticeable delay)

✓ This is REAL Bangladesh performance data!
```

---

## 🔑 關鍵要點

### ✅ 為什麼這個方案有效？

1. **API 調用**
   - 只在第 1 步需要
   - 使用你的白名單 IP
   - 獲取 Token 和 URL

2. **遊戲加載**
   - 不需要白名單
   - Token 在 URL 中
   - 可以從任何 IP 訪問

3. **分離測試**
   - API 調用 = 白名單 IP
   - 遊戲測試 = 孟加拉 IP
   - 兩者互不干擾

---

## 🎯 測試多款遊戲

### 批量測試腳本

```bash
#!/bin/bash
# 測試多款遊戲的腳本

GAMES=("ArcadeBingo" "StandAloneDice" "BonusBingo" "MultiPlayerCrash")

echo "Step 1: Getting all game URLs (without VPN)..."
for game in "${GAMES[@]}"; do
    echo "Getting URL for $game..."
    ./test_with_vpn_workaround.sh "$game" en-US
    sleep 2
done

echo ""
echo "Now connect your VPN to Bangladesh and press Enter..."
read

echo "Step 2: Testing all games (with VPN)..."
# 繼續測試...
```

---

## 💡 進階技巧

### 1. 保存遊戲 URL 以便重複使用

```bash
# 獲取並保存 URL
GAME_URL=$(./get_game_url.sh ArcadeBingo en-US)
echo "$GAME_URL" > arcadebingo_url.txt

# 之後可以重複使用
# 連接 VPN 後：
SAVED_URL=$(cat arcadebingo_url.txt)
curl -o /dev/null -s -w "Time: %{time_total}s\n" "$SAVED_URL"
```

### 2. 比較不同 IP 的性能

```bash
# 測試 1: 從白名單 IP
echo "Test from whitelisted IP:"
./test_real_page_load.sh ArcadeBingo en-US

# 連接 VPN

# 測試 2: 從孟加拉 IP
echo "Test from Bangladesh IP:"
# 使用相同的 URL 再次測試
```

### 3. 自動化完整流程

創建一個腳本，自動：
1. 檢查是否連接 VPN
2. 如果沒有，調用 API
3. 如果有，直接測試遊戲

---

## ⚠️ 注意事項

### Token 有效期

**問題：** Token 可能有有效期限制

**解決：**
- 測試前獲取新的 URL
- 不要保存太久的 URL
- 如果測試失敗，重新獲取 URL

### VPN 穩定性

**問題：** VPN 可能斷線

**解決：**
- 測試前確認 VPN 連接穩定
- 如果中途斷線，重新連接後繼續

### IP 驗證

**問題：** 不確定是否真的連到孟加拉

**解決：**
```bash
# 隨時檢查當前 IP
./show_client_ip.sh

# 應該看到：
# Country: Bangladesh (BD)
```

---

## 📝 測試檢查清單

使用此方案測試時：

- [ ] 第 1 步：確認當前 IP 是白名單 IP
- [ ] 第 2 步：成功調用 API 獲取遊戲 URL
- [ ] 第 3 步：保存或記錄遊戲 URL
- [ ] 第 4 步：連接 VPN 到孟加拉
- [ ] 第 5 步：確認 IP 已改變到孟加拉
- [ ] 第 6 步：使用保存的 URL 測試遊戲
- [ ] 第 7 步：記錄真實的性能數據
- [ ] 第 8 步：斷開 VPN（如果需要）

---

## 🎉 總結

這個兩步驟方案完美解決了 API 白名單問題：

✅ **第 1 步（白名單 IP）：** 調用 API 獲取 URL
✅ **第 2 步（孟加拉 IP）：** 測試遊戲加載

你將獲得：
- ✅ 真實的孟加拉 IP
- ✅ 真實的孟加拉網絡性能
- ✅ 準確的加載時間數據
- ✅ 不受 API 白名單限制

開始測試！ 🚀
