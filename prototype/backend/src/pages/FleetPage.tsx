import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { AppIcon } from '../components/AppIcon';
import { buildFleetRecords, type FleetRecord } from '../domain/fleetRows';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function FleetPage() {
  const activeDataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const updateCaseStatus = useInspectFlowStore(
    (state) => state.updateCaseStatus,
  );
  const updateVehicleStatus = useInspectFlowStore(
    (state) => state.updateVehicleStatus,
  );
  const createTask = useInspectFlowStore((state) => state.createTask);
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const records = useMemo<FleetRecord[]>(
    () => buildFleetRecords(activeDataset),
    [activeDataset],
  );

  const visibleRecords = records.filter((record) =>
    `${record.vehicle.plateNumber} ${record.vehicle.modelName} ${record.rental.returnLocation}`
      .toLocaleLowerCase('zh-TW')
      .includes(search.trim().toLocaleLowerCase('zh-TW')),
  );

  function activateRecord(record: FleetRecord) {
    if (record.dataset.meta.id !== activeDataset.meta.id) {
      loadScenario(record.dataset.meta.id);
    }
  }

  function sendCleaningRequest(record: FleetRecord) {
    if (record.vehicle.availability !== 'READY') return;
    activateRecord(record);
    updateCaseStatus(record.currentCase.id, 'PENDING_CLEANING');
    updateVehicleStatus(
      record.vehicle.id,
      'CLEANING',
      '營運人員透過 API 送出清潔處理請求',
    );
    const result = createTask({
      caseId: record.currentCase.id,
      type: 'cleaning',
      title: `${record.vehicle.plateNumber} 清潔處理`,
      actorId: 'USR-OPS-001',
      priority: 'normal',
    });
    if (result.entityId) navigate('/processing');
  }

  function markForReview(record: FleetRecord) {
    if (record.vehicle.availability !== 'READY') return;
    activateRecord(record);
    updateCaseStatus(record.currentCase.id, 'PENDING_REVIEW');
    updateVehicleStatus(
      record.vehicle.id,
      'REVIEW_REQUIRED',
      '營運人員標記車況異常，等待人工覆核',
    );
    navigate('/cases');
  }

  return (
    <div className="page-stack fleet-page fleet-operations-page">
      <section className="page-intro page-intro--compact">
        <h2>車輛管理</h2>
        <div className="page-list-tools">
          <label className="compact-search fleet-search">
            <span>搜尋車號、車型或位置</span>
            <input
              onChange={(event) => setSearch(event.target.value)}
              placeholder="例如：KBC-2186、信義區"
              type="search"
              value={search}
            />
          </label>
          <button
            aria-label="篩選車輛"
            className="filter-icon-button"
            title="篩選"
            type="button"
          >
            <AppIcon name="filter" />
          </button>
        </div>
      </section>

      <section className="simple-table-wrap" aria-label="車輛管理清單">
        <table className="simple-table unified-record-table fleet-operations-table--ready">
          <thead>
            <tr>
              <th>車輛</th>
              <th>車型</th>
              <th>目前位置</th>
              <th>狀態</th>
              <th>整潔狀態</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            {visibleRecords.map((record) => (
              <tr
                aria-label={`查看 ${record.vehicle.plateNumber} 車輛詳情`}
                className="record-row"
                key={record.vehicle.id}
                onClick={() => navigate(`/fleet/${record.vehicle.id}`)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    navigate(`/fleet/${record.vehicle.id}`);
                  }
                }}
                tabIndex={0}
              >
                <td>
                  <strong>{record.vehicle.plateNumber}</strong>
                  <small>{record.vehicle.colorName}</small>
                </td>
                <td>{record.vehicle.modelName}</td>
                <td>{record.rental.returnLocation}</td>
                <td>
                  <span
                    className={`fleet-table-state fleet-table-state--${
                      record.vehicle.availability === 'READY'
                        ? 'ready'
                        : 'rented'
                    }`}
                  >
                    {record.vehicle.availability === 'READY'
                      ? '待租'
                      : '租借中'}
                  </span>
                </td>
                <td>
                  <span
                    className={`cleanliness-state cleanliness-state--${
                      record.vehicle.cleanliness ?? 'normal'
                    }`}
                  >
                    {record.vehicle.cleanliness === 'clean' ? '乾淨' : '普通'}
                  </span>
                </td>
                <td>
                  <div className="fleet-management-actions">
                    <button
                      className="fleet-management-action fleet-management-action--cleaning"
                      disabled={record.vehicle.availability !== 'READY'}
                      onClick={(event) => {
                        event.stopPropagation();
                        sendCleaningRequest(record);
                      }}
                      onKeyDown={(event) => event.stopPropagation()}
                      type="button"
                    >
                      送出清潔請求
                    </button>
                    <button
                      className="fleet-management-action fleet-management-action--review"
                      disabled={record.vehicle.availability !== 'READY'}
                      onClick={(event) => {
                        event.stopPropagation();
                        markForReview(record);
                      }}
                      onKeyDown={(event) => event.stopPropagation()}
                      type="button"
                    >
                      判定異常
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {visibleRecords.length === 0 && (
          <div className="simple-empty">目前沒有符合條件的正常車輛。</div>
        )}
      </section>
    </div>
  );
}
