import s01 from '../../../mock-data/S01.json';
import s02 from '../../../mock-data/S02.json';
import s03 from '../../../mock-data/S03.json';
import s04 from '../../../mock-data/S04.json';
import s05 from '../../../mock-data/S05.json';
import s06 from '../../../mock-data/S06.json';
import s07 from '../../../mock-data/S07.json';
import type { ScenarioDataset, ScenarioId } from '../domain/types';

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
  return structuredClone(datasets[scenarioId]);
}

export function getAllScenarioDatasets(): ScenarioDataset[] {
  return SCENARIO_IDS.map((scenarioId) => getScenarioDataset(scenarioId));
}

export const scenarioCatalog = SCENARIO_IDS.map((id) => {
  const { meta } = datasets[id];
  return { ...meta };
});
