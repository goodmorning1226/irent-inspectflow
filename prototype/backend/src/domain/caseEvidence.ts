import { getRuntimeScenarioDataset } from '../data/scenarios';
import type {
  Finding,
  FindingSeverity,
  FindingType,
  ScenarioDataset,
  ScenarioId,
} from './types';

export type EvidenceEffect = 'none';

const exteriorClean = '/exterior_clean_best.png';
const damageCenter = '/exterior_damage_detail_center.png';
const damageLeft = '/exterior_damage_detail_left.png';
const damageRight = '/exterior_damage_detail_right.png';
const damageWide = '/exterior_damage_wide.png';
const interiorClean = '/interior_clean_best.png';
const interiorDirty = '/interior_dirty_best.png';
const headlightDamageWide = '/headlight_damage_wide.png';
const headlightDamageDetail = '/headlight_damage_detail.png';
const vehicleFront = '/vehicle_front.png';
const vehicleRear = '/vehicle_rear.png';
const vehicleRightSide = '/vehicle_right_side.png';
const vehicleFrontSeat = '/vehicle_front_seat.png';

export interface EvidenceImage {
  id: string;
  label: string;
  caption: string;
  src: string | null;
  effect: EvidenceEffect;
  sourceLabel: string;
}

export interface EvidencePresentation {
  baseline: EvidenceImage;
  current: EvidenceImage;
  angles: EvidenceImage[];
  comparability: 'comparable' | 'limited' | 'unavailable';
  comparabilityLabel: string;
  comparabilityReason: string;
  conclusion: string;
}

export type InspectionZoneId =
  'front' | 'leftSide' | 'rear' | 'rightSide' | 'frontSeat' | 'rearSeat';

export interface ZoneEvidencePresentation extends EvidencePresentation {
  zoneId: InspectionZoneId;
  zoneLabel: string;
  status: 'normal' | 'attention' | 'unavailable';
  statusLabel: string;
}

export const findingTypeLabels: Record<FindingType, string> = {
  scratch: '刮痕',
  dent: '凹陷',
  crack: '破裂',
  stain: '污漬',
  litter: '垃圾',
  leftItem: '遺留物',
  obstruction: '遮蔽',
  unknown: '待確認',
};

export function formatFindingType(finding: Finding): string {
  if (['stain', 'litter', 'leftItem', 'obstruction'].includes(finding.type)) {
    return ['frontSeat', 'rearSeat'].includes(finding.zone)
      ? '車內髒污'
      : '車外髒污';
  }
  return findingTypeLabels[finding.type];
}

export const severityLabels: Record<FindingSeverity, string> = {
  low: '輕微',
  medium: '中等',
  high: '嚴重',
  unknown: '無法分級',
};

const commonBefore: EvidenceImage = {
  id: 'before-left',
  label: '本次取車前',
  caption: '同車左側車身，本次租程取車前掃描影像',
  src: exteriorClean,
  effect: 'none',
  sourceLabel: '本次租程・取車前掃描',
};

