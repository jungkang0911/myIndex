---
name: myindex
description: >
  幫同仁安裝 / 更新個人瀏覽器起始頁 MyIndex（單檔 HTML：分頁、書籤區塊、本地路徑連結、筆記、待辦、搜尋列，資料存瀏覽器 localStorage），
  可從 Edge/Chrome 書籤挑資料夾產生預設內容 config.js，並教學設成瀏覽器首頁。
  使用者說「裝起始頁」「安裝 MyIndex」「我也要那個首頁」「更新起始頁」「把書籤做成起始頁」「設成首頁」「起始頁加連結」「myindex」時使用。
---

# myindex

## 固定範本規則

- `assets/index.html` 是唯一頁面範本。安裝與更新必須用 `scripts/install.ps1` 原樣複製，不得重新生成 HTML、CSS 或替換成其他版型。
- 個人化只修改 `config.js` / 匯入 JSON；已儲存的資料使用頁面匯入與匯出。不要把使用者書籤、帳號或內部網址寫入範本。
- 除非使用者明確要求修改版型，否則不修改範本。缺少範本時取得完整專案，不憑文字描述重建。
- 安裝完成比較 `assets/index.html` 與目標 `index.html` 的 SHA-256，必須相同。更新保留原路徑與既有 `config.js`。

呼叫格式：`/myindex [安裝|更新|書籤|首頁|加連結 <網址…>]`

- 未指定動作 → 依序做：安裝 →（詢問是否要從書籤產生預設內容）→ 教學設成首頁
- `更新` → 只覆蓋 index.html，使用者自訂內容不受影響
- `書籤` → 從瀏覽器書籤產生預設內容
- `首頁` → 只給設定首頁的教學
- `加連結`（或參數直接給網址）→ 產生匯入用 JSON 片段（見步驟 4），不碰 localStorage

---

## 固定設定

| 項目 | 值 |
|------|-----|
| 範本 | 本 skill 資料夾 `assets/index.html` |
| 預設安裝位置 | `%USERPROFILE%\MyIndex\index.html`（使用者指定別處就照用） |
| 預設內容檔 | 同資料夾 `config.js`（`window.STARTPAGE_DEFAULT = {...};`），只在 localStorage 為空時生效 |
| 使用者資料 | 存在瀏覽器 localStorage（key `startpage.v1`），**不在檔案裡** |
| 腳本 | `scripts/install.ps1`、`scripts/bookmarks-to-config.ps1`（以下 `$SK` = 本 skill 資料夾的絕對路徑） |

腳本為 UTF-8 with BOM（Windows PowerShell 5.1 才不會讀成亂碼），修改時要保留 BOM。

---

## 執行步驟

### 1. 安裝 / 更新

```powershell
& "$SK\scripts\install.ps1"                          # 預設位置
& "$SK\scripts\install.ps1" -Target "D:\MyStart"     # 指定位置
```
- 最後一行輸出是 `file:///…/index.html` 網址，記下來給步驟 3 用。
- 舊的 index.html 會自動備份成 `index.html.bak`。
- **更新時要用同一個路徑**：不同路徑在部分瀏覽器會被當成不同來源，看起來像資料不見。
- 若使用者已在用舊版，提醒：自訂內容在瀏覽器裡，更新不會遺失；保險起見可先按右上角「⋯ → 匯出設定」備份。

### 2.（選用）從書籤產生預設內容

**隱私原則：只把資料夾名稱與連結數帶進對話，不讀、不列出書籤網址；行動裝置書籤不讀。**

1. 列出資料夾（只輸出路徑 + 數量）：
   ```powershell
   & "$SK\scripts\bookmarks-to-config.ps1" -List              # Edge
   & "$SK\scripts\bookmarks-to-config.ps1" -Browser Chrome -List
   ```
2. 把清單給使用者，**請他自己挑**要放上起始頁的資料夾（工作相關的）。不要自行判斷或建議私人資料夾。
3. 產生 JSON 並安裝成 config.js：
   ```powershell
   $json = "$env:USERPROFILE\MyIndex\startpage-default.json"
   & "$SK\scripts\bookmarks-to-config.ps1" -Folders '書籤列/工作','書籤列/DevOps' -Out $json
   & "$SK\scripts\install.ps1" -Config $json
   ```
   `-Folders` 用 `-List` 顯示的完整路徑；子資料夾會自動一起納入，各自成為一個區塊。
4. **若使用者已經開過起始頁**（localStorage 有資料），config.js 不會生效 → 請他在頁面「⋯ → 匯入設定」選 `startpage-default.json`，或「⋯ → 重設為預設內容」（會清掉現有自訂）。

