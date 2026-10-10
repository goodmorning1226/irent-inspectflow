export type ScenarioId = 'S01' | 'S02' | 'S03' | 'S04' | 'S05' | 'S06' | 'S07';

export type VehicleAvailability =
  | 'READY'
  | 'REVIEW_REQUIRED'
  | 'CLEANING'
  | 'MAINTENANCE'
  | 'OFFLINE'
  | 'REINSPECTION_REQUIRED';

export type InspectionZone =
  'front' | 'leftSide' | 'rear' | 'rightSide' | 'frontSeat' | 'rearSeat';

export type FindingType =
  | 'scratch'
  | 'dent'
  | 'crack'
  | 'stain'
  | 'litter'
  | 'leftItem'
  | 'reflection'
  | 'obstruction'
  | 'unknown';

export type FindingSeverity = 'low' | 'medium' | 'high' | 'unknown';
export type EvidenceState = 'sufficient' | 'insufficient' | 'not_applicable';
export type CaseStatus =
  | 'RESOLVED'
  | 'PENDING_REVIEW'
  | 'PENDING_CLEANING'
  | 'PENDING_INSPECTION'
  | 'PENDING_REPAIR'
  | 'CLAIM_REVIEW';
export type TaskType = 'cleaning' | 'inspection' | 'repair' | 'claim_review';
export type TaskStatus =
  | 'PENDING'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'WAITING_REVIEW'
  | 'COMPLETED'
  | 'RETURNED'
  | 'CANCELLED';
export type ReviewOutcome =
  | 'CONFIRMED_ANOMALY'
  | 'NOT_DAMAGE'
  | 'EVIDENCE_INSUFFICIENT'
  | 'REQUEST_MORE_EVIDENCE'
  | 'RETURNED';
export type ClaimOutcome =
  | 'EVIDENCE_SUFFICIENT'
  | 'EVIDENCE_INSUFFICIENT'
  | 'NOT_NEW_DAMAGE'
  | 'REQUEST_MORE_EVIDENCE';

export interface ScenarioMeta {
  id: ScenarioId;
  name: string;
  purpose: string;
  summary: string;
  dataNotice: string;
}

export interface Vehicle {
  id: string;
  plateNumber: string;
  modelName: string;
  colorName: string;
  availability: VehicleAvailability;
}

export interface Rental {
  id: string;
  vehicleId: string;
  memberIdMasked: string;
  pickupAt: string;
  pickupLocation: string;
  returnAt: string;
  returnLocation: string;
}

export interface ZoneCapture {
  zone: InspectionZone;
  capturedAt: string;
  qualitySummary: string;
  sourceImages: string[];
}

export interface InspectionSession {
  id: string;
  rentalId: string;
  vehicleId: string;
  type: 'pickup' | 'return' | 'completion_review';
  capturedAt: string;
  zoneCaptures: ZoneCapture[];
  isPrototype: true;
}

export interface Finding {
  id: string;
  inspectionSessionId: string;
  location: string;
  zone: InspectionZone;
  type: FindingType;
  severity: FindingSeverity;
  possiblyNew: boolean | null;
  confidence: number | null;
  evidenceState: EvidenceState;
  sourceImages: string[];
  limitations: string[];
  isPrototype: true;
}

export interface Case {
  id: string;
  scenarioId: ScenarioId;
  title: string;
  status: CaseStatus;
  priority: 'normal' | 'high' | 'urgent';
  vehicleId: string;
  rentalId: string;
  inspectionSessionIds: string[];
  findingIds: string[];
  suggestedAction: string;
  createdAt: string;
  updatedAt: string;
  reviewerId?: string;
  isPrototype: true;
}

export interface ReviewDecision {
  id: string;
  caseId: string;
  findingId: string | null;
  outcome: ReviewOutcome;
  correctedType: FindingType | null;
  correctedSeverity: FindingSeverity | null;
  vehicleStatus: VehicleAvailability;
  reason: string;
  note: string;
  reviewerId: string;
  reviewedAt: string;
  isPrototype: true;
}

export interface Task {
  id: string;
  caseId: string;
  type: TaskType;
  status: TaskStatus;
  title: string;
  location: string;
  etaLabel: string | null;
  priority?: 'normal' | 'high' | 'urgent';
  requiredSkills?: string[];
  requiredTools?: string[];
  reservationRisk?: boolean;
  progressNote?: string;
  isPrototype: true;
}

export interface Worker {
  id: string;
  displayName: string;
  team: string;
  skills: TaskType[];
  currentWorkload?: number;
  etaLabel?: string;
  isPrototype: true;
}

export interface CompletionReview {
  id: string;
  taskId: string;
  zone: InspectionZone;
  originalImage: string;
  completionImage: string;
  sameRegion: boolean;
  result: 'PENDING' | 'PASSED' | 'RETURNED';
  reason: string;
  reviewerId: string | null;
  reviewedAt: string | null;
  isPrototype: true;
}

export interface ReleaseAuthorization {
  id: string;
  caseId: string;
  vehicleId: string;
  reason: string;
  authorizedBy: string;
  authorizedAt: string;
  isPrototype: true;
}

export interface ClaimDecision {
  id: string;
  caseId: string;
  outcome: ClaimOutcome;
  reason: string;
  note: string;
  reviewerId: string;
  reviewedAt: string;
  isPrototype: true;
}

export interface Assignment {
  id: string;
  taskId: string;
  workerId: string;
  assignedAt: string;
  assignedBy: string;
  isPrototype: true;
}

export interface VehicleStatusEvent {
  id: string;
  vehicleId: string;
  from: VehicleAvailability;
  to: VehicleAvailability;
  reason: string;
  occurredAt: string;
  actorId: string;
  isPrototype: true;
}

export interface AuditEvent {
  id: string;
  entityType: 'scenario' | 'case' | 'task' | 'vehicle' | 'claim';
  entityId: string;
  action: string;
  detail: string;
  actorId: string;
  occurredAt: string;
  isPrototype: true;
}

export interface ScenarioDataset {
  schemaVersion: 'prototype-1.0';
  meta: ScenarioMeta;
  vehicles: Vehicle[];
  rentals: Rental[];
  inspectionSessions: InspectionSession[];
  findings: Finding[];
  cases: Case[];
  tasks: Task[];
  workers: Worker[];
  assignments: Assignment[];
  vehicleStatusEvents: VehicleStatusEvent[];
  reviewDecisions: ReviewDecision[];
  completionReviews: CompletionReview[];
  releaseAuthorizations: ReleaseAuthorization[];
  claimDecisions: ClaimDecision[];
  auditEvents: AuditEvent[];
}
