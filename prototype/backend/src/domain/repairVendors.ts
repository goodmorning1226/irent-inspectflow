export interface RepairVendor {
  id: string;
  name: string;
  serviceArea: string;
  capability: string;
  intakeLabel: string;
}

export const repairVendors: RepairVendor[] = [
  {
    id: 'VENDOR-TAIPEI-XINYI',
    name: '信義合作保修廠',
    serviceArea: '台北・新北',
    capability: '車燈、鈑金與烤漆',
    intakeLabel: '今日可進場',
  },
  {
    id: 'VENDOR-TAOYUAN-ZHONGLI',
    name: '中壢合作保修廠',
    serviceArea: '桃園',
    capability: '鈑金與車體修復',
    intakeLabel: '約 2 小時可收車',
  },
  {
    id: 'VENDOR-TAICHUNG-XITUN',
    name: '西屯合作保修廠',
    serviceArea: '台中・彰化',
    capability: '鈑金、烤漆與零件更換',
    intakeLabel: '今日 16:30 可進場',
  },
  {
    id: 'VENDOR-SOUTH',
    name: '南區合作保修廠',
    serviceArea: '台南・高雄',
    capability: '保桿、鈑金與烤漆',
    intakeLabel: '當班可收車',
  },
  {
    id: 'VENDOR-HUALIEN',
    name: '花蓮合作保修廠',
    serviceArea: '花蓮',
    capability: '車體修復與完工檢查',
    intakeLabel: '已通知完工',
  },
];

const cityVendorMap: Array<[string, string]> = [
  ['桃園', 'VENDOR-TAOYUAN-ZHONGLI'],
  ['台中', 'VENDOR-TAICHUNG-XITUN'],
  ['台南', 'VENDOR-SOUTH'],
  ['高雄', 'VENDOR-SOUTH'],
  ['花蓮', 'VENDOR-HUALIEN'],
  ['台北', 'VENDOR-TAIPEI-XINYI'],
  ['新北', 'VENDOR-TAIPEI-XINYI'],
];

export function getRepairVendor(vendorId: string | undefined) {
  return repairVendors.find((vendor) => vendor.id === vendorId);
}

export function getRepairVendorSuggestions(location: string) {
  const recommendedId = cityVendorMap.find(([city]) =>
    location.includes(city),
  )?.[1];
  const recommended = getRepairVendor(recommendedId);
  const alternatives = repairVendors.filter(
    (vendor) => vendor.id !== recommended?.id,
  );
  return recommended
    ? [recommended, ...alternatives].slice(0, 3)
    : alternatives.slice(0, 3);
}