失敗處理：
- `找不到書籤檔` → 瀏覽器可能用非 Default 設定檔，請使用者到 `edge://version` / `chrome://version` 看「設定檔路徑」，再用 `-Path "<設定檔路徑>\Bookmarks"`。
- `沒有符合 -Folders` → 名稱要與 `-List` 的路徑完全一致（含「書籤列/」前綴）。

### 3. 設成瀏覽器首頁（只能請使用者手動，不要改登錄檔/原則）

| 瀏覽器 | 設定位置 |
|------|------|
| Edge | `edge://settings/startHomeNTP` →「Edge 啟動時」選「開啟這些頁面」→ 新增頁面，貼上 file:/// 網址；同頁「在工具列上顯示首頁按鈕」也可填同網址 |
| Chrome | `chrome://settings/onStartup` →「開啟特定網頁或一組網頁」→ 新增；`chrome://settings/appearance` →「顯示首頁按鈕」填同網址 |

- 「新分頁」無法直接指定 file:// 網址（需擴充功能），這點先講清楚，避免使用者以為沒設好。
- 公司電腦若首頁被群組原則鎖住（設定旁有公事包圖示），就改成加到書籤列 / 釘選分頁使用。

### 4. 加連結到已在用的起始頁

使用者資料在 localStorage，不能直接寫 → 產生 **JSON 片段**讓使用者「⋯ → 匯入」，會併入現有分頁，不開新分頁、不覆蓋：

```json
{ "page": "首頁",
  "widgets": [{ "title": "負責的系統", "links": [
    { "name": "會員中心 PROD", "url": "https://…" },
    { "name": "會員中心 UAT",  "url": "https://…" } ]}]}
```
- 存到安裝資料夾（如 `add-links.json`，UTF-8 無 BOM）。連結名稱、區塊標題依使用者描述命名，不清楚再問。
- `page`：分頁名稱，可省略；找不到就併入目前分頁。
- 同名書籤區塊 → 連結加進去，重複網址自動略過；沒有同名區塊 → 新增區塊。
- **不要**用含 `pages` 的 JSON 加連結：那是完整設定檔，匯入會整份取代（頁面會先跳確認）。
- 匯入後要換位置：編輯模式拖到上方分頁標籤，或用 ⇄ / 連結 ✎ 的「所在區塊」。

---

## 輸出格式

完成後回報：

```markdown
## MyIndex 已安裝
- 位置：<index.html 路徑>
- 網址：<file:/// 網址>
- 預設內容：<無 / 已從 N 個書籤資料夾產生 config.js>

### 下一步
1. 用瀏覽器開啟上面的網址
2. <設首頁步驟，依使用者的瀏覽器>
3. 右上角「✎ 編輯」可自訂；「⋯」可匯出備份
```

---

## 頁面功能速查（使用者問怎麼用時回答）

- **編輯模式**：右上角「✎ 編輯」→ 按鈕變「✓ 完成」；按 Esc 或「✓ 完成編輯」結束
- **連結**：網址或本地路徑都可（`D:\資料夾`、`\\server\share\檔.xlsx`）；本地路徑有 ⧉ 可複製路徑
- **圖示**：編輯連結時「圖示」欄可填 emoji、圖片網址或本地圖檔；留空自動抓 favicon
- **排序**：編輯模式拖 `⋮⋮`，連結可跨區塊，區塊拖標題列；藍線為落點
- **移到其他分頁**：編輯模式把區塊標題列或連結**拖到上方分頁標籤**（虛線框）放開；或按區塊的 ⇄ 選分頁；或連結 ✎ 的「所在區塊（分頁 / 區塊）」下拉
- **分頁**：編輯模式下「＋ 分頁」新增、雙擊改名、✕ 刪除
- **備份 / 換電腦**：「⋯ → 匯出設定 (JSON)」，新電腦「⋯ → 匯入」（完整設定檔會取代全部，先跳確認）
- **匯入片段**：只含 `widgets` 的 JSON 或瀏覽器書籤 HTML → 併入目前（或 `page` 指定的）分頁，同名區塊合併、重複網址略過，不會開新分頁
- **派送給別人**：匯出的 JSON 用 `install.ps1 -Config <json>` 產生 config.js，連同 index.html 給對方

---

## 注意事項

- 本 skill 只會寫入安裝資料夾（index.html、config.js、.bak、預設內容 JSON），不改瀏覽器設定、登錄檔或書籤。
- 不要直接讀寫瀏覽器 localStorage 檔案；使用者資料一律透過頁面的匯入/匯出處理。
- Canonical template: `assets/index.html`. Keep the repository self-contained; no Hub access is required.

---
