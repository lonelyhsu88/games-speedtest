# 文檔索引

## 📖 從這裡開始

### 🎯 我想要...

| 目的 | 文檔 | 說明 |
|------|------|------|
| **快速使用修復版** | [QUICK_START.md](QUICK_START.md) | 5 分鐘快速上手 ⭐⭐⭐ |
| **了解問題和解決方案** | [ANSWER_YOUR_QUESTION.md](ANSWER_YOUR_QUESTION.md) | 直接回答您的問題 ⭐⭐⭐ |
| **查看總覽** | [README_REVIEW.md](README_REVIEW.md) | Code Review 總結 ⭐⭐⭐ |
| **從舊版遷移** | [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | 遷移步驟指南 ⭐⭐ |
| **了解技術細節** | [CODE_REVIEW_FINDINGS.md](CODE_REVIEW_FINDINGS.md) | 12 個發現的詳細分析 ⭐⭐ |
| **對比舊版和新版** | [COMPARISON.md](COMPARISON.md) | 逐項程式碼對比 ⭐ |
| **第一次改進記錄** | [IMPROVEMENTS.md](IMPROVEMENTS.md) | 初期改進說明 ⭐ |

---

## 🚀 推薦閱讀順序

### 初次使用者（5-10 分鐘）
1. **ANSWER_YOUR_QUESTION.md** - 了解問題
2. **QUICK_START.md** - 立即開始使用
3. 執行測試驗證

### 深入了解（20-30 分鐘）
1. **README_REVIEW.md** - 查看總覽
2. **CODE_REVIEW_FINDINGS.md** - 理解技術原因
3. **COMPARISON.md** - 查看程式碼差異

### 技術人員（1 小時）
1. 閱讀所有文檔
2. 檢查程式碼修改
3. 執行對比測試

---

## 📂 檔案結構

### 核心測速程式

```
puppeteer_game_test.js               # ❌ 舊版（不準確）
puppeteer_game_test.js         # ✅ 修復版（準確）⭐
puppeteer_game_test_interactive.js   # 互動式測試版
```

### Shell 腳本

```
test_games_menu.sh                   # ❌ 舊版選單
test_games_menu.sh             # ✅ 修復版選單 ⭐
test_games_with_puppeteer.sh         # ❌ 舊版批次測試
test_games_with_puppeteer.sh   # ✅ 修復版批次測試 ⭐
```

### 文檔

```
INDEX.md                             # 📖 本文件（導覽）
ANSWER_YOUR_QUESTION.md              # 🎯 直接回答問題 ⭐⭐⭐
QUICK_START.md                       # 🚀 快速開始 ⭐⭐⭐
README_REVIEW.md                     # 📋 總覽摘要 ⭐⭐⭐
MIGRATION_GUIDE.md                   # 🔄 遷移指南 ⭐⭐
CODE_REVIEW_FINDINGS.md              # 🔍 詳細分析 ⭐⭐
COMPARISON.md                        # ⚖️ 程式碼對比 ⭐
IMPROVEMENTS.md                      # 📝 改進記錄 ⭐
```

---

## 🎯 快速參考

### 立即使用修復版

```bash
# 互動式選單（最簡單）
./test_games_menu.sh

# 直接指定遊戲
./test_games_with_puppeteer.sh --games "StandAloneLimboCL" en-US 15000

# 單一遊戲 URL
node puppeteer_game_test.js "https://game-url" --output=report.json
```

### 驗證結果

```bash
# 1. 使用修復版測試
./test_games_menu.sh

# 2. 同時用瀏覽器 DevTools 測試
# 3. 比較 requests 和 size（應該相差 < 5%）
```

### 查看結果

```bash
# 查看測試結果
cat results/puppeteer_game_test_*/results.txt

# 查看詳細 JSON
cat results/puppeteer_game_test_*/*.json | jq '.'
```

---

## 🔑 關鍵差異

### 舊版 ❌

```javascript
// 使用 content-length header（常常為 0）
size: parseInt(headers['content-length'] || 0)
```

**結果**：2.68 MB, 133 requests（少計算 ~80%）

### 修復版 ✅

```javascript
// 使用 CDP 取得實際 body
const responseBody = await client.send('Network.getResponseBody', {
    requestId: event.requestId
});
let actualSize = Buffer.byteLength(responseBody.body);
```

**結果**：12.9 MB, 209 requests（準確）

---

## 📊 問題嚴重度

| 問題 | 嚴重度 | 影響 | 狀態 |
|------|--------|------|------|
| 資源大小計算錯誤 | 🔴 P0 | 少計算 70-80% | ✅ 已修復 |
| requestCount 追蹤 bug | 🟡 P1 | 遺漏延遲資源 | ✅ 已修復 |
| 錯誤處理不足 | 🟡 P1 | 無法追蹤問題 | ✅ 已修復 |
| Click 檢測不完整 | 🟢 P2 | 可能點錯 | ✅ 已改進 |
| Canvas 點擊錯誤 | 🟢 P2 | 遊戲可能不啟動 | ✅ 已修復 |

---

## 🎓 學習資源

### 理解 Chrome DevTools Protocol

- [Chrome DevTools Protocol 文檔](https://chromedevtools.github.io/devtools-protocol/)
- [Puppeteer CDP 使用](https://pptr.dev/guides/cdp-sessions)

### 為什麼 content-length 不可靠

1. **HTTP/2 特性**：使用 chunked transfer encoding
2. **壓縮**：gzip/brotli 壓縮後沒有原始大小
3. **動態內容**：伺服器可能不知道最終大小

### Chrome DevTools 如何計算

Chrome DevTools 本身也使用 CDP 的 `Network.getResponseBody`，所以修復版與 DevTools 結果一致。

---

## ✅ 檢查清單

### 使用前
- [ ] 閱讀 ANSWER_YOUR_QUESTION.md
- [ ] 閱讀 QUICK_START.md
- [ ] 確認 Node.js 和 Puppeteer 已安裝
- [ ] 確認有足夠磁碟空間

### 第一次測試
- [ ] 執行 `./test_games_menu.sh`
- [ ] 選擇 1-2 個遊戲
- [ ] 同時用瀏覽器 DevTools 驗證
- [ ] 確認結果相差 < 5%

### 正式使用
- [ ] 使用修復版重新測試重要遊戲
- [ ] 建立新的效能基準
- [ ] 更新團隊文檔
- [ ] 停止使用舊版

---

## 🆘 疑難排解

### 常見問題

1. **測試太慢？**
   - 減少等待時間（10 秒）
   - 一次只測試 1-3 個遊戲

2. **記憶體不足？**
   - 不要選擇 "all"
   - 分批測試

3. **結果不準確？**
   - 確認使用的是 `_fixed` 版本
   - 檢查 /tmp/puppeteer_output.txt

4. **找不到遊戲？**
   - 檢查 API 連線
   - 確認 IP 已加白名單

### 獲取協助

```bash
# 檢查版本
head -n 5 test_games_menu.sh

# 查看錯誤日誌
cat /tmp/puppeteer_output.txt

# 驗證檔案存在
ls -lh *_fixed.*
```

---

## 📈 建議的工作流程

### 日常測試

```bash
1. ./test_games_menu.sh
2. 選擇 3-5 個代表性遊戲
3. 使用標準設定（15 秒等待）
4. 記錄並比較結果
```

### 效能監控

```bash
1. 每週測試相同的遊戲集
2. 記錄 size、requests、time
3. 與基準比較（允許 ±10% 波動）
4. 異常時深入調查
```

### 問題排查

```bash
1. 發現效能異常
2. 使用 --headless=false 觀察
3. 檢查 JSON 報告的 failedRequests
4. 對比 byType 分析哪類資源變多
```

---

## 🎉 開始吧！

```bash
# 最簡單的開始方式
./test_games_menu.sh
```

**祝測試順利！** 🚀
