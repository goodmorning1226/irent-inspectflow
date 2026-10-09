# InspectFlow Mobile Prototype

Flutter 製作的 iRent InspectFlow 手機端展示原型。目前完成第 1 階段：工程骨架、共用視覺 Theme、頁面路由、淺色流程 Scaffold、深色掃描 Scaffold、Prototype 標示及最小假資料。

一般取還車頁面固定使用直屏；進入 `ScanScaffold` 時會切換為橫屏，離開掃描頁後恢復直屏。Web 平台不保證能由程式鎖定瀏覽器方向，展示時以橫向視窗呈現掃描頁。

## 環境

- Flutter 3.41.7 stable
- Dart 3.11.5
- 已建立 Android、Web 與 Windows 平台檔案
- 目前主要開發與截圖裝置為 Chrome；第 1 階段未偵測到 Android 實機或模擬器

## 執行

```powershell
cd D:\github\irent-inspectflow\prototype\mobile
flutter pub get
flutter run -d chrome
```

## 驗證

```powershell
flutter analyze
flutter test test/app_smoke_test.dart
```

## 目前可操作內容

1. 開啟 App，查看還車車況入口、車輛及還車資訊。
2. 點選「進入車況檢查」。
3. 進入第 2 階段預留的車況檢查頁，再使用返回鍵回到入口。

## 尚未實作

- 六區選擇及進度
- 影片掃描與時間軸腳本
- 無損、有損與車內污損案例
- 上傳、完成及完工複檢
- 後台與跨端功能

所有畫面均為 Prototype，不代表正式 AI 模型或 iRent 系統已完成。
