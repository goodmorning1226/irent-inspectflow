# Windows 開發 Flutter 並安裝至 iPhone

最後更新：2026-10-11

本文件記錄目前已驗證成功的 Windows → GitHub Actions → iPhone 流程。此流程不需要付費 Apple Developer Program，但 Apple ID、密碼及雙重驗證碼只能由使用者本人在 iLoader 視窗輸入，不得寫入專案、指令稿或對話。

## 1. 已驗證環境

- Windows 開發電腦
- Flutter 3.41.7
- iTunes 12.13.11.1 與 Apple Mobile Device Support
- iLoader 2.3.6：`D:\tools\iloader-app\iloader.exe`
- iPhone 已開啟開發者模式、以 USB 連接並信任此電腦
- GitHub Actions 在 macOS runner 建立未簽署 Release IPA
- iLoader 使用免費 Apple ID 在本機重新簽署並安裝 IPA

免費 Apple ID 簽署的 App 通常約 7 天後到期。到期後重新簽署並安裝即可。免費帳號也有可同時安裝 App 與註冊 App ID 的數量限制，因此不使用的測試 App 應適時移除。

## 2. 更新目前的 InspectFlow

### 2.1 修改版本號

在 `prototype/mobile/pubspec.yaml` 增加 build number，例如：

```yaml
version: 1.0.0+2
```

下一次依序改為 `+3`、`+4`。正式版本名稱有變動時，再調整 `1.0.0` 部分。

### 2.2 執行基本檢查

```powershell
cd D:\github\irent-inspectflow\prototype\mobile
flutter analyze --no-pub
flutter test
```

只有在檢查通過後才建立 IPA。

### 2.3 提交並推送修改

先確認 `git status`，不要意外提交下載的 IPA、帳號資料或其他暫存檔。

```powershell
cd D:\github\irent-inspectflow
git status --short
git add <本次確定要提交的檔案>
git commit -m "update mobile prototype"
git push
```

### 2.4 觸發 GitHub Actions Release 建置

`builder.json` 必須保留以下設定：

```json
{
  "ios": {
    "path": "prototype/mobile/ios",
    "bundleId": "tw.irent.inspectflow.mobile",
    "configuration": "Release"
  },
  "flutter": {
    "version": "3.41.7"
  }
}
```

使用一個從未使用過的標籤名稱觸發建置：

```powershell
cd D:\github\irent-inspectflow
git tag ios-build/mobile-update-01
git push origin ios-build/mobile-update-01
```

下一次改用 `mobile-update-02` 或日期加流水號。遠端工作流程完成後會刪除觸發用標籤；本機標籤可能仍存在，因此最簡單的做法是每次使用新名稱。

### 2.5 下載 Release IPA

1. 開啟 GitHub Repository。
2. 進入 `Actions`。
3. 選擇最新的 `iOS Build`。
4. 確認建置結果為綠色 `Success`。
5. 在頁面下方的 `Artifacts` 下載 `ipa`。
6. 解壓縮 ZIP，取得 `.ipa` 檔案。

不要重複安裝舊的 Debug IPA。Flutter Debug App 在沒有 debugger 附加時，可能從 iPhone 主畫面開啟後立即退出。

### 2.6 使用 iLoader 覆蓋安裝

1. 以 USB 連接並解鎖 iPhone。
2. 確認 iPhone 信任此 Windows 電腦。
3. 開啟 `D:\tools\iloader-app\iloader.exe`。
4. 選擇最新下載的 Release IPA。
5. 執行 `Sign & Install App`。
6. 由使用者本人輸入 Apple ID、密碼及雙重驗證碼。
7. 出現 `Operation completed` 後，在 iPhone 主畫面開啟 `iRent InspectFlow`。

相同 Bundle ID 且使用相同 Apple ID 簽署時，一般會覆蓋既有 App。不要先刪除 App，才能盡量保留其本機資料；Prototype 仍不應把重要資料只保存在 App 沙盒內。

若 iPhone 顯示「不受信任的開發者」，前往：

```text
設定 → 一般 → VPN 與裝置管理 → 對應 Apple ID → 信任
```

## 3. 建立其他 Flutter App

### 3.1 建立專案與 iOS 工程

建立新專案：

```powershell
flutter create new_flutter_app
cd new_flutter_app
flutter create --platforms=ios .
```

如果既有 Flutter 專案尚未包含 `ios/`，只需在專案根目錄執行第二行。

### 3.2 設定 App 身分

每個 App 必須使用獨立 Bundle ID，例如：

```text
tw.yourname.newapp
```

同時確認：

- iOS App 顯示名稱
- `pubspec.yaml` 的 `version`
- 支援的直向／橫向方向
- 圖片、影片及 JSON 素材已列入 `pubspec.yaml`
- 不包含需要付費開發者能力的 entitlement

免費 Apple ID 不適合測試 App Store 發布、推播、Sign in with Apple、iCloud 等需要額外 entitlement 或正式 provisioning profile 的功能；目前流程適合基本 Prototype 實機展示。

### 3.3 複製建置工作流程

將 InspectFlow 的 `.github/workflows/ios-build.yml` 複製到新 Repository 的相同位置，並在 Repository 根目錄建立 `builder.json`：

```json
{
  "project": "new-flutter-app",
  "platform": "ios",
  "github": {
    "owner": "YOUR_GITHUB_ACCOUNT",
    "repo": "YOUR_REPOSITORY"
  },
  "provider": "github",
  "ios": {
    "path": "ios",
    "bundleId": "tw.yourname.newapp",
    "configuration": "Release"
  },
  "flutter": {
    "version": "3.41.7"
  }
}
```

若 Flutter App 位於 Repository 子資料夾，`ios.path` 必須包含完整相對路徑，例如：

```json
"path": "apps/mobile/ios"
```

### 3.4 建置及安裝

將新 Repository 推上 GitHub 後：

```powershell
git tag ios-build/first-release-01
git push origin ios-build/first-release-01
```

接著依本文件第 2.5 與 2.6 節下載 IPA，並透過 iLoader 簽署安裝。

## 4. 常見問題

### 安裝成功，但 App 點開立即退出

先確認 `builder.json` 使用：

```json
"configuration": "Release"
```

重新建置並安裝 Release IPA。不要使用需要 Flutter debugger 的 Debug IPA 作為桌面獨立啟動版本。

### iLoader 顯示 EOF 或無法連線裝置

依序檢查：

1. iPhone 已解鎖並信任電腦。
2. iPhone 已開啟開發者模式。
3. Apple Mobile Device Service 正在執行。
4. 關閉後重新開啟 iLoader。
5. 重新插拔 USB 線，避免只支援充電的線材或不穩定 USB Hub。

### 新版本沒有覆蓋舊版本

確認新舊版本使用相同 Bundle ID、相同 Apple ID，並增加 `pubspec.yaml` 的 build number。若簽署工具改寫了 Bundle ID，需以 iLoader 顯示的實際識別碼為準。

### GitHub Actions 沒有開始

確認：

- 標籤名稱以 `ios-build/` 開頭。
- 標籤對應的 commit 已包含 workflow 與 `builder.json`。
- 標籤名稱尚未在本機或遠端使用過。
- GitHub Repository 的 Actions 功能已啟用。

## 5. 安全規則

- 不把 Apple ID 密碼、雙重驗證碼或 GitHub Token 寫進任何檔案。
- 不把憑證、Provisioning Profile、IPA 或簽署暫存檔提交到 Git。
- Apple 登入資訊只在使用者本人可見的 iLoader 視窗輸入。
- 安裝新的 iLoader 或簽署工具前，先確認來源、版本及下載位置。
