# InspectFlow Mobile Prototype

Flutter 製作的 iRent InspectFlow 手機端展示原型。目前已完成第 8 階段手機端定稿：六區車況檢查、左側無損／有損與後座污損案例、檢查摘要、模擬上傳、完成頁、本機輸出 JSON、簡化完工複檢，以及完整尺寸與流程驗證。

一般取還車頁面固定使用直屏；進入 `ScanScaffold` 時會切換為橫屏，離開掃描頁後恢復直屏。Web 平台不保證能由程式鎖定瀏覽器方向，展示時以橫向視窗呈現掃描頁。

## 環境

- Flutter 3.41.7 stable
- Dart 3.11.5
- 已建立 Android、Web 與 Windows 平台檔案
- 目前主要開發與截圖裝置為 Chrome；第 1 階段未偵測到 Android 實機或模擬器
- 本機影片使用 Flutter 官方 `video_player` 2.11.1；目前 Prototype 以 Android 與 Web 為展示目標，Windows 不列入影片播放驗收。

## 執行

```powershell
cd D:\github\irent-inspectflow\prototype\mobile
flutter pub get
flutter run -d chrome
```

## 驗證

```powershell
dart format lib
flutter analyze --no-pub
flutter test test/scan_timeline_test.dart
flutter test test/mobile_inspection_result_test.dart
flutter test
flutter build web --debug
```

## 目前可操作內容

1. 開啟 App，查看還車車況入口、車輛及還車資訊。
2. 點選「進入車況檢查」。
3. 在六區總覽選擇車頭、左側、車尾、右側、前座或後座。
4. 車頭、車尾、右側與前座可查看固定影像、完成時間及品質摘要。
5. 左側與後座會先顯示橫放手機提示，再進入共用橫向掃描畫面。
6. 掃描畫面以本機 MP4 加 JSON 時間軸依序顯示定位、對準、品質鎖定與自動擷取。
7. 長按右上角「Prototype 模擬結果」可開啟 Demo 控制器，切換左側無損、左側有損或後座污損案例，並可重播、跳到下一事件或重設。
8. 左側掃描完成後會顯示最佳影格與「未發現明顯異常」；按下完成返回總覽，左側狀態更新為已完成。
9. 長按 Prototype 標示切換為「左側有損」後，廣角掃描會框出疑似刮痕，引導完成中央、左側及右側三個近距離視角。
10. 有損路徑只告知已取得補充影像並等待後續比對，不向會員顯示責任、索賠或賠償判定。
11. 選擇後座後會以座椅與腳踏區導引完成橫向車內掃描，框選右側座墊飲料污漬並保存車內 Finding。
12. 完成後返回六區總覽，後座標記為已完成並顯示「等待後續處理」；會員端不顯示清潔費或責任判定。
13. 六區都完成後進入檢查摘要，再執行逐區模擬上傳；左側會固定發生一次連線中斷，點選重試後可接續完成。
14. 完成頁說明後續分析會在背景進行，可返回 iRent 流程或重設 Prototype。
15. 首頁提供取車、還車與完工複檢三種最低必要入口；完工複檢會顯示原異常，再切換橫向完成同區域重掃。
16. 完工重掃預設顯示通過；長按右上角 Prototype 標示可切換為「仍需補充處理」。

完整驗證結果請見 [`docs/stage8-validation-report.md`](docs/stage8-validation-report.md)。

## 尚未實作

- 後台與跨端功能

所有畫面均為 Prototype，不代表正式 AI 模型或 iRent 系統已完成。
