# InspectFlow Mobile Prototype

> 全車連續掃描改造進度：第 6 階段完成後再依展示需求收斂。約 29 秒連續影片現在使用六個不同視角，並在區域之間加入移動過場與步行提示；六區初始均為待掃描。Prototype 只保留還車車況檢查主線。

Flutter 製作的 iRent InspectFlow 手機端展示原型。目前展示還車時的六區車況檢查、左側刮痕多角度補掃、後座污損、檢查摘要、模擬上傳、完成頁及本機輸出 JSON。取車檢查與完工複檢不再提供展示入口，將由簡報或口頭說明補充。

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

1. 開啟 App，在「掃描」入口查看車號、車型及初始皆為空白的六區俯視圖。
2. 按下「掃描車輛狀況」後直接進入橫向全畫面掃描，不經過另一個六區總覽或橫放確認頁。
3. 同一段本機影片會依序呈現右側、車頭、左側、車尾、前座與後座六個不同影像。
4. 每區由時間軸提供無車、區域辨識、0.8 秒品質鎖定與自動擷取；區域切換使用 0.8 秒影像過場及步行提示，不會瞬間跳到下一側。
5. 左側廣角會框出疑似刮痕，影片接著靠近並自動保存中央、左側與右側三個視角；右下角左側格保留橘色異常標記。
6. 補充影像完成後自動退回廣角、前往車尾；車外完成後提示開門並接續前、後座。
7. 前座正常擷取；後座會框出右側座墊污漬並在右下角車圖保留第二個橘色異常標記。
8. 六區完成後短暫顯示兩處待確認影像，約 0.9 秒後自動離開掃描並直接開啟六區摘要，不需要按下完成。
9. 摘要與本機輸出會包含刮痕及污漬兩筆 Finding，再接續正常的逐區模擬上傳；展示不包含上傳失敗或重試。
10. 長按左上角返回按鈕可開啟隱藏展示控制器，重播完整流程或跳至下一事件。

原版單區與完工複檢程式仍保留於專案中供設計參考，但已從使用者可見入口移除，不屬於目前展示主線。

目前主線影片為 `full_vehicle_scan_panorama_v3.mp4`。車頭完成後會額外停留約 0.5 秒再轉向左側，移動期間掃描框保持顯示；左側刮痕的橘色框依實際位置縮小校正，近距離補掃提高到 2.3 倍並維持刮痕置中。

原版流程的完整驗證結果請見 [`docs/stage8-validation-report.md`](docs/stage8-validation-report.md)；新版連續主線請見 [`docs/stage6-continuous-scan-validation-report.md`](docs/stage6-continuous-scan-validation-report.md)。

## 尚未實作

- 新版連續主線在實際 Chrome 或 Android 裝置的不中斷展示演練。
- 後台與跨端功能

所有畫面均為 Prototype，不代表正式 AI 模型或 iRent 系統已完成。
