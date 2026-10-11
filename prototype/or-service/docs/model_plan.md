# Gurobi 模型計畫：A–D

本文件使用 Markdown 與 LaTeX 表示模型。時間單位均為「自規劃日 09:00 起算的分鐘」，規劃區間為 09:00–17:00；例如 \(180\) 代表 12:00。

> **目前實作範圍（簡化 A）**：只做優先排序、技能／工具篩選與固定出發座標的最近人員推薦；未檢查班次、休息或時間衝突，不是完整排程。以下 B–D 與完整 A 基準為後續設計。詳見 [A 階段結果](../output/stage_a_report.md)。

## 1. 決策範圍與開發順序

在一個班次內，安排具有不同技能與工具的人員，處理分散於台北的車輛整備任務。採混合整數線性規劃（MILP），輸出人員指派、拜訪順序、到場／開始／完成時間、未派任務與車輛預估整備完成時間。

| 階段 | 決策內容 | 定位 |
|---|---|---|
| A | 優先排序與規則派工 | 可重現的比較基準 |
| B | 批次人員指派 | 技能與總工時容量的指派鬆弛模型 |
| C | 任務開始時間與先後順序 | 加入班次、休息、前置與交通時間 |
| D | 完整拜訪路線 | 整合指派、排程與路徑弧 |

B 不保證能直接執行；C、D 的計畫需要獨立檢查器驗證。以下公式描述 D 的完整模型，B、C 從中逐步加入必要限制。

初版假設現場維修、固定交通時間、單人完成單件任務，並於班次結束前返回起點。不處理搬車、維修站容量或交通隨時間變動。資料皆為模擬值，尚未實作或執行 Gurobi 求解。

## 2. 集合

| 符號 | 意義 |
|---|---|
| \(I\) | 任務集合，索引為 \(i,j\) |
| \(K\) | 人員集合，索引為 \(k\) |
| \(V\) | 車輛集合，索引為 \(v\) |
| \(I_v\subseteq I\) | 車輛 \(v\) 恢復可用前的必要任務，含複檢 |
| \(P\subseteq I\times I\) | 前置關係；\((i,j)\in P\) 表示先完成 \(i\) 才能開始 \(j\) |
| \(I^{U},I^{H}\) | urgent、high 任務集合 |
| \(o_k,e_k\) | 人員 \(k\) 的虛擬起點、終點 |
| \(N_k=I\cup\{o_k,e_k\}\) | 人員 \(k\) 的路線節點 |
| \(A_k\) | 允許的有向路徑弧 |

\(A_k\) 包含起點到任務、不同任務之間、任務到終點的弧；排除自環、進入起點、離開終點與起點直接到終點。不同任務即使同一地點仍是不同節點。

## 3. 參數與資料對照

| 符號 | 意義 | JSON 欄位 |
|---|---|---|
| \(H\) | 規劃長度，初版 \(480\) | `planning.horizon_minutes` |
| \(p_i>0\) | 任務處理分鐘 | `duration_minutes` |
| \(r_i\) | 最早開始時間 | `release_minute` |
| \(d_i\) | 軟性完成期限 | `deadline_minute` |
| \(\tau_{ij}\ge0\) | 節點間交通分鐘 | `travel_time_matrix.minutes` |
| \(a_k,b_k\) | 人員可開始工作／班次結束時間 | `available_from_minute`, `shift_end_minute` |
| \(E_{ik}\in\{0,1\}\) | 人員是否同時符合技能與工具需求 | 由 `required_skills`, `required_tools` 與人員資料計算 |
| \(\delta_k\) | 休息長度，初版 \(30\) | `break_duration_minutes` |
| \(L_k,U_k\) | 休息可用區間，初版 \([180,300]\) | `break_window` |
| \(f_v\) | 車輛停用起始時間，可為負數 | `offline_since_minute` |
| \(w_v\) | 車輛需求權重 | `demand_weight` |
| \(\omega_i\) | 任務逾期權重 | 由 `priority` 對應 |

