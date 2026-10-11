"""Stage A: priority ordering and nearest eligible worker recommendations."""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRIORITY = {'urgent': 0, 'high': 1, 'normal': 2}


def distance_km(a, b):
    """Great-circle distance from latitude/longitude, in kilometers."""
    lat1, lon1, lat2, lon2 = map(math.radians, (
        a['latitude'], a['longitude'], b['latitude'], b['longitude']))
    h = math.sin((lat2-lat1)/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin((lon2-lon1)/2)**2
    return 6371.0088 * 2 * math.asin(math.sqrt(min(1.0, max(0.0, h))))


def recommend(data):
    """Independent recommendations from fixed worker origins; no assignments applied."""
    def index(rows):
        result = {r['id']: r for r in rows}
        if len(result) != len(rows):
            raise ValueError('Duplicate IDs')
        return result
    locations = index(data['locations'])
    tasks = index(data['tasks'])
    workers = index(data['workers'])
    for loc in locations.values():
        if not (-90 <= loc['latitude'] <= 90 and -180 <= loc['longitude'] <= 180):
            raise ValueError('Invalid coordinates')
    for worker in workers.values():
        if worker['start_location_id'] not in locations:
            raise ValueError('Unknown worker location')
    for task in tasks.values():
        if task['location_id'] not in locations or task['priority'] not in PRIORITY:
            raise ValueError('Invalid task location or priority')
        if any(p not in tasks for p in task['predecessor_task_ids']):
            raise ValueError('Unknown predecessor')
    ordered = sorted(tasks.values(), key=lambda t: (
        PRIORITY[t['priority']], t['deadline_minute'], t['release_minute'], t['id']))
    rows = []
    for rank, task in enumerate(ordered, 1):
        candidates = []
        for worker in workers.values():
            if (set(task['required_skills']) <= set(worker['skills']) and
                    set(task['required_tools']) <= set(worker['tools'])):
                distance = distance_km(locations[worker['start_location_id']], locations[task['location_id']])
                candidates.append(dict(worker_id=worker['id'], worker_name=worker['name'],
                                       origin_location_id=worker['start_location_id'],
                                       distance_km=distance))
        candidates.sort(key=lambda c: (c['distance_km'], c['worker_id']))
        # Sort at full precision; round only the presentation values.
        for c in candidates:
            c['distance_km'] = round(c['distance_km'], 3)
        blocked = [p for p in task['predecessor_task_ids'] if tasks[p]['status'] != 'COMPLETED']
        if task['status'] != 'PENDING':
            state, reason = 'SKIPPED', '任務不是待派狀態'
        elif task.get('locked_worker_id') or task.get('locked_start_minute') is not None:
            state, reason = 'SKIPPED', '任務已有人工鎖定，保留原安排'
        elif blocked:
            state, reason = 'WAITING_PREDECESSOR', '前置任務尚未完成，暫不推薦派工'
        elif not candidates:
            state, reason = 'NO_ELIGIBLE_WORKER', '沒有同時具備所需技能與工具的人員'
        else:
            state, reason = 'RECOMMENDED', '依固定出發座標，推薦直線距離最近的合格人員'
        rows.append(dict(rank=rank, task_id=task['id'], vehicle_id=task['vehicle_id'],
                         type=task['type'], priority=task['priority'],
                         location_id=task['location_id'], district=locations[task['location_id']]['district'],
                         release_minute=task['release_minute'], deadline_minute=task['deadline_minute'],
                         state=state, reason=reason, blocked_by=blocked,
                         recommended_worker_id=candidates[0]['worker_id'] if state == 'RECOMMENDED' else None,
                         distance_km=candidates[0]['distance_km'] if state == 'RECOMMENDED' else None,
                         candidates=candidates))
    return dict(stage='A', scenario_id=data['scenario_id'], is_synthetic=True,
                policy='priority_then_deadline; independent_nearest_eligible_worker',
                distance_method='haversine', distance_unit='km',
                notice='僅為獨立派工建議，未套用指派。人員位置不隨推薦更新；未檢查班次容量、時間衝突、休息或交通，非可執行排程。release_minute 為最早可處理時間，本階段不判斷是否已到該時間。',
                summary=dict(total_tasks=len(rows), **{s.lower(): sum(r['state']==s for r in rows)
                    for s in ['RECOMMENDED', 'WAITING_PREDECESSOR', 'NO_ELIGIBLE_WORKER', 'SKIPPED']}),
                recommendations=rows)


def report(result):
    lines = ['# A 階段：座標距離派工建議', '', result['notice'], '',
             '排序：urgent → high → normal；同級依期限、最早開始時間與 ID。', '',
             '| 排序 | 任務 | 區域 | 優先度 | 推薦人員 | 直線公里 | 狀態 |',
             '|---|---|---|---|---|---|---|']
    for r in result['recommendations']:
        lines.append(f"| {r['rank']} | {r['task_id']} | {r['district']} | {r['priority']} | {r['recommended_worker_id'] or '—'} | {r['distance_km'] if r['distance_km'] is not None else '—'} | {r['state']} |")
    lines += ['', '同一人可被多件任務推薦；這些建議不能直接當成同時可執行的工作表。',
              '距離是座標間的大圓距離，未使用資料中的交通矩陣，也未換算到場時間。', '']
    return '\n'.join(lines)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=ROOT/'data/taipei_base.json')
    parser.add_argument('--output-dir', type=Path, default=ROOT/'output')
    args = parser.parse_args()
    result = recommend(json.loads(args.input.read_text()))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir/'stage_a_recommendations.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    (args.output_dir/'stage_a_report.md').write_text(report(result))
    print(json.dumps(result['summary'], ensure_ascii=False))
