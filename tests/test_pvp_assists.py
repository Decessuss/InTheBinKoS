import runpy
ns=runpy.run_path('tests/test_kills.py')
r=ns['r'];api=r.globals().ForeverKoS
r.execute('''
COMBATLOG_HONORGAIN="%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")
now=200
testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Enemy Person dies, honorable kill Rank: Scout (Estimated Honor Points: 10)")
''')
assert api.GetPlayerPvPRecord('Player-2-Enemy')==(3,0)
assert api.GetPlayerPvPBreakdown('Player-2-Enemy')==(2,1,0)
# One kill is still one win when honor and killing-blow events both arrive.
r.execute('testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-Enemy")')
assert api.GetPlayerKillCount('Player-2-Enemy')==3
assert api.GetPlayerPvPBreakdown('Player-2-Enemy')==(3,0,0)
assert r.globals().ForeverKoSDB.pvpKills['Player-1-Self']['Player-2-Enemy'].lastKillType=='killingBlow'
r.execute('testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","You have been awarded 50 honor points.")')
assert api.GetPlayerKillCount('Player-2-Enemy')==3
# Credit is retained by full name until a GUID can be identified.
r.execute('''
now=210
testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Unknown Opponent dies, honorable kill Rank: Scout (Estimated Honor Points: 10)")
guids.mouseover="Player-2-Unknown";units.mouseover.name="Unknown Opponent"
testFrame.OnEvent(testFrame,"UPDATE_MOUSEOVER_UNIT")
''')
assert api.GetPlayerKillCount('Player-2-Unknown')==1
# Localized strings with positional format arguments preserve the victim field.
r.execute('''
now=220
COMBATLOG_HONORGAIN="Rang %2$s: %1$s vaincu (%3$d honneur)."
testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Rang Eclaireur: Unknown Opponent vaincu (10 honneur).")
''')
assert api.GetPlayerKillCount('Player-2-Unknown')==2
assert api.GetPlayerPvPBreakdown('Player-2-Unknown')==(0,2,0)
r.execute('''
now=230
testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-Unknown")
testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Rang Eclaireur: Unknown Opponent vaincu (10 honneur).")
ForeverKoSDB.pvpKills["Player-1-Self"]["Player-2-Legacy"]={count=7,losses=2}
''')
assert api.GetPlayerPvPBreakdown('Player-2-Unknown')==(1,2,0)
assert api.GetPlayerKillCount('Player-2-Unknown')==3
assert api.GetPlayerPvPBreakdown('Player-2-Legacy')==(0,0,7)
print('PASS: named shared honor credits count as wins; no duplicate killing-blow credit, no bonus-honor guessing, deferred GUID matching and localized messages.')
