import runpy
ns=runpy.run_path('tests/test_kills.py')
r=ns['r'];api=r.globals().ForeverKoS
r.execute("""
hk=10
function GetPVPSessionStats()return hk end
now=500
testFrame.OnEvent(testFrame,"PLAYER_LOGIN")
function tick(t)now=t;testFrame.OnUpdate(testFrame,1)end
function party(guid) testFrame.OnEvent(testFrame,"PARTY_KILL","Player-3-Party",guid)end
""")
# Credit before the event, as seen on the user's client.
r.execute('hk=11;tick(501);now=503;party("Player-2-AssistA");tick(510)')
assert api.GetPlayerPvPBreakdown('Player-2-AssistA')==(0,1,0)
# Event before credit, with duplicate delivery.
r.execute('now=520;party("Player-2-AssistB");party("Player-2-AssistB");hk=12;tick(522);tick(529)')
assert api.GetPlayerKillCount('Player-2-AssistB')==1
# Own kills reserve the credit and are never reclassified as assists.
r.execute('now=540;testFrame.OnEvent(testFrame,"PARTY_KILL","Player-1-Self","Player-2-Own");hk=13;tick(542);tick(549)')
assert api.GetPlayerPvPBreakdown('Player-2-Own')==(1,0,0)
# Party kills without personal credit and credit without a death do not count.
r.execute('now=560;party("Player-2-NoCredit");tick(567);hk=14;tick(580);tick(587)')
assert api.GetPlayerKillCount('Player-2-NoCredit')==0
# Multiple possible victims remain unattributed.
r.execute('now=600;party("Player-2-AmbiguousA");party("Player-2-AmbiguousB");hk=15;tick(601);tick(608)')
assert api.GetPlayerKillCount('Player-2-AmbiguousA')==0
assert api.GetPlayerKillCount('Player-2-AmbiguousB')==0
# A burst of two credits is also ambiguous.
r.execute('now=620;party("Player-2-Burst");hk=17;tick(621);tick(628)')
assert api.GetPlayerKillCount('Player-2-Burst')==0
# Excluded instances discard pending work and establish a fresh baseline.
r.execute('now=640;party("Player-2-BG");function IsInInstance()return true,"pvp" end;hk=18;tick(641);tick(650);IsInInstance=nil;tick(660)')
assert api.GetPlayerKillCount('Player-2-BG')==0
# Named credits must not also receive delayed generic credit.
r.execute('now=680;COMBATLOG_HONORGAIN="%s dies (Honorable Kill). You gain %d Honor.";party("Player-2-Enemy");testFrame.OnEvent(testFrame,"CHAT_MSG_COMBAT_HONOR_GAIN","Enemy Person dies (Honorable Kill). You gain 4 Honor.");hk=19;tick(681)')
before=api.GetPlayerKillCount('Player-2-Enemy')
r.execute('tick(688)')
assert api.GetPlayerKillCount('Player-2-Enemy')==before
print('PASS: isolated generic assist correlation, both arrival orders, own-kill reservation, ambiguity and instance exclusion, named-credit deduplication.')
