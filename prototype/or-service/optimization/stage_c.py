"""Stage C: time-aware assignment, closed routes, precedence and stationary breaks."""
import argparse
import hashlib
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from optimization.stage_b_travel import build_model as build_routes, validate_routes


def build_model(data,env=None):
    import gurobipy as gp
    # Do not silently overestimate capacity when an input already contains reserved work.
    if any(t['status'] not in ('PENDING','COMPLETED') or t.get('locked_worker_id') or
           t.get('locked_start_minute') is not None for t in data['tasks']):
        raise ValueError('Stage C currently requires a fresh shift without locked or in-progress work')
    m,x,u,y,p=build_routes(data,env)
    H=data['planning']['horizon_minutes']
    s=m.addVars(list(p['tasks']),lb=0,ub=H,name='start')
    c=m.addVars(list(p['tasks']),lb=0,ub=H,name='finish')
    late=m.addVars(list(p['tasks']),lb=0,ub=H,name='late')
    beta=m.addVars(list(p['workers']),lb=0,ub=H,name='break_start')
    z=m.addVars(p['arcs'],vtype=gp.GRB.BINARY,name='break_arc')
    returned=m.addVars(list(p['workers']),lb=0,ub=H,name='return_time')
    for i,t in p['tasks'].items():
        m.addConstr(s[i]<=H*(1-u[i]))
        m.addConstr(c[i]==s[i]+t['duration_minutes']*(1-u[i]))
        m.addConstr(late[i]<=H*(1-u[i]))
        m.addConstr((u[i]==0)>>(s[i]>=t['release_minute']))
        m.addConstr((u[i]==0)>>(late[i]>=c[i]-t['deadline_minute']))
        for parent in t['predecessor_task_ids']:
            if parent in p['tasks']:
                m.addConstr((u[i]==0)>>(s[i]>=c[parent]))
    for i,k in p['eligible']:
        m.addConstr((x[i,k]==1)>>(s[i]>=p['workers'][k]['available_from_minute']))
        m.addConstr((x[i,k]==1)>>(c[i]<=p['workers'][k]['shift_end_minute']))
    for k,w in p['workers'].items():
        lo,hi=w['break_window'];duration=w['break_duration_minutes']
        if not (w['available_from_minute']<=lo<=hi<=w['shift_end_minute'] and hi-lo>=duration):
            raise ValueError('Break window does not fit shift')
        m.addConstr(beta[k]>=lo);m.addConstr(beta[k]+duration<=hi)
        m.addConstr(returned[k]>=w['available_from_minute'])
        m.addConstr(returned[k]<=w['shift_end_minute'])
        active=m.getVarByName(f'route_used[{k}]')
        m.addConstr(gp.quicksum(z[a] for a in p['arcs'] if a[2]==k)==active)
        for i,j,wid in p['arcs']:
            if wid!=k:continue
            a=(i,j,k);tau=p['distances'][a]/p['speed']*60
            departure=c[i] if i in p['tasks'] else w['available_from_minute']
            target=s[j] if j in p['tasks'] else returned[k]
            m.addConstr(z[a]<=y[a])
            m.addConstr((y[a]==1)>>(target>=departure+tau))
            m.addConstr((z[a]==1)>>(beta[k]>=departure))
            m.addConstr((z[a]==1)>>(target>=beta[k]+duration+tau))
    weights={'normal':1,'high':3,'urgent':10}
    m.setObjectiveN(gp.quicksum(weights[t['priority']]*late[i] for i,t in p['tasks'].items()),3,
                    priority=15,abstol=0,reltol=0,name='weighted_lateness_minutes')
    max_util=m.addVar(lb=0,ub=1,name='max_work_utilization')
    for k in p['workers']:
        service=gp.quicksum(p['tasks'][i]['duration_minutes']*x[i,w] for i,w in p['eligible'] if w==k)
        travel=gp.quicksum(p['distances'][a]/p['speed']*60*y[a] for a in p['arcs'] if a[2]==k)
        m.addConstr(service+travel<=p['capacities'][k]*max_util,name=f'balance_{k}')
    m.setObjectiveN(max_util,4,priority=12,abstol=0,reltol=0,name='max_work_utilization')
    m.setObjectiveN(gp.quicksum(p['distances'][a]*y[a] for a in p['arcs']),5,
                    priority=10,abstol=0,reltol=0,name='closed_route_distance_km')
    # Remove arbitrary idle time only after higher-priority service and distance objectives.
    m.setObjectiveN(gp.quicksum(c.values())+gp.quicksum(returned.values()),6,
                    priority=5,abstol=0,reltol=0,name='earlier_completion_tiebreak')
    m.update()
    return m,x,u,y,p,s,c,late,beta,z,returned


