# ForeverKoS — first test build

Built for the Forever client beside ForeverAuras 1.1.0. Not yet tested in-game.

Also prepared for **TBC Classic Anniversary**, interface **20506**, matching the TBC WeakAuras files in your installation. For TBC, copy the same ForeverKoS folder into `E:\WoW\World of Warcraft\_anniversary_\Interface\AddOns\`. Use **WeakAuras** for the optional aura setup below. The addon selects whichever aura engine is loaded. Do not copy ForeverAuras into TBC. Both testers must be in the same TBC guild; Forever and TBC cannot synchronize with each other. A TBC test validates shared logic, but Forever-specific behaviour still needs separate testing.

Automated checks passed using Lua 5.1 with simulated WoW clients: permission enforcement (GM, officer, member and officer-chat listener), unauthorized update rejection, removal persistence against older updates, conflicting edits, officer snapshot responses, faction checks, alert cooldowns, demotion, guild separation, malformed messages, and aura syntax. These checks do not validate the custom client's actual APIs or networking.

## Install

Close WoW. Copy the **ForeverKoS** folder into:
`E:\WoW\World of Warcraft\_forever_\Interface\AddOns\`

Every participating guild member needs the addon. Enable it at character selection.
The addon works immediately with private chat alerts and sound; the optional aura below adds a large on-screen display. It does not send public sighting announcements.

## Officer controls

Click the crossed-swords minimap button or type `/kos` to toggle the management window. It includes a paged list, Add / Save, Add Target, Remove, Test Alert, Sync, and local sound/alert toggles. Click an entry to select it for editing or removal. Drag the minimap button to reposition it; press Esc to close the window. Read-only members can browse and test alerts; editing controls require officer permission. The window refreshes while open as list updates arrive.

- `/kos add target Camping low levels` — add the selected player.
- `/kos add Enemy-Realm Reason here` — add a named player.
- `/kos remove Enemy-Realm` — remove a player.
- `/kos remove` — remove your selected player.
- `/kos list` — view active entries, reasons and editors.
- `/kos publish` — officers broadcast their saved records.

Use full Name-Realm for other realms. Names without a realm refer to your own realm.
The guild master and ranks with **officer chat speak** permission can edit. Listening permission alone does not grant editing. Rank permissions are read from the client, not from a locally editable officer-name list. Unsupported permission APIs fail closed for non-GM ranks; use `/kos status` to diagnose.

## Member controls

- `/kos sync` — request records from online officers.
- `/kos status` — check guild, editing availability and outgoing queue.
- `/kos test` — test sound and the optional aura without an enemy.
- `/kos sound off` / `/kos sound on`.
- `/kos alerts off` / `/kos alerts on`.

## Optional ForeverAura

Create a **Text** aura in ForeverAuras. Configure:

1. Trigger type **Custom**, event type **Event**.
2. Event(s): `FOREVER_KOS_SPOTTED`.
3. Hide: **Timed**, duration **8 seconds**.
4. Custom trigger:

```lua
function(event, name, reason, zone)
    if event ~= "FOREVER_KOS_SPOTTED" or not name then return false end
    aura_env.kosText = "KoS spotted: " .. name
        .. ((reason and reason ~= "") and ("\n" .. reason) or "")
        .. ((zone and zone ~= "") and ("\n" .. zone) or "")
    return true
end
```

5. Display text: `%c`. Custom text function (update on **Trigger Update**):

```lua
function()
    return aura_env.kosText or "KoS spotted"
end
```

Choose a red font around size 30, position near the centre, and leave load conditions unrestricted. Sound comes from the addon; do not add another sound action unless you switch the addon sound off. Run `/kos test`. This is a manual aura setup, not an import string.

## Sync behaviour and limits

Records use an increasing logical revision and editor identity as a deterministic tie-breaker. Removes remain as tombstones, so older additions cannot revive a removed entry. An intentional newer add restores it. Offline concurrent edits converge deterministically; they cannot reliably reflect real-world ordering until the officers exchange updates. Sync before editing after a long absence.

Each guild has separate saved records. Members request updates on login and every five minutes. Only current authorized officers can send accepted records, including snapshots of earlier edits. Ordinary members retain and use their last list while no officer is online; they cannot serve it to other members. Keep at least one officer's saved copy or a backup when reinstalling. Tombstones are retained indefinitely.

Messages are paced at five per second and capped at 250 bytes. Very long names/reasons are rejected when they cannot fit. Sync requests are limited to one per sender per minute per responder. Each officer may respond; this first build is intended for modest guild lists, not thousands of records. No central server or cryptographic signatures are used; this trusts officers and WoW's addon sender identity. Guild permission changes depend on refreshed roster/client data.

Detection checks new nameplates, targets and mouseovers, confirms opposite faction, and limits repeat alerts to once per player per minute. Enemy nameplates must be enabled for passive nameplate detection. It cannot reveal hidden enemies, scan a zone, or guarantee detection outside the client's visible units. Restricted unit data is skipped safely. Combat-log detection and public chat announcements are not included.

## In-game acceptance check

1. Two guild members install it: one officer and one ordinary member. Run `/kos status` on each.
2. Officer adds a test name. Member runs `/kos sync`, then `/kos list`; confirm matching entry and reason.
3. Member tries an add/remove: it must be denied.
4. Officer removes the test name. Confirm it disappears on the member; reconnect an older officer copy and confirm the removal survives syncing.
5. Two officers edit separate entries, sync both, and check matching lists. Also test conflicting add/remove of the same name.
6. Change an officer's rank permissions and refresh/relog. Confirm unauthorized updates are rejected.
7. Add a consenting opposing-faction test player, enable enemy nameplates, and approach/target/mouse over them. Verify one alert per minute and `/kos test` displays the aura.
8. Reload/relog and verify persistence. Verify a guildless character gets no former-guild sightings.

If a Lua error occurs, capture its text plus `/kos status`. Custom Forever-client compatibility and real cross-client delivery still require these checks before guild-wide use.
