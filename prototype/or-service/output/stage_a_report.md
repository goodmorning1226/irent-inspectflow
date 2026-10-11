# A 階段：座標距離派工建議

僅為獨立派工建議，未套用指派。人員位置不隨推薦更新；未檢查班次容量、時間衝突、休息或交通，非可執行排程。release_minute 為最早可處理時間，本階段不判斷是否已到該時間。

排序：urgent → high → normal；同級依期限、最早開始時間與 ID。

| 排序 | 任務 | 區域 | 優先度 | 推薦人員 | 直線公里 | 狀態 |
|---|---|---|---|---|---|---|
| 1 | TSK-010 | 內湖 | urgent | WRK-03 | 3.347 | RECOMMENDED |
| 2 | TSK-001 | 中正 | urgent | WRK-03 | 4.753 | RECOMMENDED |
| 3 | TSK-023 | 內湖 | high | — | — | WAITING_PREDECESSOR |
| 4 | TSK-022 | 大安 | high | — | — | WAITING_PREDECESSOR |
| 5 | TSK-021 | 萬華 | high | — | — | WAITING_PREDECESSOR |
| 6 | TSK-005 | 松山 | high | WRK-01 | 4.753 | RECOMMENDED |
| 7 | TSK-024 | 萬華 | high | — | — | WAITING_PREDECESSOR |
| 8 | TSK-009 | 北投 | high | WRK-05 | 0.0 | RECOMMENDED |
| 9 | TSK-013 | 中正 | high | WRK-03 | 4.753 | RECOMMENDED |
| 10 | TSK-017 | 松山 | high | WRK-01 | 4.753 | RECOMMENDED |
| 11 | TSK-014 | 大同 | normal | WRK-01 | 1.785 | RECOMMENDED |
| 12 | TSK-006 | 大安 | normal | WRK-01 | 3.955 | RECOMMENDED |
| 13 | TSK-004 | 中山 | normal | WRK-03 | 3.221 | RECOMMENDED |
| 14 | TSK-003 | 萬華 | normal | WRK-02 | 0.0 | RECOMMENDED |
| 15 | TSK-018 | 大安 | normal | WRK-01 | 3.955 | RECOMMENDED |
| 16 | TSK-015 | 萬華 | normal | WRK-02 | 0.0 | RECOMMENDED |
| 17 | TSK-007 | 信義 | normal | WRK-04 | 0.0 | RECOMMENDED |
| 18 | TSK-019 | 信義 | normal | WRK-04 | 0.0 | RECOMMENDED |
| 19 | TSK-012 | 文山 | normal | WRK-01 | 6.785 | RECOMMENDED |
| 20 | TSK-011 | 南港 | normal | WRK-01 | 9.028 | RECOMMENDED |
| 21 | TSK-008 | 士林 | normal | WRK-05 | 5.1 | RECOMMENDED |
| 22 | TSK-020 | 士林 | normal | WRK-05 | 5.1 | RECOMMENDED |
| 23 | TSK-016 | 中山 | normal | WRK-03 | 3.221 | RECOMMENDED |
| 24 | TSK-002 | 大同 | normal | WRK-01 | 1.785 | RECOMMENDED |

同一人可被多件任務推薦；這些建議不能直接當成同時可執行的工作表。
距離是座標間的大圓距離，未使用資料中的交通矩陣，也未換算到場時間。
