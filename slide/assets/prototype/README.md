# InspectFlow 簡報用 Prototype 實際截圖

更新日期：2026 年 10 月 14 日

本資料夾只存放目前手機端與後台端 Prototype 實際執行後擷取的畫面。簡報製作時不得改用 `slide/assets/` 內的舊版生成式概念 UI 圖。

## 手機端

手機端以目前 Flutter Web Build 執行，直向畫面使用 390 × 844，橫向掃描使用 844 × 390。Web 是本專案既有的主要開發與截圖環境，畫面內容與目前還車主線一致。

| 檔案 | 畫面內容 | 建議用途 |
| --- | --- | --- |
| `mobile-entry-390x844.png` | 掃描入口、車號資訊與六區俯視圖 | 第 5 張手機端產品設計 |
| `mobile-front-guidance-844x390.png` | 車頭偏移校正與方向箭頭 | 第 5、6 張掃描引導 |
| `mobile-damage-detected-844x390.png` | 左側廣角掃描與刮痕框選 | 第 5、6 張異常發現 |
| `mobile-damage-closeup-844x390.png` | 向前靠近刮痕的移動引導 | 第 6 張異常補掃 |
| `mobile-interior-finding-844x390.png` | 後座污漬辨識 | 第 6 張車內整潔度 |
| `mobile-summary-390x844.png` | 六區摘要與待確認結果 | 第 5 張完成流程 |

## 後台端

後台端以目前 React、TypeScript 與 Vite Prototype 執行，畫面統一使用 1600 × 900。所有畫面均保留目前的單一營運視角與固定假資料。

| 檔案 | 畫面內容 | 建議用途 |
| --- | --- | --- |
| `backend-review-list-1600x900.png` | 四筆待審異常案件 | 第 7 張後台產品設計 |
| `backend-review-detail-1600x900.png` | 六區影像、前後比較、AI 建議與人工審核 | 第 8 張後台細部功能 |
| `backend-processing-list-1600x900.png` | 五筆處理中案件與索賠請求狀態 | 第 7 張後台產品設計 |
| `backend-processing-detail-1600x900.png` | 處理事件影像比較與車輛處理資訊 | 第 8 張後台細部功能 |
| `backend-vehicle-list-1600x900.png` | 八筆正常車輛、租用與整潔狀態 | 第 7 張後台產品設計 |
| `backend-vehicle-detail-1600x900.png` | 正常車輛的上次車況與車輛資訊 | 第 8 張後台細部功能 |

## 使用限制

- 截圖呈現 Prototype 固定資料與模擬流程，不代表正式 AI 模型或 iRent API 已完成。
- 簡報可以裁切畫面，但不得改寫畫面中的狀態、車號或判讀結果。
- 同一張投影片應優先放一張主要畫面，再以一至兩張局部畫面補充，避免把所有截圖縮小成難以閱讀的縮圖牆。
