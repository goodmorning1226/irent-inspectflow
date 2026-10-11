"""Generate reproducible synthetic Taipei OR inputs; Python standard library only."""
import json
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = 20261011
rng = random.Random(SEED)
areas = [
    ('中正', '台北車站周邊', 25.0478, 121.5170),
    ('大同', '大橋頭周邊', 25.0632, 121.5120),
    ('萬華', '龍山寺周邊', 25.0353, 121.4998),
    ('中山', '行天宮周邊', 25.0597, 121.5333),
    ('松山', '南京三民周邊', 25.0516, 121.5640),
    ('大安', '信義安和周邊', 25.0330, 121.5527),
    ('信義', '市政府周邊', 25.0410, 121.5658),
    ('士林', '士林站周邊', 25.0934, 121.5263),
    ('北投', '北投站周邊', 25.1318, 121.4986),
    ('內湖', '港墘周邊', 25.0800, 121.5750),
    ('南港', '南港站周邊', 25.0520, 121.6065),
    ('文山', '萬芳醫院周邊', 24.9994, 121.5580),
]
locations = [dict(id=f'LOC-{i+1:02}', district=d, name=f'模擬服務點・{n}',
                  latitude=lat, longitude=lon, is_synthetic=True)
             for i, (d, n, lat, lon) in enumerate(areas)]

def travel(a, b):
    if a['id'] == b['id']:
        return 0
    dy = (a['latitude'] - b['latitude']) * 111.0
    dx = (a['longitude'] - b['longitude']) * 111.0 * math.cos(math.radians(25))
    return math.ceil(math.hypot(dx, dy) * 1.35 / 22 * 60 + 5)

workers = []
profiles = [(['cleaning'], ['cleaning_kit']), (['cleaning'], ['cleaning_kit']),
            (['repair'], ['repair_kit']), (['repair'], ['repair_kit']),
            (['cleaning', 'inspection'], ['cleaning_kit', 'inspection_kit']),
            (['repair', 'inspection'], ['repair_kit', 'inspection_kit'])]
for i, (skills, tools) in enumerate(profiles):
    workers.append(dict(id=f'WRK-{i+1:02}', name=f'模擬員工{i+1:02}', skills=skills,
                        tools=tools, start_location_id=locations[i*2]['id'],
                        end_location_id=locations[i*2]['id'], available_from_minute=0,
                        shift_end_minute=480, break_window=[180, 300],
                        break_duration_minutes=30, transport_mode='service_vehicle',
                        is_synthetic=True))
vehicles, tasks = [], []
for i in range(20):
    vid, tid = f'VEH-{i+1:03}', f'TSK-{i+1:03}'
    loc = locations[i % 12]['id']
    kind = 'repair' if i % 3 == 0 else 'cleaning'
    critical = i in (0, 9)
    duration = rng.choice([45, 60, 75]) if kind == 'repair' else rng.choice([20, 30, 40])
    release = rng.choice([0, 0, 30, 60, 90])
    deadline = min(450, release + rng.choice([90, 150, 210, 300]))
    followup = i in (2, 5, 9, 14)
    inspection_id = f'TSK-{21 + len([v for v in vehicles if len(v["required_task_ids"]) > 1]):03}' if followup else None
    vehicles.append(dict(id=vid, plate_number=f'DEMO-{i+1:04}',
                         model_name=rng.choice(['YARIS', 'COROLLA CROSS', 'VIOS']),
                         location_id=loc, availability='OFFLINE' if critical else 'REVIEW_REQUIRED',
                         safety_blocked=critical, offline_since_minute=-rng.choice([15, 30, 60]),
                         next_reservation_minute=deadline, demand_weight=rng.choice([1, 2, 3]),
                         required_task_ids=[tid] + ([inspection_id] if followup else []),
                         release_requires_human_approval=True, is_synthetic=True))
    tasks.append(dict(id=tid, vehicle_id=vid, location_id=loc, type=kind,
                      finding_type='light_crack' if critical else ('scratch' if kind == 'repair' else 'stain'),
                      priority='urgent' if critical else ('high' if i % 4 == 0 else 'normal'),
                      required_skills=[kind], required_tools=[f'{kind}_kit'],
                      duration_minutes=duration, release_minute=release,
                      deadline_minute=deadline - (15 if followup else 0), deadline_mode='soft',
                      predecessor_task_ids=[], status='PENDING', locked_worker_id=None,
                      locked_start_minute=None, is_synthetic=True))
    if followup:
        tasks.append(dict(id=inspection_id, vehicle_id=vid, location_id=loc, type='inspection',
                          finding_type='completion_review', priority='high',
                          required_skills=['inspection'], required_tools=['inspection_kit'],
                          duration_minutes=15, release_minute=release, deadline_minute=deadline,
                          deadline_mode='soft', predecessor_task_ids=[tid], status='PENDING',
                          locked_worker_id=None, locked_start_minute=None, is_synthetic=True))
