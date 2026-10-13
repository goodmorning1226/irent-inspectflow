import type {
  Case,
  Finding,
  FindingType,
  InspectionSession,
  InspectionZone,
  Rental,
  ScenarioDataset,
  Task,
  Vehicle,
} from '../domain/types';

interface DemoRecordDefinition {
  plateNumber: string;
  modelName: string;
  colorName: string;
  availability: Vehicle['availability'];
  cleanliness?: Vehicle['cleanliness'];
  location: string;
  title: string;
  status: Case['status'];
  priority: Case['priority'];
  finding?: {
    type: FindingType;
    zone: InspectionZone;
    location: string;
    severity: Finding['severity'];
    possiblyNew: boolean;
  };
  tasks?: Array<{
    suffix: string;
    type: Task['type'];
    status: Task['status'];
    title: string;
    progressNote: string;
    workerId?: string;
    repairVendorId?: string;
  }>;
}

const definitions: DemoRecordDefinition[] = [
  {
    plateNumber: 'KBC-2186',
    modelName: 'TOYOTA YARIS CROSS',
    colorName: '雲河灰',
    availability: 'READY',
    cleanliness: 'normal',
    location: '台北市松山區・民生停車場',
    title: '車況正常',
    status: 'RESOLVED',
    priority: 'normal',
  },
  {
    plateNumber: 'RDF-5092',
    modelName: 'TOYOTA YARIS',
    colorName: '極光銀',
    availability: 'CLEANING',
    location: '台北市信義區・市府停車場',
    title: '後座飲料污漬',
    status: 'PENDING_CLEANING',
    priority: 'high',
    finding: {
      type: 'stain',
      zone: 'rearSeat',
      location: '後座右側座墊',
      severity: 'medium',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'CLEAN-001',
        type: 'cleaning',
        status: 'ASSIGNED',
        title: '清潔後座右側座墊',
        progressNote: '已指派，等待到場',
        workerId: 'WRK-DEMO-CLEAN-01',
      },
    ],
  },
  {
    plateNumber: 'TQH-7315',
    modelName: 'TOYOTA VIOS',
    colorName: '雪貂白',
    availability: 'CLEANING',
    location: '新北市板橋區・縣民停車場',
    title: '前座垃圾與遺留物',
    status: 'PENDING_CLEANING',
    priority: 'urgent',
    finding: {
      type: 'litter',
      zone: 'frontSeat',
      location: '前座乘客腳踏區',
      severity: 'medium',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'CLEAN-002',
        type: 'cleaning',
        status: 'IN_PROGRESS',
        title: '清除前座垃圾與遺留物',
        progressNote: '現場整備中・不可改派',
        workerId: 'WRK-DEMO-CLEAN-02',
      },
    ],
  },
  {
    plateNumber: 'LME-4428',
    modelName: 'TOYOTA COROLLA CROSS',
    colorName: '炫魅紅',
    availability: 'MAINTENANCE',
    location: '桃園市中壢區・中央停車場',
    title: '右後車門新增刮痕',
    status: 'PENDING_REPAIR',
    priority: 'high',
    finding: {
      type: 'scratch',
      zone: 'rightSide',
      location: '右後車門下半部',
      severity: 'medium',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'REPAIR-001',
        type: 'repair',
        status: 'PENDING',
        title: '安排右後車門送修',
        progressNote: '待指定保修廠與調度方式',
      },
    ],
  },
  {
    plateNumber: 'PZA-8063',
    modelName: 'TOYOTA ALTIS',
    colorName: '星河藍',
    availability: 'MAINTENANCE',
    location: '台中市西屯區・朝馬停車場',
    title: '左前葉子板凹陷',
    status: 'PENDING_REPAIR',
    priority: 'high',
    finding: {
      type: 'dent',
      zone: 'leftSide',
      location: '左前葉子板',
      severity: 'medium',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'REPAIR-002',
        type: 'repair',
        status: 'ASSIGNED',
        title: '調度至台中指定保修廠',
        progressNote: '待移車・已指定台中原廠',
        repairVendorId: 'VENDOR-TAICHUNG-XITUN',
      },
    ],
  },
  {
    plateNumber: 'HKT-3691',
    modelName: 'TOYOTA SIENTA',
    colorName: '珍珠白',
    availability: 'MAINTENANCE',
    location: '台南市中西區・海安停車場',
    title: '後保桿破裂',
    status: 'PENDING_REPAIR',
    priority: 'urgent',
    finding: {
      type: 'crack',
      zone: 'rear',
      location: '後保桿右側',
      severity: 'high',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'REPAIR-003',
        type: 'repair',
        status: 'IN_PROGRESS',
        title: '後保桿原廠修護',
        progressNote: '維修中・台南指定保修廠',
        repairVendorId: 'VENDOR-SOUTH',
      },
    ],
  },
  {
    plateNumber: 'NVR-6240',
    modelName: 'TOYOTA YARIS CROSS',
    colorName: '極光銀',
    availability: 'MAINTENANCE',
    location: '高雄市前鎮區・中山停車場',
    title: '右側車門烤漆修復',
    status: 'PENDING_REPAIR',
    priority: 'normal',
    finding: {
      type: 'scratch',
      zone: 'rightSide',
      location: '右前車門',
      severity: 'low',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'REPAIR-004',
        type: 'repair',
        status: 'WAITING_REVIEW',
        title: '右側車門完工取回',
        progressNote: '待取回・保修廠已通知完工',
        repairVendorId: 'VENDOR-SOUTH',
      },
    ],
  },
  {
    plateNumber: 'GSD-1574',
    modelName: 'TOYOTA ALTIS',
    colorName: '雲河灰',
    availability: 'REINSPECTION_REQUIRED',
    location: '花蓮縣花蓮市・站前停車場',
    title: '左後車門凹陷修復完成',
    status: 'PENDING_REPAIR',
    priority: 'normal',
    finding: {
      type: 'dent',
      zone: 'leftSide',
      location: '左後車門',
      severity: 'medium',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'REPAIR-005',
        type: 'repair',
        status: 'WAITING_REVIEW',
        title: '左後車門完工複檢',
        progressNote: '待複檢・車輛已回到營運據點',
        repairVendorId: 'VENDOR-HUALIEN',
      },
    ],
  },
  {
    plateNumber: 'WUJ-9306',
    modelName: 'TOYOTA COROLLA CROSS',
    colorName: '珍珠白',
    availability: 'MAINTENANCE',
    location: '新北市新店區・區公所停車場',
    title: '左後車門疑似新增刮痕',
    status: 'CLAIM_REVIEW',
    priority: 'high',
    finding: {
      type: 'scratch',
      zone: 'leftSide',
      location: '左後車門下半部',
      severity: 'medium',
      possiblyNew: true,
    },
    tasks: [
      {
        suffix: 'REPAIR-006',
        type: 'repair',
        status: 'ASSIGNED',
        title: '調度至新店指定保修廠',
        progressNote: '待移車・索賠流程同步進行',
        repairVendorId: 'VENDOR-TAIPEI-XINYI',
      },
      {
        suffix: 'CLAIM-001',
        type: 'claim_review',
        status: 'PENDING',
        title: '左後車門刮痕索賠處理',
        progressNote: '證據包已建立',
      },
    ],
  },
  {
    plateNumber: 'EBA-2847',
    modelName: 'TOYOTA VIOS',
    colorName: '星河藍',
    availability: 'RENTED',
    cleanliness: 'normal',
    location: '台北市大安區・科技大樓站',
    title: '租借進行中',
    status: 'RESOLVED',
    priority: 'normal',
  },
  {
    plateNumber: 'MDU-4518',
    modelName: 'TOYOTA COROLLA CROSS',
    colorName: '珍珠白',
    availability: 'READY',
    cleanliness: 'normal',
    location: '桃園市桃園區・藝文停車場',
    title: '車況正常',
    status: 'RESOLVED',
    priority: 'normal',
  },
  {
    plateNumber: 'QLK-6723',
    modelName: 'TOYOTA YARIS CROSS',
    colorName: '極光銀',
    availability: 'RENTED',
    cleanliness: 'clean',
    location: '新竹市東區・公道五停車場',
    title: '租借進行中',
    status: 'RESOLVED',
    priority: 'normal',
  },
  {
    plateNumber: 'VCN-3085',
    modelName: 'TOYOTA VIOS',
    colorName: '雪貂白',
    availability: 'READY',
    cleanliness: 'normal',
    location: '台中市北屯區・捷運總站停車場',
    title: '車況正常',
    status: 'RESOLVED',
    priority: 'normal',
  },
  {
    plateNumber: 'BXF-9142',
    modelName: 'TOYOTA ALTIS',
    colorName: '雲河灰',
    availability: 'READY',
    cleanliness: 'clean',
    location: '高雄市左營區・高鐵站停車場',
    title: '車況正常',
    status: 'RESOLVED',
    priority: 'normal',
  },
  {
    plateNumber: 'YTR-5609',
    modelName: 'TOYOTA SIENTA',
    colorName: '珍珠白',
    availability: 'RENTED',
    cleanliness: 'clean',
    location: '台南市東區・文化中心停車場',
    title: '租借進行中',
    status: 'RESOLVED',
    priority: 'normal',
  },
];

