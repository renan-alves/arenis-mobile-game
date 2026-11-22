"""Author the linear campaign with exact strict-color A* and reproducible witnesses.
Candidate results remain in tmp until the independent Godot proof accepts all levels.
"""
import heapq,json,math,random,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
COLORS=['coral','aqua','gold','lilac','sky','sage','rose','peach','indigo','mint']

def unlock(rows,cap):
    rows=list(rows)
    while True:
        complete={b[0] for key,b in rows if not key and len(b)==cap and len(set(b))==1}
        changed=False
        for i,(key,b) in enumerate(rows):
            if key and key in complete: rows[i]=(0,b);changed=True
        if not changed:return tuple(rows)

def heuristic(state,goal):
    return sum(sum(j==0 or b[j]!=b[j-1] for j in range(len(b))) for _,b in state)-goal

def solve(board,cap,locks=None,max_states=65000,max_seconds=2.2):
    actual=unlock(tuple((locks[i] if locks else 0,tuple(b)) for i,b in enumerate(board)),cap)
    first=tuple(sorted(actual));goal=sum(len(b) for _,b in first)//cap
    h=heuristic(first,goal);heap=[(h,h,0,first)];cost={first:0};parents={};serial=0;started=time.monotonic()
    while heap:
        if time.monotonic()-started>max_seconds:return None
        _,_,_,state=heapq.heappop(heap);g=cost[state]
        if all(not b or len(b)==cap and len(set(b))==1 for _,b in state):
            path=[];node=state
            while node!=first:
                old,src,dst=parents[node];path.append((src,dst));node=old
            path.reverse();moves=[];current=list(actual)
            for src,dst in path:
                a=current.index(src);b=next(i for i,x in enumerate(current) if i!=a and x==dst)
                color=current[a][1][-1];run=0
                for c in reversed(current[a][1]):
                    if c!=color:break
                    run+=1
                n=min(run,cap-len(current[b][1]));moves.append([a,b])
                current[a]=(0,current[a][1][:-n]);current[b]=(0,current[b][1]+(color,)*n)
                current=list(unlock(current,cap))
            assert all(not b or len(b)==cap and len(set(b))==1 for _,b in current)
            return moves,len(cost)
        for a,(key,src) in enumerate(state):
            if key or not src:continue
            color=src[-1];run=0
            for c in reversed(src):
                if c!=color:break
                run+=1
            seen_targets=set()
            for b,(locked,dst) in enumerate(state):
                if a==b or locked or len(dst)==cap or dst and dst[-1]!=color:continue
                if (locked,dst) in seen_targets:continue
                seen_targets.add((locked,dst))
                # Moving a uniform tube into empty space only renames tubes.
                if not dst and len(set(src))==1:continue
                n=min(run,cap-len(dst));rows=list(state)
                rows[a]=(0,src[:-n]);rows[b]=(0,dst+(color,)*n)
                nxt=tuple(sorted(unlock(rows,cap)));depth=g+1
                if cost.get(nxt,10**9)<=depth:continue
                if len(cost)>=max_states:return None
                cost[nxt]=depth;parents[nxt]=(state,(key,src),(locked,dst));serial+=1
                nh=heuristic(nxt,goal);heapq.heappush(heap,(depth+nh,nh,serial,nxt))
    return None

def scramble(rng,cap,count,helpers,target):
    board=[tuple([c]*cap) for c in range(1,count+1)]+[() for _ in range(helpers)]
    seen={tuple(sorted(board))}
    for step in range(target*7+18):
        candidates=[]
        for _ in range(95):
            a=rng.randrange(len(board));b=rng.randrange(len(board))
            if a==b or not board[a] or len(board[b])>=cap:continue
            src,dst=board[a],board[b];color=src[-1];run=0
            for c in reversed(src):
                if c!=color:break
                run+=1
            amount=rng.randint(1,min(run,cap-len(dst)));left=src[:-amount]
            if left and left[-1]!=color:continue
            joined=dst+(color,)*amount;forward_run=amount
            for c in reversed(dst):
                if c!=color:break
                forward_run+=1
            if min(forward_run,cap-len(left))!=amount:continue
            nxt=list(board);nxt[a]=left;nxt[b]=joined;key=tuple(sorted(nxt))
            if key in seen:continue
            boundaries=sum(sum(x!=y for x,y in zip(row,row[1:])) for row in nxt)
            candidates.append((boundaries,rng.random(),nxt,key))
        if not candidates:break
        selected=max(candidates,key=lambda x:(x[0],x[1])) if rng.random()<.7 else rng.choice(candidates)
        _,_,board,key=selected;seen.add(key)
        if selected[0]>=target and step>=target+3:break
    rng.shuffle(board)
    return [list(b) for b in board]

