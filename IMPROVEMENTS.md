# 測速程式改進說明

## 問題分析

您發現的測速差異：

| 指標 | 舊版程式測試 | 瀏覽器測試 | 差異 |
|------|-------------|------------|------|
| 時間 | 23.87s | 23.68s | 相近 |
| 大小 | 2.68 MB | 12.9 MB | **少了 10.2 MB** |
| 請求數 | 133 requests | 209 requests | **少了 76 個請求** |

## 根本原因

遊戲資源是**分階段加載**的：

1. **第一階段** (初始加載): HTML, CSS, 基礎 JavaScript, 遊戲引擎
2. **第二階段** (點擊 "CLICK TO PLAY" 後): 遊戲場景、音效、音樂、額外動畫
3. **第三階段** (遊戲進行中): 懶加載資源、關卡資源、特效

**舊版程式的問題：**
- 點擊按鈕後只等待 2 秒就繼續
- 網路閒置判定太短 (2 秒)，第二波資源還沒來得及加載
- 最小等待時間只有 30 秒，對大型遊戲不夠

## 改進內容

### 1. 延長點擊後等待時間 (puppeteer_game_test.js:251)

```javascript
// 舊版：點擊後立即繼續
el.click();
return true;

// 新版：點擊後等待 5 秒，讓第二波資源開始加載
el.click();
// ... (等待 5 秒)
console.log(`${newRequests} new resources loaded after clicking start`);
```

### 2. 更智能的網路閒置檢測 (puppeteer_game_test.js:262-293)

**改進點：**
- ✅ 閒置門檻從 2 秒提升到 **5 秒**
- ✅ 最大等待時間從 30 秒提升到 **60 秒**
- ✅ 強制至少等待 **15 秒** 才能結束
- ✅ 閒置後額外等待 **5 秒** 確認沒有新資源
- ✅ 如果額外等待期間發現新資源，自動繼續監控

```javascript
// 舊版
const idleThreshold = 2000; // 2 秒
const maxWaitTime = 30000;  // 30 秒
if (idleTime >= idleThreshold && responses.length > 20) {
    break; // 直接停止
}

// 新版
const idleThreshold = 5000; // 5 秒
const maxWaitTime = 60000;  // 60 秒
if (elapsed >= 15000 && idleTime >= idleThreshold && responses.length > 20) {
    // 額外等待 5 秒確認
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 如果又有新資源，繼續監控
    if (responses.length > requestCount) {
        continue;
    }
    break;
}
```

## 使用方式

### 測試短時間遊戲 (預設)
```bash
node puppeteer_game_test.js "https://game.example.com/?token=xxx"
```

### 測試需要更長時間的遊戲
```bash
node puppeteer_game_test.js "https://game.example.com/?token=xxx" --wait=15000
```

### 儲存詳細報告
```bash
node puppeteer_game_test.js "https://game.example.com/?token=xxx" --output=report.json
```

### 顯示瀏覽器視窗 (除錯用)
```bash
node puppeteer_game_test.js "https://game.example.com/?token=xxx" --headless=false
```

## 預期改進效果

修改後，程式測試結果應該會更接近瀏覽器：

| 指標 | 改進前 | 改進後 (預期) | 瀏覽器 |
|------|--------|---------------|--------|
| 請求數 | 133 | ~200-210 | 209 |
| 大小 | 2.68 MB | ~12-13 MB | 12.9 MB |
| 時間 | 23.87s | 30-40s* | 23.68s |

*註：程式測試時間會稍長，因為增加了額外的等待和確認機制

## 驗證方式

建議對比測試：
1. 使用改進後的程式測試相同遊戲
2. 同時用瀏覽器開發者工具測試
3. 比較 requests 數量和 total size 是否接近 (±5%)

## 替代方案：互動式測試

如果需要更真實的測試 (模擬玩家行為)，可使用：

```bash
node puppeteer_game_test_interactive.js "https://game.example.com/?token=xxx" --playtime=180000
```

這會模擬 3 分鐘的遊戲過程，包含隨機點擊等互動。
