import runpy
import wave
from pathlib import Path
ns=runpy.run_path('tests/test_guild_alerts.py');base=ns['base']
a,b=ns['client']('Alice'),ns['client']('Member')
for r in (a,b):
    r.execute('''
clips=0
function PlaySoundFile(path,channel)
 assert(path=="Interface\\\\AddOns\\\\InTheBinKoS\\\\Media\\\\EnemySpotted.wav")
 assert(channel=="Master")
 clips=clips+1;return true,42
end
''')
base['command'](a,'add target Sound check')
base['deliver'](a,b,'Alice-Realm')
a.execute('testFrame.OnEvent(testFrame,"PLAYER_TARGET_CHANGED")')
base['deliver'](a,b,'Alice-Realm')
assert a.globals().clips==1 and b.globals().clips==1
assert a.globals().sounds==0 and b.globals().sounds==0
base['command'](b,'test');assert b.globals().clips==2
base['command'](b,'sound off');base['command'](b,'test');assert b.globals().clips==2
base['command'](b,'sound on')
b.execute('PlaySoundFile=function()return false end')
base['command'](b,'test');assert b.globals().sounds==1
b.execute('PlaySoundFile=function()error("Unsupported client")end')
base['command'](b,'test');assert b.globals().sounds==2
with wave.open(str(Path('Media/EnemySpotted.wav'))) as clip:
    assert clip.getcomptype()=='NONE'
    assert clip.getnchannels() in (1,2)
    assert 0.2 < clip.getnframes()/clip.getframerate() < 5
print('PASS: local/shared voice clip, test alert, sound checkbox, failed/missing-audio fallback and valid PCM WAV.')