const presentations: Partial<Record<ScenarioId, EvidencePresentation>> = {
  S02: {
    baseline: {
      id: 'before-interior-missing',
      label: '本次取車前',
      caption: '本案例未提供可比的本次取車前後座近照',
      src: null,
      effect: 'none',
      sourceLabel: '基準缺少',
    },
    current: {
      id: 'after-interior',
      label: '還車後影像',
      caption: '後座右側座墊可見飲料污漬',
      src: interiorDirty,
      effect: 'none',
      sourceLabel: 'INS-DEMO-001・rearSeat',
    },
    angles: [],
    comparability: 'limited',
    comparabilityLabel: '可判讀，但取車前近照有限',
    comparabilityReason: '本次污漬清楚可見；責任與費用仍需人員依規範確認。',
    conclusion: '建議建立清潔任務，完工後對同一座墊重新掃描。',
  },
  S03: {
    baseline: commonBefore,
    current: {
      id: 'after-wide',
      label: '還車後影像',
      caption: '左後車門下半部出現疑似刮痕',
      src: damageWide,
      effect: 'none',
      sourceLabel: 'INS-DEMO-001・leftSide',
    },
    angles: [
      {
        id: 'detail-center',
        label: '中央視角',
        caption: '正面近距離補掃',
        src: damageCenter,
        effect: 'none',
        sourceLabel: '補掃 1／3',
      },
      {
        id: 'detail-left',
        label: '左側視角',
        caption: '由左側確認痕跡持續存在',
        src: damageLeft,
        effect: 'none',
        sourceLabel: '補掃 2／3',
      },
      {
        id: 'detail-right',
        label: '右側視角',
        caption: '由右側確認痕跡持續存在',
        src: damageRight,
        effect: 'none',
        sourceLabel: '補掃 3／3',
      },
    ],
    comparability: 'comparable',
    comparabilityLabel: '視角可比',
    comparabilityReason:
      '車號、區域及主要車門輪廓一致，尺度與角度可進行差異覆核。',
    conclusion: '多角度都能看到相同痕跡，建議人工確認既有車損紀錄與時間關係。',
  },
  S04: {
    baseline: commonBefore,
    current: {
      id: 'minor-scratch-wide',
      label: '還車後影像',
      caption: '左前車門下半部出現疑似細微刮痕',
      src: damageWide,
      effect: 'none',
      sourceLabel: 'INS-DEMO-001・leftSide',
    },
    angles: [
      {
        id: 'minor-scratch-center',
        label: '中央視角',
        caption: '近距離影像可見細微表面痕跡',
        src: damageCenter,
        effect: 'none',
        sourceLabel: '補掃 1／2',
      },
      {
        id: 'minor-scratch-left',
        label: '左側視角',
        caption: '換角度後痕跡仍位於相同車身位置',
        src: damageLeft,
        effect: 'none',
        sourceLabel: '補掃 2／2',
      },
    ],
    comparability: 'comparable',
    comparabilityLabel: '視角可比',
    comparabilityReason:
      '影像已通過成像品質門檻，車門輪廓與取車前基準可比；細微痕跡仍需人工確認。',
    conclusion:
      '多角度都能看到相同位置的細微痕跡，建議人工確認是否為新增刮痕。',
  },
  S05: {
    baseline: {
      id: 'baseline-unavailable',
      label: '本次取車前',
      caption: '找不到本次取車前或上次還車的同區域可比影像',
      src: null,
      effect: 'none',
      sourceLabel: '證據不足',
    },
    current: {
      id: 'current-right-side',
      label: '還車後影像',
      caption: '本次影像品質合格；畫面以 Prototype 車側素材示意',
      src: exteriorClean,
      effect: 'none',
      sourceLabel: 'INS-DEMO-001・rightSide 示意',
    },
    angles: [],
    comparability: 'unavailable',
    comparabilityLabel: '無法比較',
    comparabilityReason:
      '缺少本次取車前與上次還車的同區域有效基準，因此不能判斷異常是否為本次新增。',
    conclusion: '只能標示證據不足並安排補件或現場巡檢，不進入索賠判斷。',
  },
  S07: {
    baseline: {
      id: 'before-front',
      label: '本次取車前',
      caption: '同車車頭，本次租程取車前掃描影像',
      src: vehicleFront,
      effect: 'none',
      sourceLabel: '本次租程・取車前掃描',
    },
    current: {
      id: 'headlight-damage-wide',
      label: '還車後影像',
      caption: '左前車燈燈罩出現放射狀裂紋與缺角',
      src: headlightDamageWide,
      effect: 'none',
      sourceLabel: 'INS-DEMO-001・front',
    },
    angles: [
      {
        id: 'headlight-damage-detail',
        label: '車燈近照',
        caption: '近距離影像清楚記錄燈罩裂紋與缺損位置',
        src: headlightDamageDetail,
        effect: 'none',
        sourceLabel: '安全異常補充證據',
      },
    ],
    comparability: 'comparable',
    comparabilityLabel: '區域可比',
    comparabilityReason:
      '車頭廣角影像可確認破裂位置，近距離補充影像則清楚呈現燈罩裂紋與缺損。',
    conclusion: '車燈破裂可能影響照明與防水，建議維持下線並優先安排維修。',
  },
};

const fallbackPresentation: EvidencePresentation = {
  baseline: commonBefore,
  current: {
    id: 'current-generic',
    label: '還車後影像',
    caption: '目前案例的同區域車況影像',
    src: exteriorClean,
    effect: 'none',
    sourceLabel: 'Prototype 示意素材',
  },
  angles: [],
  comparability: 'limited',
  comparabilityLabel: '概念展示',
  comparabilityReason: '此案例尚未配置專用證據素材，僅顯示資料結構與工作流程。',
  conclusion: '依案件建議交由授權人員確認後續處置。',
};

const zoneDefinitions: Array<{
  id: InspectionZoneId;
  label: string;
  src: string;
}> = [
  { id: 'front', label: '車頭', src: vehicleFront },
  { id: 'leftSide', label: '左側', src: exteriorClean },
  { id: 'rear', label: '車尾', src: vehicleRear },
  { id: 'rightSide', label: '右側', src: vehicleRightSide },
  { id: 'frontSeat', label: '前座', src: vehicleFrontSeat },
  { id: 'rearSeat', label: '後座', src: interiorClean },
];

