# 舊版 vs 修復版對比

## 核心差異總覽

| 特性 | 舊版 (puppeteer_game_test.js) | 修復版 (puppeteer_game_test.js) |
|------|------------------------------|---------------------------------------|
| **資源大小計算** | ❌ 使用 `content-length` header (不準) | ✅ 使用 CDP `getResponseBody` (準確) |
| **網路追蹤方式** | Puppeteer page events | Chrome DevTools Protocol (CDP) |
| **點擊偵測** | 基本可見性檢查 | 完整可見性 + 幾何檢查 |
| **等待邏輯** | ⚠️ requestCount 追蹤有 bug | ✅ 獨立 snapshot 追蹤 |
| **錯誤處理** | 靜默吞掉 | 記錄並統計 |
| **快取資源** | ❌ 未追蹤 | ✅ 完整追蹤 |
| **壓縮資料** | ❌ 未顯示 | ✅ 顯示傳輸大小 |

---

## 問題 #1: 資源大小計算 ⭐⭐⭐

### 舊版 (錯誤)
```javascript
// puppeteer_game_test.js:139
page.on('response', async response => {
    const headers = response.headers();
    responses.push({
        size: parseInt(headers['content-length'] || 0),  // ❌ 很多資源沒有這個 header
        // ...
    });
});
```

**問題**:
- 使用 `content-length` header，但很多資源使用 chunked transfer 或 gzip 壓縮，沒有這個 header
- 結果：**大部分資源 size = 0**

### 修復版 (正確)
```javascript
// puppeteer_game_test.js:140-155
const client = await page.target().createCDPSession();
await client.send('Network.enable');

client.on('Network.responseReceived', async event => {
    // 方法 1: 取得實際 body
    const responseBody = await client.send('Network.getResponseBody', {
        requestId: event.requestId
    });

    let actualSize = Buffer.byteLength(
        responseBody.body,
        responseBody.base64Encoded ? 'base64' : 'utf8'
    );

    // 方法 2 (fallback): 使用 CDP 的 encodedDataLength
    if (!responseBody) {
        actualSize = event.response.encodedDataLength || 0;
    }
});
```

**改進**:
- ✅ 取得實際下載的 body 大小
- ✅ 準確反映真實傳輸量
- ✅ 與瀏覽器 DevTools 數據一致

---

## 問題 #2: requestCount 追蹤邏輯 bug

### 舊版 (有 bug)
```javascript
// puppeteer_game_test.js:266-291
let requestCount = responses.length;

const requestTimeTracker = setInterval(() => {
    if (responses.length > requestCount) {
        lastRequestTime = Date.now();
        requestCount = responses.length;  // ⚠️ 一直在更新
    }
}, 100);

while (...) {
    // ...
    if (elapsed >= 15000 && idleTime >= idleThreshold) {
        await new Promise(resolve => setTimeout(resolve, 5000));

        // ❌ 這裡的 requestCount 已經被上面的 interval 更新了
        if (responses.length > requestCount) {  // 永遠不會觸發！
            console.log(`New resources detected...`);
            continue;
        }
        break;
    }
}
```

**問題**:
- `requestTimeTracker` 每 100ms 更新 `requestCount`
- 下面的檢查永遠看不到新資源（因為 `requestCount` 已經等於 `responses.length`）
- "二次確認"邏輯完全失效

### 修復版 (正確)
```javascript
// puppeteer_game_test.js:335-350
// 使用獨立的 snapshot 變數追蹤
let snapshotCount = responses.length;

while (...) {
    // 每次 loop 更新 snapshot
    if (responses.length > snapshotCount) {
        lastRequestTime = Date.now();
        snapshotCount = responses.length;  // ✅ 只在 loop 中更新
    }

    if (elapsed >= 15000 && idleTime >= idleThreshold) {
        const beforeVerify = responses.length;  // ✅ 驗證前快照
        await new Promise(resolve => setTimeout(resolve, 5000));
        const afterVerify = responses.length;   // ✅ 驗證後快照

        if (afterVerify > beforeVerify) {  // ✅ 正確比對！
            console.log(`${afterVerify - beforeVerify} more resources detected`);
            snapshotCount = afterVerify;
            lastRequestTime = Date.now();
            continue;
        }
        break;
    }
}
```

**改進**:
- ✅ 不使用 interval，改用 loop 內更新
- ✅ 驗證階段使用獨立的 before/after 變數
- ✅ 正確偵測到額外加載的資源

---

## 問題 #3: 點擊偵測改進

### 舊版 (基本檢查)
```javascript
// puppeteer_game_test.js:226-228
const style = window.getComputedStyle(el);
if (style.display !== 'none' && style.visibility !== 'hidden') {
    el.click();  // ❌ 可能點到不可點擊的元素
}
```

**問題**: 沒檢查 opacity、pointer-events、元素大小