初版取 normal、high、urgent 的 \(\omega_i\) 分別為 \(1,3,10\)，是待敏感度分析的政策假設。

交通時間依節點的 `location_id` 查矩陣；起終點使用人員的起终點地點。相同地點交通可為 \(0\)，服務工時仍為正值。

## 4. 決策變數

| 變數 | 定義域 | 意義 |
|---|---|---|
| \(x_{ik}\) | \(\{0,1\}\) | 任務 \(i\) 是否指派給人員 \(k\) |
| \(u_i\) | \(\{0,1\}\) | 任務是否未安排 |
| \(q_i=1-u_i\) | \(\{0,1\}\) | 任務是否已安排 |
| \(y_{ijk}\) | \(\{0,1\}\) | 人員是否直接由節點 \(i\) 前往 \(j\) |
| \(h_k\) | \(\{0,1\}\) | 人員是否有工作路線 |
| \(s_i,c_i\) | \([0,H]\) | 任務開始／完成時間 |
| \(\ell_i\) | \([0,H]\) | 任務逾期分鐘 |
| \(\pi_{ik}\) | \([0,|I|]\) | 任務在該人員路線中的順序位置 |
| \(z_{ijk}\) | \(\{0,1\}\) | 是否在弧 \(i\to j\) 的出發地點休息 |
| \(\beta_k\) | \([0,H]\) | 休息開始時間 |
| \(g_v\) | \(\{0,1\}\) | 車輛必要任務是否全部安排 |
| \(M_v\) | \([0,H]\) | 車輛必要任務的最大完成時間，輔助變數 |
| \(R_v\) | \([0,H]\) | 完整安排車輛的整備完成時間；未完整安排時為 \(0\) |

公式中的 \(\Rightarrow\) 為條件限制，實作時使用 Gurobi indicator constraints；\(\max\) 使用 general MAX constraint。必要時轉換成有明確界限的線性限制，不使用任意巨大的 Big-M。

## 5. 指派與服務時間限制

### 5.1 每件任務指派一人或列為未安排

\[
\sum_{k\in K}x_{ik}+u_i=1
\qquad \forall i\in I
\]

### 5.2 技能與工具必須符合

\[
x_{ik}\le E_{ik}
\qquad \forall i\in I,\ k\in K
\]

例如，沒有維修技能的人不能指派車燈修復任務。

### 5.3 處理時間與未安排狀態

\[
0\le s_i\le Hq_i,\qquad
c_i=s_i+p_iq_i,\qquad
0\le\ell_i\le Hq_i
\qquad \forall i\in I
\]

已安排時 \(c_i=s_i+p_i\)；未安排時 \(s_i=c_i=\ell_i=0\)。

### 5.4 開始時間、班次與軟期限

\[
q_i=1\Rightarrow s_i\ge r_i
\]

\[
x_{ik}=1\Rightarrow s_i\ge a_k,\qquad
x_{ik}=1\Rightarrow c_i\le b_k
\]

\[
q_i=1\Rightarrow\ell_i\ge c_i-d_i
\]

上述限制對相應任務與人員成立。班次為硬限制；期限可逾期，但受到目標函數懲罰。交通及回程另由路線限制保證。

## 6. 路線與時間限制

### 6.1 每件已指派任務有一條進入與離開弧

\[
\sum_{j:(j,i)\in A_k}y_{jik}=x_{ik},\qquad
\sum_{j:(i,j)\in A_k}y_{ijk}=x_{ik}
\qquad \forall i\in I,\ k\in K
\]

### 6.2 有工作的員工從起點出發，最後回到終點

\[
\sum_{j\in I}y_{o_kjk}=h_k,\qquad
\sum_{i\in I}y_{ie_kk}=h_k
\qquad \forall k\in K
\]