tasks.sort(key=lambda t: t['id'])
data = dict(schema_version='or-taipei-1.0', scenario_id='TAIPEI-BASE-001', seed=SEED,
            is_synthetic=True, notice='所有人員、車輛、工時、期限及交通均為假資料；座標為區域示意，非真實服務站。',
            planning=dict(date='2026-10-12', timezone='Asia/Taipei',
                          start_at='2026-10-12T09:00:00+08:00', horizon_minutes=480,
                          time_unit='minute', route_end_policy='return_to_start',
                          repair_policy='on_site_only', break_policy='stationary_at_current_location',
                          reservation_buffer_minutes=0),
            assumptions=dict(travel_model='ceil(straight_line_km * 1.35 / 22 * 60 + 5)',
                             travel_speed_kmh=22, travel_matrix_static=True,
                             travel_matrix_symmetric=True, same_location_travel_minutes=0,
                             tools_non_consumable=True, skills_boolean=True,
                             predicted_readiness_excludes_human_approval_delay=True,
                             actual_release_requires_review=True),
            locations=locations, workers=workers, vehicles=vehicles, tasks=tasks,
            travel_time_matrix=dict(location_ids=[p['id'] for p in locations],
                                    minutes=[[travel(a,b) for b in locations] for a in locations]),
            solver_defaults=dict(time_limit_seconds=30, mip_gap=0.02))

def validate(d):
    ids = lambda rows: {r['id'] for r in rows}
    locs, ws, vs, ts = map(ids, [d['locations'], d['workers'], d['vehicles'], d['tasks']])
    for rows in [d['locations'], d['workers'], d['vehicles'], d['tasks']]:
        assert len(ids(rows)) == len(rows), 'Duplicate ID'
    matrix = d['travel_time_matrix']['minutes']
    assert len(matrix) == len(locs) and all(len(row) == len(locs) for row in matrix)
    assert d['travel_time_matrix']['location_ids'] == [p['id'] for p in d['locations']]
    assert all(matrix[i][i] == 0 for i in range(len(locs)))
    assert all(isinstance(v, int) and v >= 0 for row in matrix for v in row)
    by_id = {t['id']: t for t in d['tasks']}
    def visit(tid, stack):
        assert tid not in stack, 'Dependency cycle'
        for parent in by_id[tid]['predecessor_task_ids']:
            visit(parent, stack | {tid})
    for t in d['tasks']:
        assert t['vehicle_id'] in vs and t['location_id'] in locs
        assert 0 <= t['release_minute'] < t['deadline_minute'] <= 480
        assert t['duration_minutes'] > 0
        assert set(t['predecessor_task_ids']) <= ts
        visit(t['id'], set())
        assert any(set(t['required_skills']) <= set(w['skills']) and
                   set(t['required_tools']) <= set(w['tools']) for w in d['workers'])
    for v in d['vehicles']:
        assert v['location_id'] in locs and set(v['required_task_ids']) <= ts
        assert all(by_id[t]['vehicle_id'] == v['id'] for t in v['required_task_ids'])
    for w in d['workers']:
        assert w['start_location_id'] in locs and w['end_location_id'] in locs
        lo, hi = w['break_window']
        assert w['available_from_minute'] <= lo < hi <= w['shift_end_minute']
        assert hi-lo >= w['break_duration_minutes']
    return dict(locations=len(locs), workers=len(ws), vehicles=len(vs), tasks=len(ts),
                matrix_shape=[len(locs), len(locs)], structural_validation='passed',
                scheduling_feasibility='not_yet_solved',
                task_types={k: sum(t['type']==k for t in d['tasks']) for k in ['cleaning','repair','inspection']})

if __name__ == '__main__':
    summary = validate(data)
    (ROOT/'data').mkdir(exist_ok=True)
    (ROOT/'data/taipei_base.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
    (ROOT/'data/validation_summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps(summary, ensure_ascii=False))
