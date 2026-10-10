# InspectFlow Backend Prototype

iRent InspectFlow 的桌面營運後台展示原型。介面採單一營運視角，不提供客服、派工、索賠與管理者角色切換，讓展示聚焦在三個核心決策：看車況差異、分配清潔／維修任務，以及確認是否進入索賠。

## 環境與執行

- Node.js 22.23.2
- npm 10.9.8
- React 19、TypeScript 5.9、Vite 8、Zustand 5

```powershell
cd D:\github\irent-inspectflow\prototype\backend
npm install
npm run dev
```

預設開發網址為 `http://localhost:4173`。

## 展示頁面

1. **車況比對**：以車輛清單進入同車、同區域的取車前／還車後比較，並顯示多角度證據、異常位置與建議處理。
2. **任務分配**：只顯示清潔與維修任務。營運人員可查看異常影像、地點與期限，並指派具備對應技能的員工。暫不製作員工接單頁。
3. **索賠審查**：只列出疑似新增的車身損傷，依嚴重程度由高至低排列。點入後可選擇確認進入索賠、暫緩補件或不進入索賠，理由必填。

左側「展示案例」仍可切換 S01–S07 與重設固定資料，供錄製不同情境。既有完工複檢、車輛狀態、稽核事件及權限資料保留在 Store，但不再占用主要展示畫面。

## 驗證

```powershell
npm run format
npm run lint
npm run typecheck
npm run test
npm run build
```

## Prototype 邊界

- 任務、人員、時間、影像與索賠結果皆為本機固定假資料。
- AI 只整理證據與提出建議，不自動判定責任或賠償金額。
- 尚未串接 iRent API、真實派工、員工系統或手機端即時傳輸。
- 介面是流程展示，不代表正式 AI 模型或企業後台已完成。
- 原第 8 階段自動驗證紀錄位於 `docs/stage8-validation-report.md`；本次介面收斂後需重新進行瀏覽器視覺與互動補驗。