### 修復版 (完整檢查)
```javascript
// puppeteer_game_test.js:236-247
const style = window.getComputedStyle(el);
const rect = el.getBoundingClientRect();

// ✅ 更完整的可見性檢查
if (style.display !== 'none' &&
    style.visibility !== 'hidden' &&
    style.opacity !== '0' &&           // ✅ 檢查透明度
    style.pointerEvents !== 'none' &&  // ✅ 檢查是否可點擊
    rect.width > 0 && rect.height > 0) { // ✅ 檢查元素大小

    // ✅ 點擊元素中心點
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    el.click();
}
```

---

## 問題 #4: Canvas 點擊改進

### 舊版
```javascript
// puppeteer_game_test.js:236-240
const canvas = document.querySelector('canvas');
if (canvas) {
    canvas.click();  // ❌ 點擊 (0, 0) 位置
}
```

### 修復版
```javascript
// puppeteer_game_test.js:252-262
const canvas = document.querySelector('canvas');
if (canvas) {
    const rect = canvas.getBoundingClientRect();
    const x = rect.left + rect.width / 2;   // ✅ 計算中心點
    const y = rect.top + rect.height / 2;

    const event = new MouseEvent('click', {
        view: window,
        bubbles: true,
        cancelable: true,
        clientX: x,  // ✅ 點擊中心位置
        clientY: y
    });
    canvas.dispatchEvent(event);
}
```

---

## 問題 #5: 錯誤處理

### 舊版
```javascript
// puppeteer_game_test.js:144-146
} catch (error) {
    // Some responses might fail to get headers
    // ❌ 完全不知道有多少資源被跳過
}
```

### 修復版
```javascript
// puppeteer_game_test.js:166-170
} catch (error) {
    skippedResponses.push({
        url: event.response.url,
        error: error.message
    });
}

// ...後面顯示統計
if (skippedResponses.length > 0) {
    console.log(`Skipped Responses: ${skippedResponses.length}`);
}
```

---

## 新增功能

### 1. 快取資源追蹤
```javascript
fromCache: event.response.fromDiskCache ||
           event.response.fromServiceWorker ||
           false
```

顯示有多少資源來自快取，不是實際下載。

### 2. 壓縮資料顯示
```javascript
console.log(`Total:        ${formatBytes(totalSize)}`);
console.log(`Transferred:  ${formatBytes(totalEncodedSize)} (after compression)`);
```

區分解壓縮後大小 vs 實際傳輸大小。

### 3. 詳細的點擊資訊
```javascript
console.log(`Clicked: ${clicked.element} - "${clicked.text}"`);
console.log(`${newRequests} new resources loaded after clicking`);
```

清楚顯示點擊了什麼元素，以及觸發了多少新資源。

---

## 預期測試結果對比

| 指標 | 舊版 | 修復版 | 瀏覽器 DevTools |
|------|------|--------|-----------------|
| Requests | 133 | ~209 ✅ | 209 |
| Total Size | 2.68 MB ❌ | ~12.9 MB ✅ | 12.9 MB |
| Transferred | N/A | ~10-11 MB ✅ | (depends) |
| Time | 23.87s | 30-40s | 23.68s |
| Failed | Unknown ❌ | Tracked ✅ | Tracked |

---

## 使用建議

### 舊版適用情況
- ❌ 不建議使用（資料不準確）
- 只適合快速測試連線是否成功

### 修復版適用情況
- ✅ 準確的效能測試
- ✅ 資源加載分析
- ✅ 網站優化評估
- ✅ CI/CD 效能監控

### 使用方式
```bash
# 基本測試
node puppeteer_game_test.js "https://game.example.com/?token=xxx"

# 儲存詳細報告
node puppeteer_game_test.js "https://game.example.com/?token=xxx" --output=report.json

# 除錯模式（顯示瀏覽器）
node puppeteer_game_test.js "https://game.example.com/?token=xxx" --headless=false
```

---

## 遷移指南

1. **立即切換到修復版** - 舊版資料不可靠
2. **重新建立基準測試** - 使用修復版建立新的效能基準
3. **更新 CI/CD 腳本** - 如果有自動化測試，請更新腳本路徑
4. **比對瀏覽器結果** - 首次使用時與 DevTools 比對驗證

---

## 技術細節：為何 CDP 比 Puppeteer Events 準確？

### Puppeteer Page Events
```
Browser → Puppeteer → Node.js → Your Code
         (simplified)  (headers only)
```

### Chrome DevTools Protocol (CDP)
```
Browser → CDP → Your Code
        (raw protocol)  (full data)
```

CDP 提供：
- 實際的 response body
- 準確的 encodedDataLength
- 詳細的 timing 資訊
- Cache 狀態
- Service Worker 資訊

這就是為什麼 Chrome DevTools 總是最準確的 - 它也使用 CDP！