def validate_schedule(data,result):
    """Independent recomputation from input; no optimizer constraint inspection."""
    tol=1e-5
    totals=validate_routes(data,result['routes'],result['assignments'])
    tasks={t['id']:t for t in data['tasks']};workers={w['id']:w for w in data['workers']}
    times={r['task_id']:r for r in result['task_schedule']}
    assigned={a['task_id']:a['worker_id'] for a in result['assignments']}
    if len(times)!=len(result['task_schedule']) or set(times)!=set(assigned):raise ValueError('Schedule assignment mismatch')
    for i,row in times.items():
        t=tasks[i]
        if row['worker_id']!=assigned[i]:raise ValueError('Worker mismatch')
        if row['start_minute']<t['release_minute']-tol:raise ValueError('Starts before release')
        if abs(row['finish_minute']-row['start_minute']-t['duration_minutes'])>tol:raise ValueError('Wrong duration')
        if abs(row['late_minutes']-max(0,row['finish_minute']-t['deadline_minute']))>tol:raise ValueError('Wrong lateness')
        for parent in t['predecessor_task_ids']:
            if tasks[parent]['status']!='COMPLETED' and (parent not in times or row['start_minute']<times[parent]['finish_minute']-tol):
                raise ValueError('Prerequisite not finished')
    by_route={r['worker_id']:r for r in totals}
    from baselines.stage_a import distance_km
    locations={l['id']:l for l in data['locations']}
    for route in result['routes']:
        k=route['worker_id'];w=workers[k];rest=route['break'];lo,hi=w['break_window']
        bs,be=rest['start_minute'],rest['end_minute']
        if bs<lo-tol or be>hi+tol or abs(be-bs-w['break_duration_minutes'])>tol:raise ValueError('Invalid break')
        cursor=w['available_from_minute'];previous=w['start_location_id'];travel=0
        ids=route['task_ids'];legs=route['legs']
        if len(legs)!=(len(ids)+1 if ids else 0):raise ValueError('Missing leg')
        for n,leg in enumerate(legs):
            tid=ids[n] if n<len(ids) else None
            target=tasks[tid]['location_id'] if tid else w['end_location_id']
            if leg['from_location_id']!=previous or leg['to_location_id']!=target:raise ValueError('Wrong leg locations')
            duration=distance_km(locations[previous],locations[target])/data['assumptions']['travel_speed_kmh']*60
            dep,arr=leg['departure_minute'],leg['arrival_minute']
            if dep<cursor-tol or abs(arr-dep-duration)>tol:raise ValueError('Invalid travel timing')
            if dep<be-tol and arr>bs+tol and duration>tol:raise ValueError('Driving during break')
            if tid:
                row=times[tid]
                if arr>row['start_minute']+tol:raise ValueError('Task starts before arrival')
                if row['start_minute']<be-tol and row['finish_minute']>bs+tol:raise ValueError('Working during break')
                cursor=row['finish_minute']
            else:cursor=arr
            previous=target;travel+=duration
        if cursor>w['shift_end_minute']+tol:raise ValueError('Late return')
        # A break on a route must occur at a stationary gap at its recorded location.
        if ids:
            valid_gap=False
            for n,leg in enumerate(legs):
                gap_start=w['available_from_minute'] if n==0 else times[ids[n-1]]['finish_minute']
                if gap_start<=bs+tol and be<=leg['departure_minute']+tol and rest['location_id']==leg['from_location_id']:
                    valid_gap=True
            if not valid_gap:raise ValueError('Break not in stationary route gap')
        elif rest['location_id']!=w['start_location_id']:raise ValueError('Idle break location mismatch')
        if abs(travel-by_route[k]['travel_minutes'])>tol:raise ValueError('Wrong travel total')
    return dict(status='passed',checks=['skills_tools','assignment_uniqueness','closed_routes','service_plus_travel_capacity',
                                       'release_times','travel_timing','cross_worker_precedence','break_window_no_overlap',
                                       'stationary_break_location','return_before_shift_end','lateness_recomputed'])


