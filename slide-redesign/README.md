# iRent InspectFlow 重新設計版

本資料夾是以 `codex-ppt` image mode 製作的獨立視覺版本，不會覆蓋原本的 `slide/index.html`。

## 頁數

- 共 16 張。
- 第 1 張封面計入正文。
- 第 2 張提案摘要標示為「不計入 15 頁」。
- 第 3 至 16 張對應正文第 2 至 15 頁。
- 本版不含附錄，因此符合「15 頁正文＋1 頁不計入摘要」的規劃。

## 目錄

- `slides/`：16 張完整投影片 PNG。
- `prompts/`：逐頁生成提示詞。
- `final/`：PDF 與 image-based PPTX。
- `qa/`：編譯報告與視覺檢查紀錄。
- `brief.md`、`storyline.md`、`design-system.md`、`storyboard.md`：設計與敘事依據。

## 可編輯性

PPTX 每頁以整張圖片置入，適合播放、分享及作為視覺定稿參考；其中的文字與圖表不是獨立可編輯物件。若確認此版方向，再依此視覺系統重建完全可編輯的正式 PPTX。