function getFocusZone(
  scenarioId: ScenarioId,
  finding?: Finding,
): InspectionZoneId {
  if (finding) return finding.zone;
  if (scenarioId === 'S02') return 'rearSeat';
  if (scenarioId === 'S05') return 'rightSide';
  if (scenarioId === 'S01' || scenarioId === 'S07') return 'front';
  return 'leftSide';
}

function buildZoneEvidence(
  scenarioId: ScenarioId,
  focusPresentation: EvidencePresentation,
  hasFinding: boolean,
  focusZone: InspectionZoneId,
): ZoneEvidencePresentation[] {
  return zoneDefinitions.map((zone) => {
    if (zone.id === focusZone) {
      return {
        ...focusPresentation,
        zoneId: zone.id,
        zoneLabel: zone.label,
        status:
          focusPresentation.comparability === 'unavailable'
            ? 'unavailable'
            : hasFinding
              ? 'attention'
              : 'normal',
        statusLabel:
          focusPresentation.comparability === 'unavailable'
            ? '證據不足'
            : hasFinding
              ? '發現異常'
              : '影像正常',
      };
    }

    const baseline: EvidenceImage = {
      id: `${scenarioId}-${zone.id}-before`,
      label: '本次取車前',
      caption: `${zone.label}在本次租程取車前的掃描影像`,
      src: zone.src,
      effect: 'none',
      sourceLabel: '本次租程・取車前掃描',
    };
    const current: EvidenceImage = {
      id: `${scenarioId}-${zone.id}-after`,
      label: '還車後影像',
      caption: `${zone.label}本次掃描影像`,
      src: zone.src,
      effect: 'none',
      sourceLabel: `INS-DEMO-001・${zone.id}`,
    };

    return {
      zoneId: zone.id,
      zoneLabel: zone.label,
      status: 'normal',
      statusLabel: '影像正常',
      baseline,
      current,
      angles: [],
      comparability: 'comparable',
      comparabilityLabel: '視角可比',
      comparabilityReason: `${zone.label}的本次取車前掃描與還車後影像均已留存，可供人工快速確認；上次還車影像可作為補充基準。`,
      conclusion: `${zone.label}未發現需要另外處理的明顯異常。`,
    };
  });
}

export interface CaseWorkspace {
  dataset: ScenarioDataset;
  currentCase: ScenarioDataset['cases'][number];
  vehicle: ScenarioDataset['vehicles'][number];
  rental: ScenarioDataset['rentals'][number];
  findings: Finding[];
  presentation: EvidencePresentation;
  zoneEvidence: ZoneEvidencePresentation[];
  defaultZoneId: InspectionZoneId;
}

export function buildCaseWorkspace(
  caseId: string,
  activeDataset: ScenarioDataset,
): CaseWorkspace | null {
  const scenarioId = caseId.match(/^CASE-(S0[1-7])-/)?.[1] as
    ScenarioId | undefined;
  if (!scenarioId) return null;
  const dataset =
    activeDataset.meta.id === scenarioId
      ? activeDataset
      : getRuntimeScenarioDataset(scenarioId);
  const currentCase = dataset.cases.find((item) => item.id === caseId);
  if (!currentCase) return null;
  const vehicle = dataset.vehicles.find(
    (item) => item.id === currentCase.vehicleId,
  );
  const rental = dataset.rentals.find(
    (item) => item.id === currentCase.rentalId,
  );
  if (!vehicle || !rental) return null;
  const findings = dataset.findings.filter((item) =>
    currentCase.findingIds.includes(item.id),
  );
  const primaryFinding = findings[0];
  const presentation =
    presentations[scenarioId] ??
    (primaryFinding &&
    ['stain', 'litter', 'leftItem', 'obstruction'].includes(primaryFinding.type)
      ? presentations.S02
      : primaryFinding &&
          ['scratch', 'dent', 'crack'].includes(primaryFinding.type)
        ? presentations.S03
        : primaryFinding?.type === 'unknown'
          ? presentations.S05
          : undefined) ??
    fallbackPresentation;
  const focusZone = getFocusZone(scenarioId, primaryFinding);
  return {
    dataset,
    currentCase,
    vehicle,
    rental,
    findings,
    presentation,
    zoneEvidence: buildZoneEvidence(
      scenarioId,
      presentation,
      findings.length > 0,
      focusZone,
    ),
    defaultZoneId: focusZone,
  };
}

export function formatFullDateTime(value: string) {
  return new Intl.DateTimeFormat('zh-TW', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(new Date(value));
}
