import { getAllScenarioDatasets } from '../data/scenarios';
import { findingTypeLabels, severityLabels } from './caseEvidence';
import type { FindingSeverity, ScenarioDataset, ScenarioId } from './types';

const severityRank: Record<FindingSeverity, number> = {
  high: 0,
  medium: 1,
  low: 2,
  unknown: 3,
};

export interface ClaimRow {
  caseId: string;
  scenarioId: ScenarioId;
  plateNumber: string;
  title: string;
  typeLabel: string;
  location: string;
  severity: FindingSeverity;
  severityLabel: string;
  createdAt: string;
  reviewed: boolean;
}

export function buildClaimRows(activeDataset: ScenarioDataset): ClaimRow[] {
  return getAllScenarioDatasets()
    .map((dataset) =>
      dataset.meta.id === activeDataset.meta.id ? activeDataset : dataset,
    )
    .flatMap((dataset) =>
      dataset.cases.flatMap((currentCase) => {
        const finding = dataset.findings.find(
          (item) =>
            currentCase.findingIds.includes(item.id) &&
            item.possiblyNew === true &&
            ['scratch', 'dent', 'crack'].includes(item.type),
        );
        if (!finding) return [];
        const vehicle = dataset.vehicles.find(
          (item) => item.id === currentCase.vehicleId,
        );
        return [
          {
            caseId: currentCase.id,
            scenarioId: dataset.meta.id,
            plateNumber: vehicle?.plateNumber ?? '—',
            title: currentCase.title,
            typeLabel: findingTypeLabels[finding.type],
            location: finding.location,
            severity: finding.severity,
            severityLabel: severityLabels[finding.severity],
            createdAt: currentCase.createdAt,
            reviewed: dataset.claimDecisions.some(
              (item) => item.caseId === currentCase.id,
            ),
          },
        ];
      }),
    )
    .sort(
      (left, right) =>
        severityRank[left.severity] - severityRank[right.severity] ||
        Date.parse(right.createdAt) - Date.parse(left.createdAt),
    );
}
