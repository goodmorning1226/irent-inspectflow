import { scenarioCatalog } from '../data/scenarios';
import type { ScenarioId } from '../domain/types';
import { useInspectFlowStore } from '../store/inspectFlowStore';

export function ScenarioControl() {
  const activeScenarioId = useInspectFlowStore(
    (state) => state.activeScenarioId,
  );
  const dataset = useInspectFlowStore((state) => state.dataset);
  const loadScenario = useInspectFlowStore((state) => state.loadScenario);
  const resetActiveScenario = useInspectFlowStore(
    (state) => state.resetActiveScenario,
  );

  const vehicle = dataset.vehicles[0];
  const currentCase = dataset.cases[0];

  return (
    <details className="scenario-control">
      <summary>
        <span>
          <small>展示案例</small>
          <strong>
            {dataset.meta.id}・{dataset.meta.name}
          </strong>
        </span>
        <span className="scenario-control__chevron" aria-hidden="true">
          ＋
        </span>
      </summary>

      <div className="scenario-control__body">
        <label htmlFor="scenario-select">切換固定情境</label>
        <select
          id="scenario-select"
          onChange={(event) => loadScenario(event.target.value as ScenarioId)}
          value={activeScenarioId}
        >
          {scenarioCatalog.map((scenario) => (
            <option key={scenario.id} value={scenario.id}>
              {scenario.id}・{scenario.name}
            </option>
          ))}
        </select>

        <dl className="scenario-control__context">
          <div>
            <dt>案件</dt>
            <dd>{currentCase?.id ?? '未建立案件'}</dd>
          </div>
          <div>
            <dt>車輛</dt>
            <dd>{vehicle?.plateNumber ?? '—'}</dd>
          </div>
        </dl>

        <p>{dataset.meta.summary}</p>
        <button
          className="scenario-reset"
          onClick={resetActiveScenario}
          type="button"
        >
          重設此案例資料
        </button>
        <p className="scenario-control__notice">{dataset.meta.dataNotice}</p>
      </div>
    </details>
  );
}