def solve(data,warm_start=None):
    import gurobipy as gp
    m,x,u,y,p,s,c,late,beta,z,returned=build_model(data)
    try:
        if warm_start and warm_start.get('has_solution'):
            selected={(a['task_id'],a['worker_id']) for a in warm_start['assignments']}
            for pair,var in x.items():var.Start=int(pair in selected)
            for i,var in u.items():var.Start=int(not any(a==i for a,k in selected))
            arcs=set()
            for route in warm_start['routes']:
                k=route['worker_id'];ids=route['task_ids']
                if ids:
                    nodes=[f'origin:{k}']+ids+[f'end:{k}']
                    arcs.update((a,b,k) for a,b in zip(nodes,nodes[1:]))
            for a,var in y.items():var.Start=int(a in arcs)
        progress=[]
        def callback(model,where):
            if where==gp.GRB.Callback.MIPSOL:
                progress.append(dict(event='incumbent',runtime_seconds=model.cbGet(gp.GRB.Callback.RUNTIME)))
            elif where==gp.GRB.Callback.MULTIOBJ:
                progress.append(dict(event='objective_pass_finished',runtime_seconds=model.cbGet(gp.GRB.Callback.RUNTIME),
                                     completed_objective_count=int(model.cbGet(gp.GRB.Callback.MULTIOBJ_OBJCNT))))
        m.optimize(callback)
        base=dict(stage='C',scenario_id=data['scenario_id'],input_sha256=hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest(),
                  has_solution=m.SolCount>0,status_code=m.Status,
                  status='OPTIMAL' if m.Status==gp.GRB.OPTIMAL else ('TIME_LIMIT' if m.Status==gp.GRB.TIME_LIMIT else str(m.Status)),
                  runtime_seconds=m.Runtime,time_limit_seconds=m.Params.TimeLimit,mip_gap_setting=m.Params.MIPGap,
                  speed_kmh=p['speed'],progress=progress,is_synthetic=True,
                  notice='使用座標直線距離與22 km/h估計交通；含班次、休息、前置與軟期限。不是實際導航或企業營運驗證。')
        if not m.SolCount:return dict(base,assignments=[],routes=[],task_schedule=[],message='未取得可行排程，不可套用')
        assignments=[dict(task_id=i,worker_id=k) for i,k in p['eligible'] if x[i,k].X>0.5]
        times=[dict(task_id=i,worker_id=k,start_minute=s[i].X,finish_minute=c[i].X,
                    deadline_minute=p['tasks'][i]['deadline_minute'],late_minutes=max(0,c[i].X-p['tasks'][i]['deadline_minute']))
               for i,k in p['eligible'] if x[i,k].X>0.5]
        routes=[]
        for k,w in p['workers'].items():
            succ={i:j for i,j,wid in p['arcs'] if wid==k and y[i,j,wid].X>0.5}
            node=f'origin:{k}';ids=[];legs=[];rest_location=w['start_location_id'];cursor=w['available_from_minute']
            while node in succ:
                target=succ[node];arc=(node,target,k)
                if z[arc].X>0.5:
                    cursor=max(cursor,beta[k].X+w['break_duration_minutes'])
                    rest_location=w['start_location_id'] if node.startswith('origin:') else p['tasks'][node]['location_id']
                origin_loc=w['start_location_id'] if node.startswith('origin:') else p['tasks'][node]['location_id']
                dest_loc=w['end_location_id'] if target.startswith('end:') else p['tasks'][target]['location_id']
                arr=cursor+p['distances'][arc]/p['speed']*60
                legs.append(dict(from_location_id=origin_loc,to_location_id=dest_loc,
                                 departure_minute=cursor,arrival_minute=arr))
                if target.startswith('end:'):break
                if target in ids:raise ValueError('Cycle')
                ids.append(target);cursor=c[target].X;node=target
            routes.append(dict(worker_id=k,task_ids=ids,legs=legs,
                               **{'break':dict(start_minute=beta[k].X,end_minute=beta[k].X+w['break_duration_minutes'],location_id=rest_location)}))
        totals=validate_routes(data,routes,assignments)
        for route,total in zip(routes,totals):
            route.update({key:value for key,value in total.items() if key not in ('worker_id','task_ids')})
            route['return_minute']=route['legs'][-1]['arrival_minute'] if route['legs'] else p['workers'][route['worker_id']]['available_from_minute']
            route['work_utilization']=route['work_minutes']/route['capacity_minutes'] if route['capacity_minutes'] else 0
        objectives=[]
        for n in range(m.NumObj):
            m.Params.ObjNumber=n;objectives.append(dict(name=m.ObjNName,value=m.ObjNVal))
        result=dict(base,assignments=assignments,routes=routes,task_schedule=times,
                    unassigned=[i for i in p['tasks'] if u[i].X>0.5],objective_values=objectives,
                    total_distance_km=sum(r['distance_km'] for r in routes),total_travel_minutes=sum(r['travel_minutes'] for r in routes),
                    late_task_count=sum(t['late_minutes']>1e-5 for t in times),total_late_minutes=sum(t['late_minutes'] for t in times),
                    quality_notice='按目标优先序求解；限时结果不代表所有目标均最优。未收集各层界限，不报告虚构的整体gap。')
        result['max_work_utilization']=max((r['work_utilization'] for r in routes),default=0)
        result['validation']=validate_schedule(data,result)
        return result
    finally:m.dispose()


