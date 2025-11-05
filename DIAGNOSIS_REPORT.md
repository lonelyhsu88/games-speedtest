# 測試不準確問題診斷報告

## 問題總結

測試腳本存在**硬編碼閾值**問題，導致對不同類型遊戲的測試結果不準確：

### 1. 主要問題：最小資源數量限制（P0 - 嚴重）

**代碼位置：** `puppeteer_game_test.js:429`

```javascript
if (elapsed >= 15000 && idleTime >= idleThreshold && responses.length > 20) {
    // 認為加載完成
}
```

**影響：**
- 資源少於 20 個的遊戲會一直等待直到超時（60秒）
- 加載時間被嚴重高估

**測試案例：**
```
遊戲A（15個資源，實際5秒加載完成）
- 當前測試結果：60 秒 ❌
- 實際加載時間：5 秒 ✅
- 誤差：1100% 偏高
```

### 2. 次要問題：點擊成功判斷閾值（P1）

**代碼位置：** `puppeteer_game_test.js:282, 321`

```javascript
if (newResourceCount > 5) {
    clickSuccessful = true;
}
```

**影響：**
- 點擊後只加載少量資源的遊戲會被誤判為點擊失敗
- 浪費時間嘗試其他點擊策略

### 3. 次要問題：最小加載時間限制（P2）

**代碼位置：** `puppeteer_game_test.js:429`

```javascript
if (elapsed >= 15000 && ...) {
    // 必須等待至少 15 秒
}
```

**影響：**
- 快速加載的遊戲（<10秒）時間被高估

---

## 修復建議

### 方案 A：動態閾值（推薦）

根據遊戲實際情況動態調整閾值：

```javascript
// 點擊成功判斷：根據已加載資源數動態調整
const clickSuccessThreshold = Math.max(3, Math.floor(beforeClickRequests * 0.1));
if (newResourceCount > clickSuccessThreshold) {
    clickSuccessful = true;
}

// 加載完成判斷：移除固定資源數限制
const minResourceCount = 5;  // 最低 5 個資源即可
if (elapsed >= 10000 && idleTime >= idleThreshold && responses.length > minResourceCount) {
    // 認為加載完成
}
```

### 方案 B：可配置閾值

通過命令行參數允許用戶自定義閾值：

```bash
node puppeteer_game_test.js "https://..." \
    --min-resources=10 \
    --min-time=8000 \
    --click-threshold=3
```

### 方案 C：智能檢測

分析資源加載模式，自動判斷：

```javascript
// 檢測資源加載速率變化
const loadingRateHistory = [];
if (loadingRateHistory.length >= 3 && isLoadingStable(loadingRateHistory)) {
    // 加載速率穩定，認為完成
}
```

---

## 建議修復優先級

1. **P0 - 立即修復：** 移除 `responses.length > 20` 的硬限制
2. **P1 - 短期修復：** 降低點擊成功閾值到 2-3 個資源
3. **P2 - 中期優化：** 減少最小加載時間到 8-10 秒
4. **P3 - 長期改進：** 實現動態閾值或智能檢測

---

## 快速修復代碼

### 修復 1: 降低資源數量閾值

```javascript
// 修改第 429 行
// 舊代碼：
if (elapsed >= 15000 && idleTime >= idleThreshold && responses.length > 20) {

// 新代碼：
if (elapsed >= 10000 && idleTime >= idleThreshold && responses.length > 5) {
```

### 修復 2: 降低點擊成功閾值

```javascript
// 修改第 282, 321 行
// 舊代碼：
if (newResourceCount > 5) {

// 新代碼：
if (newResourceCount > 2) {
```

---

## 測試驗證

修復後需要測試以下遊戲類型：

- [x] 小型遊戲（10-15 個資源）
- [x] 中型遊戲（20-50 個資源）
- [x] 大型遊戲（100+ 個資源）
- [x] 快速加載遊戲（<5 秒）
- [x] 慢速加載遊戲（>30 秒）

預期結果：所有類型的遊戲都能準確測量加載時間，誤差 <10%
