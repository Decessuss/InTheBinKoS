import runpy
ns=runpy.run_path('tests/test_kills.py')
r=ns['r'];api=r.globals().ForeverKoS
r.execute('''
deathHits={}
C_DeathRecap={GetRecapEvents=function()return deathHits end}
testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
deathHits={{sourceGUID="Player-2-Enemy",sourceName="Enemy Person",timestamp=200,event="SPELL_DAMAGE"}}
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
''')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(2,1)
# A repeated recap and a second kill event for the same death cannot double-count.
r.execute('testFrame.OnEvent(testFrame,"PARTY_KILL","Player-2-Enemy","Player-1-Self")')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(2,1)
r.execute('''
now=110;testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
''')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(2,1)
# A new confirmed death counts; NPCs and environmental damage do not.
r.execute('''
testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
deathHits={{sourceGUID="Player-2-Enemy",timestamp=210,event="SWING_DAMAGE"}}
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
deathHits={{sourceGUID="Creature-1-NPC",sourceName="Enemy Person",timestamp=220,event="SPELL_DAMAGE"}}
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
deathHits={{sourceGUID="Player-2-Enemy",timestamp=230,event="ENVIRONMENTAL_DAMAGE"}}
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
''')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(2,2)
# WoWForever may provide a readable name without a GUID; use only an observed player mapping.
r.execute('''
now=120;testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")
deathHits={{sourceName="Enemy Person",timestamp=240,event="SPELL_DAMAGE"}}
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
GameTooltip.scripts.OnTooltipCleared(GameTooltip)
modernCallback(GameTooltip)
assert(tooltipLines[#tooltipLines-1]=="Your PvP record: 2 wins / 3 losses")
''')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(2,3)
print('PASS: PvP losses from death recap/kill events, per-death deduplication, stale recap rejection, NPC/environment exclusion and observed-player resolution.')
