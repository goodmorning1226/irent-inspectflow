# InspectFlow AI 車況掃描影片 Demo

這個目錄使用 React、Three.js、無頭 Chrome 與 FFmpeg 製作可重複輸出的產品概念影片，不呼叫任何付費影片生成 API，也不宣稱已完成正式 AI 模型。

## 10 秒測試影片

測試內容為第一人稱從汽車左側完成掃描、步行轉向車頭，再由系統自動辨識車頭。右下角六區俯視圖與鏡頭時間軸同步更新，全程不需手動選區。

```powershell
npm install
npm run render:test
```

主要輸出：`output/inspectflow-scan-test-10s-final.mp4`

- 1920 × 1080
- 60 FPS、600 幀
- H.264、yuv420p
- 10.00 秒

渲染器以 30 FPS 決定性取樣 React／Three.js 畫面，再由 FFmpeg 插幀為 60 FPS。相機與 UI 共用 60 FPS 主時間軸，因此完成狀態與鏡頭位置保持同步。

## 驗證與授權

- `qa/side.png`、`qa/walking.png`、`qa/front.png`：關鍵畫面靜幀。
- `qa/contact-sheet-final.png`：成品三段接觸表。
- `ATTRIBUTION.md`：車輛模型與停車場環境的來源及授權。

完整影片尚未開始；需先由使用者確認此測試場景的車輛、環境、鏡頭與 HUD 品質。

## 純相機素材 V2

依後續展示分工，V2 影片不包含 HUD、提示、異常框、品質進度或六區俯視圖。Flutter 會依獨立時間軸在 App 內疊加所有 UI。

```powershell
npm run render:camera-v2
```

輸出：`output/inspectflow-camera-only-test-v2-10s.mp4`

- 白色一般五門掀背／小型休旅車，同一個有樹木的都市停車場。
- 0–2.7 秒左側定點畫面；2.7–4.7 秒轉向車頭；4.7–10 秒車頭定點畫面。
- 定點段完全固定，沒有上下晃動；轉身瞬間以短暫動態模糊遮蔽視角切換。
- 純 16:9 手機橫向相機畫面，1920 × 1080、60 FPS、600 幀、10.00 秒。
- `camera-timeline-v2.json` 提供 Flutter 疊加介面的同步節點與安全區。
- `CAMERA_ONLY_PIPELINE.md` 記錄正式全流程母片的分層與延伸方式。
