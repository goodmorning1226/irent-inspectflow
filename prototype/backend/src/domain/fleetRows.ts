import { getAllRuntimeScenarioDatasets } from '../data/scenarios';
import type { Case, Rental, ScenarioDataset, Vehicle } from './types';

export interface FleetRecord {
  dataset: ScenarioDataset;
  vehicle: Vehicle;
  currentCase: Case;
  rental: Rental;
}

function collectFleetRecords(activeDataset: ScenarioDataset): FleetRecord[] {
  return getAllRuntimeScenarioDatasets()
    .map((dataset) =>
      dataset.meta.id === activeDataset.meta.id ? activeDataset : dataset,
    )
    .flatMap((dataset) =>
      dataset.vehicles.flatMap((vehicle) => {
        if (!['READY', 'RENTED'].includes(vehicle.availability)) return [];
        const currentCase = [...dataset.cases]
          .reverse()
          .find((item) => item.vehicleId === vehicle.id);
        const rental = [...dataset.rentals]
          .reverse()
          .find((item) => item.vehicleId === vehicle.id);
        if (!currentCase || !rental) return [];
        return [{ dataset, vehicle, currentCase, rental }];
      }),
    );
}

export function buildFleetRecords(
  activeDataset: ScenarioDataset,
): FleetRecord[] {
  return collectFleetRecords(activeDataset)
    .sort((left, right) => {
      const availabilityRank = { READY: 0, RENTED: 1 } as const;
      const cleanlinessRank = { normal: 0, clean: 1 } as const;
      const leftCleanliness = left.vehicle.cleanliness ?? 'normal';
      const rightCleanliness = right.vehicle.cleanliness ?? 'normal';
      return (
        availabilityRank[left.vehicle.availability as 'READY' | 'RENTED'] -
          availabilityRank[right.vehicle.availability as 'READY' | 'RENTED'] ||
        cleanlinessRank[leftCleanliness] - cleanlinessRank[rightCleanliness] ||
        left.vehicle.plateNumber.localeCompare(right.vehicle.plateNumber)
      );
    })
    .slice(0, 8);
}

export function buildFleetWorkspace(
  vehicleId: string,
  activeDataset: ScenarioDataset,
): FleetRecord | null {
  return (
    collectFleetRecords(activeDataset).find(
      (record) => record.vehicle.id === vehicleId,
    ) ?? null
  );
}