\[
x_{ik}\le h_k,\qquad
h_k\le\sum_{i\in I}x_{ik}
\]

沒有任務的員工不強迫出車。

### 6.3 任務間交通與回程

\[
y_{ijk}=1\Rightarrow s_j\ge c_i+\tau_{ij}
\qquad i,j\in I
\]

\[
y_{o_kjk}=1\Rightarrow s_j\ge a_k+\tau_{o_kj}
\]

\[
y_{ie_kk}=1\Rightarrow c_i+\tau_{ie_k}\le b_k
\]

例如，前一件任務 10:00 完成、交通需要 20 分鐘，下一件最早 10:20 開始。這些時間允許等待；休息插入時還需要滿足第 8 節。

### 6.4 排除不連到起點的子迴圈

\[
x_{ik}\le\pi_{ik}\le |I|x_{ik}
\]

\[
y_{ijk}=1\Rightarrow\pi_{jk}\ge\pi_{ik}+1
\qquad i,j\in I,\ i\ne j
\]

任務順序必須沿路線增加，不能形成 \(i\to j\to i\) 的迴圈。正工時配合時間傳遞也能排除任務環，但保留順序限制利於驗證及擴充。

## 7. 任務前置關係

\[
q_j\le q_i
\qquad\forall(i,j)\in P
\]

\[
q_j=1\Rightarrow s_j\ge c_i
\qquad\forall(i,j)\in P
\]

例如，後座清潔完成才能開始複檢；清潔與複檢可以由不同員工執行，但不能跳過清潔而安排複檢。

## 8. 休息限制

休息必須完整落在允許區間：

\[
L_k\le\beta_k,\qquad
\beta_k+\delta_k\le U_k
\qquad\forall k\in K
\]

有路線的員工選一條使用中的弧，在出發地點休息：

\[
z_{ijk}\le y_{ijk},\qquad
\sum_{(i,j)\in A_k}z_{ijk}=h_k
\]

定義弧出發節點的可離開時間：

\[
D_{ik}=\begin{cases}
a_k,&i=o_k,\\
c_i,&i\in I.
\end{cases}
\]

若在弧出發前休息：

\[
z_{ijk}=1\Rightarrow\beta_k\ge D_{ik}
\]

\[
z_{ijk}=1\Rightarrow s_j\ge\beta_k+\delta_k+\tau_{ij}
\qquad j\in I
\]

\[
z_{ie_kk}=1\Rightarrow
\beta_k+\delta_k+\tau_{ie_k}\le b_k
\]

可在首件之前、任務之間或回程之前休息，休息時停留在當前地點，因此不會與工作或行駛重疊。沒有任務的人在起點休息，仍保留區間內的 \(\beta_k\)，不需建立路線弧。

## 9. 車輛整備完成時間

車輛全部必要任務都安排，才算完整安排：

\[
g_v\le q_i\quad\forall i\in I_v,\qquad
g_v\ge\sum_{i\in I_v}q_i-|I_v|+1
\]

\[
M_v=\max_{i\in I_v}c_i
\]

\[
g_v=1\Rightarrow R_v=M_v,\qquad
0\le R_v\le Hg_v
\]

\(g_v=0\) 時 \(R_v=0\) 僅作為內部計算值，API 對外輸出 `null` 與「未完成」，不能顯示成 09:00 已恢復可用。

這是**預估整備完成時間**，不包含人工放行等待。最佳化計畫不能直接解除安全停用，實際出租仍需完工證據、複檢與授權。

## 10. 多目標函數

採優先序目標，先處理前一層，再改善下一層，不把件數與分鐘直接混成相同單位。

### 第一層：減少 urgent 未派件數

\[
\min F_1=\sum_{i\in I^{U}}u_i
\]

### 第二層：減少 high 未派件數

\[
\min F_2=\sum_{i\in I^{H}}u_i
\]

### 第三層：減少所有未派件數