export function appendOperationsDemo(source: ScenarioDataset): ScenarioDataset {
  const dataset = structuredClone(source);
  const baseTime = Date.parse('2026-10-13T09:00:00+08:00');

  dataset.workers.push(
    {
      id: 'WRK-DEMO-CLEAN-01',
      displayName: '林佳蓉',
      team: '台北現場整備組',
      skills: ['cleaning'],
      currentWorkload: 2,
      etaLabel: '約 20 分鐘可到場',
      isPrototype: true,
    },
    {
      id: 'WRK-DEMO-CLEAN-02',
      displayName: '吳承恩',
      team: '新北現場整備組',
      skills: ['cleaning'],
      currentWorkload: 1,
      etaLabel: '目前處理中',
      isPrototype: true,
    },
  );

  definitions.forEach((definition, index) => {
    const number = String(index + 1).padStart(3, '0');
    const vehicleId = `VEH-S01-OPS-${number}`;
    const rentalId = `RNT-S01-OPS-${number}`;
    const inspectionId = `INS-S01-OPS-${number}`;
    const caseId = `CASE-S01-OPS-${number}`;
    const occurredAt = new Date(baseTime + index * 12 * 60_000).toISOString();
    const pickupAt = new Date(baseTime - (index + 2) * 3_600_000).toISOString();
    const zone = definition.finding?.zone ?? 'front';

    dataset.vehicles.push({
      id: vehicleId,
      plateNumber: definition.plateNumber,
      modelName: definition.modelName,
      colorName: definition.colorName,
      availability: definition.availability,
      cleanliness: definition.cleanliness,
    });

    const rental: Rental = {
      id: rentalId,
      vehicleId,
      memberIdMasked: `MBR-****-${String(3200 + index)}`,
      pickupAt,
      pickupLocation: definition.location,
      returnAt: occurredAt,
      returnLocation: definition.location,
    };
    dataset.rentals.push(rental);

    const inspection: InspectionSession = {
      id: inspectionId,
      rentalId,
      vehicleId,
      type: 'return',
      capturedAt: occurredAt,
      zoneCaptures: [
        {
          zone,
          capturedAt: occurredAt,
          qualitySummary: '位置、清晰度與曝光均符合標準',
          sourceImages: [
            definition.finding?.type === 'stain' ||
            definition.finding?.type === 'litter'
              ? 'prototype/mobile/assets/frames/interior_dirty_best.png'
              : 'prototype/mobile/assets/frames/exterior_damage_wide.png',
          ],
        },
      ],
      isPrototype: true,
    };
    dataset.inspectionSessions.push(inspection);

    const findingId = definition.finding ? `FND-S01-OPS-${number}` : undefined;
    if (definition.finding && findingId) {
      dataset.findings.push({
        id: findingId,
        inspectionSessionId: inspectionId,
        location: definition.finding.location,
        zone: definition.finding.zone,
        type: definition.finding.type,
        severity: definition.finding.severity,
        possiblyNew: definition.finding.possiblyNew,
        confidence: 0.86 + index * 0.01,
        evidenceState: 'sufficient',
        sourceImages: inspection.zoneCaptures[0].sourceImages,
        limitations: ['Prototype 固定示範資料，未執行正式模型推論。'],
        isPrototype: true,
      });
    }

    dataset.cases.push({
      id: caseId,
      scenarioId: 'S01',
      title: definition.title,
      status: definition.status,
      priority: definition.priority,
      vehicleId,
      rentalId,
      inspectionSessionIds: [inspectionId],
      findingIds: findingId ? [findingId] : [],
      suggestedAction:
        definition.status === 'RESOLVED'
          ? '目前不需建立車務任務。'
          : definition.status === 'PENDING_CLEANING'
            ? '建立現場整備任務，完成後回傳同區域影像。'
            : definition.status === 'CLAIM_REVIEW'
              ? '送修與索賠流程並行，避免等待歸責而延誤車輛處理。'
              : '安排車輛移至指定保修廠，完工後回到原區域複檢。',
      createdAt: occurredAt,
      updatedAt: occurredAt,
      reviewerId: definition.status === 'RESOLVED' ? undefined : 'USR-OPS-001',
      isPrototype: true,
    });

    definition.tasks?.forEach((taskDefinition, taskIndex) => {
      const taskId = `TSK-S01-OPS-${taskDefinition.suffix}`;
      dataset.tasks.push({
        id: taskId,
        caseId,
        type: taskDefinition.type,
        status: taskDefinition.status,
        title: taskDefinition.title,
        location: definition.location,
        etaLabel:
          definition.priority === 'urgent'
            ? '展示 ETA：急迫'
            : definition.priority === 'high'
              ? '展示 ETA：常件'
              : '展示 ETA：緩件',
        priority: definition.priority,
        requiredSkills: [taskDefinition.type],
        requiredTools:
          taskDefinition.type === 'cleaning'
            ? ['內裝清潔組', '完工掃描手機']
            : taskDefinition.type === 'repair'
              ? ['車輛調度', '保修廠聯繫']
              : [],
        reservationRisk: definition.priority !== 'normal',
        progressNote: taskDefinition.progressNote,
        repairVendorId: taskDefinition.repairVendorId,
        isPrototype: true,
      });
      if (taskDefinition.workerId) {
        dataset.assignments.push({
          id: `ASN-S01-OPS-${number}-${taskIndex + 1}`,
          taskId,
          workerId: taskDefinition.workerId,
          assignedAt: occurredAt,
          assignedBy: 'USR-OPS-001',
          isPrototype: true,
        });
      }
    });
  });

  return dataset;
}
