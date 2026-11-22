"""Synthesize original tap/completion sounds. Sand uses prepare_sand_audio.py."""
import math, struct, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent/'assets/audio'
ROOT.mkdir(parents=True,exist_ok=True)
RATE=22050
def save(name,samples):
    with wave.open(str(ROOT/name),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x))*32767)) for x in samples))
save('tap.wav',[math.sin(2*math.pi*660*i/RATE)*.09*math.exp(-i/RATE*80) for i in range(int(RATE*.09))])
samples=[]
for i in range(RATE):
    t=i/RATE; v=0
    for delay,freq in [(0,523.25),(.13,659.25),(.26,783.99)]:
        age=t-delay
        if age>=0:v+=math.sin(math.tau*freq*age)*.07*(1-math.exp(-age*80))*math.exp(-age*5)
    samples.append(v)
save('complete.wav',samples)
