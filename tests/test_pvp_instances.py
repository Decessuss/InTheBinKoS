import runpy
ns=runpy.run_path('tests/test_kills.py')
r=ns['r'];api=r.globals().ForeverKoS
r.execute('''
COMBATLOG_HONORGAIN="%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
instanceKind="pvp"
function IsInInstance()return instanceKind~="none",instanceKind end
deathHits={}
C_DeathRecap={GetRecapEvents=function()return deathHits end}
''')
for kind in ('pvp','arena'):
    r.globals().instanceKind=kind
    r.execute('''
now=300
testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-Enemy")
testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Enemy Person dies, honorable kill Rank: Scout (Estimated Honor Points: 10)")
testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","BG Only dies, honorable kill Rank: Scout (Estimated Honor Points: 10)")
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-2-Enemy","Player-1-Self")
deathHits={{sourceGUID="Player-2-Enemy",timestamp=300,event="SPELL_DAMAGE"}}
testFrame.OnEvent(testFrame,"PLAYER_DEAD")
''')
    assert api.GetPlayerPvPRecord('Player-2-Enemy')==(2,0)
    assert not r.globals().ForeverKoSDB.pvpKills['Player-1-Self'].namedCredits
r.execute('''
instanceKind="none";now=310
testFrame.OnEvent(testFrame,"PLAYER_ALIVE")
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-Enemy")
''')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(3,0)
print('PASS: battleground/arena wins, assists, unknown credits and losses excluded; existing records preserved and world PvP resumes.')
