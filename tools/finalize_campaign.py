"""Freeze the initial unpublished campaign after Godot --solve. No runtime randomness."""
import argparse
import hashlib
import json
from pathlib import Path

def fingerprint(level):
    bottles = [[b['colors'], sorted(map(int,b.get('hidden',[]))), b.get('unlock_color','')] for b in level['bottles']]
    value = [2,level['id'],int(level['version']),level['difficulty_id'],int(level['capacity']),bottles]
    return hashlib.sha256(json.dumps(value,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ['input','proof','output']:parser.add_argument('--'+name,required=True,type=Path)
    parser.add_argument('--replace-unpublished',action='store_true')
    args=parser.parse_args()
    if args.output.exists() and not args.replace_unpublished:
        parser.error('Output already exists. Replacing published IDs is forbidden; only use --replace-unpublished before release.')
    pack=json.loads(args.input.read_text(encoding='utf-8-sig'))
    proof=json.loads(args.proof.read_text(encoding='utf-8-sig'))
    results={r['id']:r for r in proof['results']}
    assert proof['accepted'] and len(results)==150 and len(pack['levels'])==150
    for level in pack['levels']:
        result=results[level['id']]
        assert result['status']=='optimal' and result['accepted'] and result['minimum_moves']>0
        assert result['fingerprint']==fingerprint(level),level['id']
    final=[]
    for difficulty in ['easy','medium','hard']:
        source=[l for l in pack['levels'] if l['difficulty_id']==difficulty]
        assert len(source)==50
        group=[]
        for a,b in [(0,3),(3,10),(10,20),(20,23),(23,35),(35,50)]:
            for level in sorted(source[a:b],key=lambda l:(results[l['id']]['minimum_moves'],l['id'])):
                level['minimum_moves']=results[level['id']]['minimum_moves']
                group.append(level)
        for number,level in enumerate(group,1):
            level.update(id=f'{difficulty}-{number:03}',title=f'Nível {number}')
        final.extend(group)
    pack['levels']=final
    args.output.write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('150 levels frozen. Run Godot validation without --solve to create the final proof.')

if __name__=='__main__':main()