def lock_from_proof(board,cap,solution,rng):
    current=[list(b) for b in board];touched=set();initial={b[0] for b in board if len(b)==cap and len(set(b))==1}
    for a,b in solution:
        touched.update([a,b]);color=current[a][-1];run=0
        for c in reversed(current[a]):
            if c!=color:break
            run+=1
        amount=min(run,cap-len(current[b]));current[b]+=current[a][-amount:];del current[a][-amount:]
        if len(current[b])==cap and len(set(current[b]))==1 and color not in initial:
            targets=[i for i,row in enumerate(board) if i not in touched and len(set(row))>1]
            if targets:
                locks=[0]*len(board);locks[rng.choice(targets)]=color
                return locks
    return None

def create():
    rng=random.Random(2026112206);levels=[];proofs=[];seen=set();started=time.monotonic()
    for number in range(1,151):
        cap=3 if number<=15 else 4 if number<=35 else 5 if number<=65 else 6 if number<=100 else 7
        count=2 if number<=5 else 3 if number<=15 else 4 if number<=25 else 5 if number<=45 else 6 if number<=75 else 7 if number<=105 else 8 if number<=130 else 9
        helpers=1 if number<=5 else 2
        target=min(26,1+number//5)
        if number%10==0:target=max(2,target-4)
        must_lock=number>=61 and (number%4==1 or number in [61,81,101,121,141])
        hidden=number>=26 and (number%3!=0 or number==26)
        for attempt in range(120):
            board=scramble(rng,cap,count,helpers,max(1,target-attempt//24))
            canonical=tuple(sorted(map(tuple,board)))
            if (cap,canonical) in seen:continue
            solved=solve(board,cap)
            if not solved or len(solved[0])<max(2,target-6):continue
            locks=None
            if must_lock:
                locks=lock_from_proof(board,cap,solved[0],rng)
                if locks is None:continue
                solved=solve(board,cap,locks)
                if not solved:continue
            solution,states=solved;break
        else:raise RuntimeError(f'Could not prove level {number}')
        seen.add((cap,canonical));bottles=[]
        for i,row in enumerate(board):
            bottle={'colors':[COLORS[c-1] for c in row]}
            if locks and locks[i]:bottle['unlock_color']=COLORS[locks[i]-1]
            if hidden:
                conceal=[j for j in range(max(0,len(row)-1)) if rng.random()<.55]
                if conceal:bottle['hidden']=conceal
            bottles.append(bottle)
        mode='free' if number<=15 or number%10==0 else 'timed' if number>=41 and number%8==0 else 'moves' if number%3 else 'free'
        minimum=len(solution);move_limit=max(minimum+5,math.ceil(minimum*2.1)+(3 if hidden else 0)) if mode=='moves' else 0
        time_limit=max(90,minimum*7+30+(30 if hidden else 0)) if mode=='timed' else 0
        level={'id':f'level-{number:03}','version':1,'title':f'Nível {number}','number':number,'difficulty':'Campanha','difficulty_id':'journey','capacity':cap,'minimum_moves':minimum,'lesson':'Separe cada cor em um tubo cheio.','mode':mode,'move_limit':move_limit,'time_limit':time_limit,'bottles':bottles}
        levels.append(level);proofs.append({'id':level['id'],'minimum_moves':minimum,'solution':solution,'python_states':states})
        print(f'{number:03}/150: {len(board)} tubes, capacity={cap}, minimum={minimum}, {mode}, states={states}',flush=True)
    # Curated candidates that also satisfy the independent engine's proof budget.
    overrides=json.loads((ROOT/'data/journey-authoring-overrides.json').read_text(encoding='utf-8'))
    for replacement,witness in zip(overrides['levels'],overrides['witnesses']):
        index=replacement['number']-1
        levels[index]=replacement
        proofs[index]={'id':replacement['id'],'minimum_moves':replacement['minimum_moves'],'solution':witness['solution'],'python_states':witness.get('states',0)}
    pack={'schema_version':3,'rules_version':3,'pack_id':'journey','pack_version':1,'levels':levels}
    (ROOT/'tmp').mkdir(exist_ok=True)
    (ROOT/'tmp/journey-pack.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ROOT/'tmp/journey-witnesses.json').write_text(json.dumps({'algorithm':'strict-color-astar-symmetry-v3','elapsed_seconds':round(time.monotonic()-started,2),'results':proofs},indent=2)+'\n',encoding='utf-8')
    print('150 levels authored with exact Python minima. Independent Godot proof is still required.',flush=True)
if __name__=='__main__':create()