\[
\min F_3=\sum_{i\in I}u_i
\]

### 第四層：降低加權逾期分鐘

\[
\min F_4=\sum_{i\in I}\omega_i\ell_i
\]

### 第五層：縮短完整安排車輛的加權停用時間

\[
\min F_5=\sum_{v\in V}w_v\left(R_v-f_vg_v\right)
\]

當 \(g_v=1\)，項目為 \(w_v(R_v-f_v)\)；當 \(g_v=0\)，項目為 \(0\)。此式是線性的，因為 \(f_v\) 是常數。

前面層級先保護任務服務量，報表仍須另列未完成車輛。此目標只衡量完整安排的車輛；若營運希望優先增加恢復車輛數，可在第五層之前另加 \(\max\sum_v g_v\)，需先確認政策。

### 第六層：降低總交通分鐘

\[
\min F_6=\sum_{k\in K}\sum_{(i,j)\in A_k}\tau_{ij}y_{ijk}
\]

包含起程、任務間移動與回程。以 Gurobi 多目標優先序或逐層求解實作；限時取得的解不一定證明各層最優，需要保留各層目標值、界限與停止原因。

## 11. A、B 的實作定位

A 的優先序為 urgent → high → normal，同級依期限、可開始時間、任務 ID 排序。另建立「先到先做」與「最近合格人員」基準。產生完整計畫時，仍需檢查休息、交通、前置與回程；不合法方案不能作有效比較基準。

B 先使用指派、未派與相容性限制，加上總服務工時容量：

\[
\sum_{i\in I}p_ix_{ik}\le b_k-a_k-\delta_k
\qquad\forall k\in K
\]

交通成本暫用起點到各任務的近似：

\[
\min\sum_{k\in K}\sum_{i\in I}\tau_{o_ki}x_{ik}
\]

這不是完整路線交通量，不能保證時序可行。C 加入員工內任務先後、交通與休息，D 整合完整路徑；最終以 D 為完整營運建議模型。

## 12. 輸出、評估與驗證

輸出 `input_version`、`scenario_id`、求解狀態、是否有可行解、求解秒數、各層目標值／界限／gap、人員路線、任務時間、未派案件與車輛預估整備完成時間。

未派原因分成可直接證明的「無技能／工具人員」與需進一步診斷的「容量或期限競爭」。軟期限本身不直接造成不可行，不得把猜測當成證明。

以相同輸入與同等限制比較完整基準與 D，報告：

- 安排／未派件數與完成整備車輛數。
- 逾期件數、加權及未加權逾期分鐘。
- 總交通分鐘、各人工作與休息時間。
- 已完成車輛的停用時間及未完成車輛數，避免只報有利平均。
- 求解時間與各層最佳化差距。

初步使用 30 秒限時與 2% `MIPGap` 作實驗起點，不承諾所有規模都達標。多目標求解需逐層記錄品質，不能以單一 gap 代表整體優先序已證明最優。若逐層求解，需控制全部階段合計的時間預算。

沒有 incumbent 時不返回空計畫作為成功；模型不可行時分析 IIS，回報限制衝突。獨立檢查器需核對指派、技能、時序、交通、休息、回程、前置與指標計算。

## 13. 未來擴充

- **E 動態重排**：新增事件觸發、已開始／人工鎖定任務與改派成本。現有 `locked` 欄位僅預留，皆為 `null`，尚未實作。
- **F 車輛跨區調度**：加入區域需求、可用車輛供給、搬車人力與停車容量，建立另一個調度模型。

## 14. 官方參考

- [Gurobi Python Model](https://docs.gurobi.com/projects/optimizer/en/current/reference/python/model.html)
- [Gurobi 多目標](https://docs.gurobi.com/projects/optimizer/en/current/features/multiobjective.html)
- [Gurobi 求解參數](https://docs.gurobi.com/projects/optimizer/en/current/reference/parameters.html)