def clock(data,minute):
    # Display seconds so rounding does not imply overlapping minute-level intervals.
    return (datetime.fromisoformat(data['planning']['start_at'])+timedelta(seconds=round(minute*60))).strftime('%H:%M:%S')


def report(data,result):
    lines=['# Stage C 排程結果','',result['notice'],'',
           f"求解狀態：{result['status']}；耗時 {result['runtime_seconds']:.2f} 秒。"]
    if not result['has_solution']:return '\n'.join(lines+['','未取得可行解，不輸出時間表。'])
    lines +=[f"指派 {len(result['assignments'])} 件，未派 {len(result['unassigned'])} 件。",
             f"路線 {result['total_distance_km']:.3f} 公里、移動 {result['total_travel_minutes']:.1f} 分鐘。",
             f"逾期 {result['late_task_count']} 件，總逾期 {result['total_late_minutes']:.1f} 分鐘。",
             '獨立驗證：'+result['validation']['status'],'',
             '若狀態為 TIME_LIMIT，結果是已驗證可行的排程，尚未證明所有目標最優。',
             '時間為規劃日台北時間，顯示至秒；JSON 保留分鐘數完整精度。','']
    lines += ['## 工作量分擔', '', '工作量 = 處理＋移動；不含休息及等待。降低最大工時使用率，不保證每人完全相同。', '', '| 人員 | 處理分鐘 | 移動分鐘 | 工作分鐘 | 使用率 |', '|---|---|---|---|---|']
    for r in result['routes']:
        lines.append(f"| {r['worker_id']} | {r['service_minutes']} | {r['travel_minutes']:.1f} | {r['work_minutes']:.1f} | {r['work_utilization']:.1%} |")
    lines.append('')
    times={t['task_id']:t for t in result['task_schedule']}
    for r in result['routes']:
        lines +=[f"## {r['worker_id']}",'',
                 f"處理 {r['service_minutes']} 分鐘；移動 {r['travel_minutes']:.1f} 分鐘；休息 {r['break_minutes']} 分鐘。",
                 f"休息 {clock(data,r['break']['start_minute'])}–{clock(data,r['break']['end_minute'])}，地點 {r['break']['location_id']}。",'',
                 '| 任務／回程 | 出發 | 到場 | 開始 | 完成 | 期限 | 逾期分鐘 |',
                 '|---|---|---|---|---|---|---|']
        for idx,leg in enumerate(r['legs']):
            if idx<len(r['task_ids']):
                tid=r['task_ids'][idx];t=times[tid]
                lines.append(f"| {tid} | {clock(data,leg['departure_minute'])} | {clock(data,leg['arrival_minute'])} | {clock(data,t['start_minute'])} | {clock(data,t['finish_minute'])} | {clock(data,t['deadline_minute'])} | {t['late_minutes']:.1f} |")
            else:lines.append(f"| 返回起點 | {clock(data,leg['departure_minute'])} | {clock(data,leg['arrival_minute'])} | — | — | {clock(data,data['planning']['horizon_minutes'])} | — |")
        if not r['task_ids']:lines.append('| 無任務，在起點休息 | — | — | — | — | — | — |')
        lines.append('')
    lines +=['## 求解過程','',f"回呼記錄 {sum(e['event']=='incumbent' for e in result['progress'])} 次候選可行解事件。"]
    for e in result['progress']:
        if e['event']=='objective_pass_finished':lines.append(f"- {e['runtime_seconds']:.2f} 秒：第 {e['completed_objective_count']} 個目標階段結束（不代表已證明最優）。")
    lines +=['','未派任務：'+(', '.join(result['unassigned']) or '無'),'']
    return '\n'.join(lines)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input',type=Path,default=ROOT/'data/taipei_base.json')
    parser.add_argument('--output-dir',type=Path,default=ROOT/'output')
    parser.add_argument('--time-limit',type=float,default=None)
    args=parser.parse_args();data=json.loads(args.input.read_text())
    if args.time_limit is not None:data['solver_defaults']['time_limit_seconds']=args.time_limit
    warm_path=ROOT/'output/stage_b_travel.json'
    warm=json.loads(warm_path.read_text()) if warm_path.exists() and args.input.resolve()==(ROOT/'data/taipei_base.json').resolve() else None
    result=solve(data,warm);args.output_dir.mkdir(parents=True,exist_ok=True)
    (args.output_dir/'stage_c_schedule.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    (args.output_dir/'stage_c_report.md').write_text(report(data,result))
    print(json.dumps({k:result.get(k) for k in ['status','has_solution','runtime_seconds','late_task_count','total_late_minutes','total_distance_km']},ensure_ascii=False))
    sys.exit(0 if result['has_solution'] else 2)
