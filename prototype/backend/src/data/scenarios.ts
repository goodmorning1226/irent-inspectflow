import s01 from '../../../mock-data/S01.json';
import s02 from '../../../mock-data/S02.json';
import s03 from '../../../mock-data/S03.json';
import s04 from '../../../mock-data/S04.json';
import s05 from '../../../mock-data/S05.json';
import s06 from '../../../mock-data/S06.json';
import s07 from '../../../mock-data/S07.json';
import type { ScenarioDataset, ScenarioId } from '../domain/types';
import { appendOperationsDemo } from './operationsDemo';

export const SCENARIO_IDS: ScenarioId[] = [
  'S01',
  'S02',
  'S03',
  'S04',
  'S05',
  'S06',
  'S07',
];

const datasets: Record<ScenarioId, ScenarioDataset> = {
  S01: s01 as ScenarioDataset,
  S02: s02 as ScenarioDataset,
  S03: s03 as ScenarioDataset,
  S04: s04 as ScenarioDataset,
  S05: s05 as ScenarioDataset,
  S06: s06 as ScenarioDataset,
  S07: s07 as ScenarioDataset,
};

export function isScenarioDataset(value: unknown): value is ScenarioDataset {
  if (!value || typeof value !== 'object') return false;
  const candidate = value as Partial<ScenarioDataset>;
  return (
    candidate.schemaVersion === 'prototype-1.0' &&
    SCENARIO_IDS.includes(candidate.meta?.id as ScenarioId) &&
    Array.isArray(candidate.vehicles) &&
    Array.isArray(candidate.rentals) &&
    Array.isArray(candidate.inspectionSessions) &&
    Array.isArray(candidate.findings) &&
    Array.isArray(candidate.cases) &&
    Array.isArray(candidate.tasks) &&
    Array.isArray(candidate.workers) &&
    Array.isArray(candidate.assignments) &&
    Array.isArray(candidate.vehicleStatusEvents) &&
    Array.isArray(candidate.reviewDecisions) &&
    Array.isArray(candidate.completionReviews) &&
    Array.isArray(candidate.releaseAuthorizations) &&
    Array.isArray(candidate.claimDecisions) &&
    Array.isArray(candidate.auditEvents)
  );
}

export function getScenarioDataset(scenarioId: ScenarioId): ScenarioDataset {
  const dataset = structuredClone(datasets[scenarioId]);
  return scenarioId === 'S01' ? appendOperationsDemo(dataset) : dataset;
}

let runtimeDatasets: Record<ScenarioId, ScenarioDataset> | null = null;

const runtimeStoragePrefix = 'inspectflow-runtime-datasets:';

function getRuntimeStorageKey(): string | null {
  if (typeof window === 'undefined' || !import.meta.env.DEV) return null;
  const sessionId =
    typeof __INSPECTFLOW_DEV_SESSION_ID__ === 'undefined'
      ? 'test'
      : __INSPECTFLOW_DEV_SESSION_ID__;
  return `${runtimeStoragePrefix}${sessionId}`;
}

function readStoredRuntimeDatasets(): Record<
  ScenarioId,
  ScenarioDataset
> | null {
  const storageKey = getRuntimeStorageKey();
  if (!storageKey) return null;

  try {
    for (let index = sessionStorage.length - 1; index >= 0; index -= 1) {
      const key = sessionStorage.key(index);
      if (key?.startsWith(runtimeStoragePrefix) && key !== storageKey) {
        sessionStorage.removeItem(key);
      }
    }

    const raw = sessionStorage.getItem(storageKey);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<
      Record<ScenarioId, ScenarioDataset>
    >;
    if (
      !SCENARIO_IDS.every((scenarioId) => isScenarioDataset(parsed[scenarioId]))
    ) {
      sessionStorage.removeItem(storageKey);
      return null;
    }
    return parsed as Record<ScenarioId, ScenarioDataset>;
  } catch {
    sessionStorage.removeItem(storageKey);
    return null;
  }
}

function persistRuntimeDatasets(
  runtime: Record<ScenarioId, ScenarioDataset>,
): void {
  const storageKey = getRuntimeStorageKey();
  if (!storageKey) return;
  sessionStorage.setItem(storageKey, JSON.stringify(runtime));
}

function ensureRuntimeDatasets(): Record<ScenarioId, ScenarioDataset> {
  runtimeDatasets ??=
    readStoredRuntimeDatasets() ??
    (Object.fromEntries(
      SCENARIO_IDS.map((scenarioId) => [
        scenarioId,
        getScenarioDataset(scenarioId),
      ]),
    ) as Record<ScenarioId, ScenarioDataset>);
  return runtimeDatasets;
}

export function getRuntimeScenarioDataset(
  scenarioId: ScenarioId,
): ScenarioDataset {
  return structuredClone(ensureRuntimeDatasets()[scenarioId]);
}

export function getAllRuntimeScenarioDatasets(): ScenarioDataset[] {
  const runtime = ensureRuntimeDatasets();
  return SCENARIO_IDS.map((scenarioId) => structuredClone(runtime[scenarioId]));
}

export function saveRuntimeScenarioDataset(dataset: ScenarioDataset): void {
  const runtime = ensureRuntimeDatasets();
  runtime[dataset.meta.id] = structuredClone(dataset);
  persistRuntimeDatasets(runtime);
}

export function resetRuntimeScenarioDatasets(): void {
  runtimeDatasets = null;
  const storageKey = getRuntimeStorageKey();
  if (storageKey) sessionStorage.removeItem(storageKey);
}

export function getAllScenarioDatasets(): ScenarioDataset[] {
  return SCENARIO_IDS.map((scenarioId) => getScenarioDataset(scenarioId));
}

export const scenarioCatalog = SCENARIO_IDS.map((id) => {
  const { meta } = datasets[id];
  return { ...meta };
});
