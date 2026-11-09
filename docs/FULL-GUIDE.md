# <in the bin> KoS List

An officer-managed guild Kill on Sight list with a minimap window, local sighting alerts, shared last-seen reports and clickable map locations.

**Status:** release candidate with a separate unrestricted test build. TBC TomTom links and Retail native map pins have been tested in-game. The new shared sightings and larger-list controls have automated simulated-client tests; multiplayer delivery and WoWForever compatibility still need in-game validation.

## Quick start

1. Install one build in the correct client's `Interface\AddOns` folder, preserving the folder name **ForeverKoS**.
2. Enable **<in the bin> KoS List** in the character-selection AddOns list.
3. Click the crossed-swords minimap button, or type `/kos`.
4. Click **Test Alert**. A private chat message and sound should appear. Import the optional aura for the styled on-screen card.
5. Click the blue zone/coordinates link in the test message to pin the position where you pressed Test Alert. Move away first if you want to check that the coordinates stay fixed.

Test Alert works without another player. In the unrestricted build, a guildless character can also create a local test list. Test alerts do not add fake entries or sightings to the list.

## Test and release builds

| Capability | Officer-controlled release | Unrestricted test |
|---|---|---|
| View, search and sort the shared list | All guild members | All guild members |
| Receive or serve a requested cached list | All guild members | All guild members |
| Add/remove players or edit reasons | Guild master and officer-chat speakers | Any guild member |
| Report actual sightings | All participating guild members | All participating guild members |
| View shared sightings and pin a last-seen location | All guild members | All guild members |
| Create a private local list while guildless | No | Yes |

Officer permission means **permission to speak in officer chat**. Permission to listen alone does not grant editing rights. Rank names such as “Officer” are not hard-coded. If the client's rank-permission API is unavailable, non-GM editing and publishing fail closed rather than granting everyone access.

Install only one build at a time. Both use the `ForeverKoS` folder, `/kos` command and aura event. Test and release have **separate saved databases and network prefixes**, so test edits cannot change the release list. Switching to release does not copy your test list.

## Installation and updates

For this setup, the client folders are:

| Client | AddOns directory |
|---|---|
| TBC Classic Anniversary | `E:\WoW\World of Warcraft\_anniversary_\Interface\AddOns` |
| Retail | `E:\WoW\World of Warcraft\_retail_\Interface\AddOns` |
| WoWForever | `E:\WoW\World of Warcraft\_forever_\Interface\AddOns` |

Close the game, extract the package, and place its **ForeverKoS** folder in the appropriate AddOns directory. Avoid an extra nested folder: `AddOns\ForeverKoS\ForeverKoS.toc` should exist directly. Do not rename the addon folder; texture paths and initialization depend on it. The display name is `<in the bin> KoS List`, while the internal folder stays `ForeverKoS`.

ZIP packages stored beside the addon are inactive. To switch builds, close the game and replace the active `ForeverKoS` folder with the one inside the desired ZIP. Keep your `WTF` saved data unless you intend to reset it. A restart may be necessary when adding a new addon folder or texture; ordinary Lua changes usually need `/reload`.

Every guild member who wants the list or automatic sightings needs the addon. Use matching versions and build types. TBC, Retail and WoWForever do not synchronize with each other.

## The management window

Click the minimap button or type `/kos` to open or close the window. Drag the button around the minimap to reposition it. Drag the window to move it; press **Esc** or its close button to dismiss it.

The guild logo is dimmed behind the controls to preserve contrast.

### Browsing a long list

- **Search:** filter by player name, reason, reporting player or last-seen zone. Clear the box to show all entries.
- **Sort: Name / Sort: Last Seen:** switch between alphabetical order and newest sightings first. Unseen entries follow seen entries in the latter mode.
- **Previous / Next:** move through seven entries per page. The count shows matching entries versus total active entries.
- Each row shows the name, reason, last-seen zone, age and reporter. Hover for the full details and saved coordinates.

Realm suffixes are hidden in player labels and alerts, but retained internally for matching and synchronization. Two same-named characters from different realms can therefore have identical visible labels. Selecting an existing entry preserves its full identity when saving or removing it.

### Adding and editing

Authorized editors can enter a player and optional reason, then press **Add / Save**. To add your current target, enter a reason and click **Add Target**. Click an existing entry to load its name and reason, edit the reason and press **Add / Save**. To remove it, select it and click **Remove**.

Member clients see the list, search, sorting and page controls. Below the page buttons they see only **Sound** and **Sighting alerts** checkboxes. Editing fields and all footer buttons are hidden. Members can right-click a listed player to pin a saved sighting, use `/kos sync` to request updates, and use `/kos test` to test alerts. Officers retain the complete controls.

Names entered without a realm refer to your current realm. `Name-Realm` remains accepted for explicit matching even though realm suffixes are hidden in the display. First and last names are supported. Enter the complete name in the UI. In slash commands, quote a name containing spaces: `/kos add "First Last" Reason here` and `/kos remove "First Last"`. The same syntax works in Personal mode. Existing one-word names and target commands still work. Names are case-insensitive for matching, and repeated ordinary spaces are normalized. All guild members should update to 0.5.1 to sync names containing spaces. Actual WoWForever name API behavior still requires in-game testing.

Reasons are limited to 60 bytes and sanitized for chat formatting. Very long encoded names or reasons can be rejected if they exceed the addon-message limit; use a shorter reason when prompted.

## Detection and last-seen reports

### Personal avoid list

Choose **Personal List** at the top of the window to maintain a private list of people you prefer not to group with. Everyone can add, edit and remove their own entries regardless of guild rank. The list is saved per character, works while guildless, and is never included in guild sync or sightings. Personal records are kept separately from guild records and share the same private store across test/release builds.

Add a friendly target or type their name and a reason. Same-faction target/mouseover checks produce a private chat reminder and optional sound, limited to once per player per minute. When a listed person is already in your party/raid or joins it, you get a private group warning once per membership change. This does not block invitations or remove anyone from a group. It does not inspect group-finder applicants or invitation dialogs. Personal reminders use chat and sound rather than the guild KoS aura or map pins.

The **Sound** and **Personal reminders** checkboxes on this tab apply only to the personal list. Guild alert settings remain separate. Guild detection continues regardless of which tab is open. In Personal view, Sync, Pin Last Seen and officer access controls are hidden. `/kos personal` and `/kos guild` switch the active list; `/kos add`, `/kos remove` and `/kos list` act on that selected list. The title/status makes the current private mode clear. Shared guild snapshots never include personal notes.

The addon checks players when:

- An enemy nameplate becomes available.
- You mouse over their character.
- You change your selected target.

The player must be on your active list and belong to the opposing faction. Enable enemy nameplates for passive nameplate detection. A per-player 60-second cooldown limits repeated alerts and reports. Another sighting is recorded after the cooldown when a relevant event occurs; the addon does not continuously scan stationary players every second.

**Last seen means the spotter's position at the moment they detected the player.** It is an approximate sighting location, not the enemy's exact coordinates or a live tracker. Each report stores the KoS name, reporting guild member, timestamp, map and spotter coordinates. A newer report replaces an older report; reports with equal timestamps use a deterministic reporter tie-breaker.

Any participating guild member can send a sighting for an active KoS entry without being allowed to edit that entry. Reports are sent through the addon's guild communication channel, not public chat. Fresh direct reports up to 30 seconds old trigger private chat, sound and the existing aura on recipients, naming the original spotter and using their saved location. Recipients must have the enemy on their active list and alerts enabled. A shared 60-second per-enemy notification cooldown prevents multiple nearby spotters from repeatedly alerting the same recipient. Duplicate packets, old reports and cached history snapshots update data without replaying alerts. Sound obeys each recipient's local setting. Everyone should update the addon; the existing aura event is unchanged.

Officers can select an entry and click **Pin Last Seen** to pin its saved observation location. All members can also right-click an entry to pin it. The button is disabled if no valid mapped sighting is available. Read the age before travelling: the player may have moved or left the zone. Entries without reports show **Not seen yet**.

Local sightings persist with your saved guild list. Any guild peer can include cached sightings from the past seven days when responding to list sync requests. Older locally saved reports can remain visible with their age, but are not relayed in history sync. A client only accepts reports for entries already on its active list.

Turning **Sighting alerts** off mutes your automatic local notifications while still collecting and sharing sightings. Turning **Sound** off disables the addon's sound. Neither setting grants or changes edit permission. Test Alert deliberately still exercises the notification path; its sound obeys the sound setting.

## Map links and waypoints

Local chat alerts contain the spotted name, spotter and a blue zone/coordinates link. Clicking it uses the stored detection coordinates, even after the spotter moves.

Native map waypoints are preferred when the client supplies the necessary APIs. TomTom is used when native waypoint APIs are absent. These are static user waypoints, not party/raid map pings. Creating a native waypoint can replace your current user waypoint.

Some maps do not support native waypoints; Dalaran's current map rejected them during testing. If native APIs exist but reject the map, this build explains the restriction instead of silently switching to TomTom. Test in a normal outdoor zone with a fresh link. Missing map coordinates produce **location unavailable**; the sighting can still be recorded with no pinnable position.

TomTom is optional on clients with working native waypoints, and required for the tested TBC pin path. The optional aura is not needed for map links or the management window.

## Styled WeakAura / ForeverAura

Use **WeakAuras** on the TBC installation and **ForeverAuras** on WoWForever. The packaged Retail import is supplied for compatible WeakAuras installations; test it separately from native map pins.

1. Open the appropriate import text file and copy its entire line.
2. Type `/wa` for WeakAuras or `/fa` for ForeverAuras.
3. Click **Import**, paste the string, review it and confirm.
4. Disable earlier basic KoS text auras to avoid duplicates.
5. Close the configuration window and run `/kos test`.

The group is **<in the bin> KoS List — Sighting Card**. It shows the player name, reason and zone for eight seconds, with a dark background, red accent, countdown and fades. New sightings replace the card's contents and reset its duration. Earlier messages remain in chat.

Move or scale the **whole group** in the aura editor. The card has no sound actions; the addon supplies sound. Map interactions stay in chat and the addon window. Importing the aura does not install the addon.

Import files:

- `ForeverKoS-Sighting-Card-import.txt` — WeakAuras.
- `ForeverKoS-ForeverAura-import.txt` — ForeverAuras.

## Commands

### Named editor permissions

Guild officers have a **Grant list editing** section below their normal controls. Enter a current guild member's character name and choose **Grant Access** or **Revoke Access**. Granted editors get the list-management fields and can add/edit/remove entries, but cannot grant access to anyone else. Guild-master and officer-chat permissions always apply; revoking a named grant does not remove a character's rank-based rights.

Grants are per character and guild, persist in saved data, and use versioned revocations so an older grant cannot restore removed access. Direct grants and grant-history synchronization are accepted only from an actual guild officer; ordinary peer list caches cannot authorize new editors. An online officer is therefore needed to deliver grants/revocations to a client that missed them, even though the list itself can sync from any peer. Revocations are not instantaneous on disconnected clients. The special Retail member-only build cannot use grant controls even on an officer character.

| Command | Action |
|---|---|
| `/kos` or `/kos ui` | Toggle the management window. |
| `/kos add target Reason` | Add the selected player with an optional reason. |
| `/kos add Player Reason` | Add or update a named entry on your current realm. |
| `/kos add Player-Realm Reason` | Add or update an explicit full identity. |
| `/kos remove` or `/kos remove target` | Remove your selected player. |
| `/kos remove Player-Realm` | Remove the specified entry. |
| `/kos list` | Print active entries, reasons and editors in private chat. |
| `/kos sync` | Request cached lists and recent history from online guild peers. |
| `/kos publish` | Authorized editors broadcast their saved list and recent sightings. |
| `/kos test` | Test chat link, sound and optional card without another player. |
| `/kos status` | Show guild scope, edit availability and outgoing queue length. |
| `/kos sound on` / `/kos sound off` | Enable or disable local addon sound. |
| `/kos alerts on` / `/kos alerts off` | Enable or mute automatic local sighting notifications. |

## Synchronization and large lists

List records have logical revisions and editor identifiers. Removals leave retained deletion records (“tombstones”), so an older saved copy cannot restore a removed player. A deliberate newer add can restore them. Concurrent officer edits merge deterministically; when offline edits conflict, the outcome does not necessarily follow real-world edit time. Sync before editing after a long absence.

The addon requests updates when guild state initializes and every five minutes. Manual sync has a 30-second cooldown; a publisher responds to the same requester's requests at most once per minute. Outgoing messages are paced at five per second, with a maximum queue of 5,000 messages and a 250-byte message limit. Large lists and multiple responding officers can take time to transfer; the UI updates as records arrive. Check `/kos status` while syncing.

Search and pagination keep the window manageable as the list grows. Keep reasons concise and remove obsolete active entries manually. There is no automatic expiry, bulk import/export, batch removal or tombstone cleanup in this version. The queue cap can prevent a very large snapshot from completing; this build is intended for ordinary guild lists, not an unlimited blacklist service. Large-scale stress testing remains pending.

Any online guild member running a matching updated build can answer a sync request with their saved list and recent sighting history. An officer does not need to be online. Revisions and removal records merge incoming copies, so an older cached addition cannot replace a newer removal. A peer can only provide changes it has actually received; a newly created officer edit cannot appear from an older offline cache. If several peers reply, their copies converge as messages arrive. There is no central server or cross-client cloud storage.

**Cached-sync trust:** direct list edits and local editing controls remain restricted to officers. Requested cached records are accepted as trusted guild-peer data, not cryptographically signed officer records. The sender is checked against the current guild roster, and cached snapshots are accepted only by whisper during the request window. A deliberately modified addon or saved file on a guild member's computer could falsify a cached record. This cooperative guild model provides offline-officer syncing, not tamper-proof officer authorship. The member-only test build can serve cached data without gaining edit controls.

## Saved data and backups

WoW stores the addon data in the current client's account-level `WTF\Account\<account>\SavedVariables\ForeverKoS.lua`.

- `ForeverKoSDB`: officer-controlled release data.
- `ForeverKoSTestDB`: unrestricted test data.

Guild records, last sightings and local sound/alert preferences are separated by guild scope. The test build also has a separate per-character guildless scope. The minimap angle and sort preference are account-level settings within that build's database. The window can be dragged, but its position is not persisted in this version.

Close WoW before making a backup or restoring saved-variable files. Back up the file before switching or reinstalling. Both builds can have data in that same saved-variable file, so deleting it resets both sets of saved state. Do not edit the file while the game is running; WoW may overwrite your changes on exit.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Addon missing | Correct client folder, direct `ForeverKoS.toc` location, addon enabled, then restart WoW. |
| No minimap button | Open your minimap button collector; `/kos` also opens the window. |
| New logo not visible | Restart the game after installing `Media\GuildBackground.tga`. |
| No card but chat/sound works | Import the appropriate aura, check its Load settings, close the editor and test again. |
| No automatic alert | Active entry, opposite faction, target/mouseover/nameplate event, alerts enabled and 60-second cooldown elapsed. |
| No sound | Enable addon sound, check Master volume and try Test Alert. |
| Cannot edit | Confirm release versus test, loaded guild roster and officer-chat speak permission. Run `/kos status`. |
| Empty list for a member | Same guild/build, an online peer with a saved list, Sync and allow time for the queue. |
| No last-seen information | A participating member must actually detect the listed player, or an officer must have recent saved history to sync. |
| Pin button disabled | No mapped sighting is saved for the selected entry. |
| “Map does not support a waypoint” | Use a supported outdoor zone and a fresh test link. |
| “Location unavailable” | The client did not provide valid player coordinates for that map. |
| Pin is in the wrong place for the enemy now | It records where the spotter was at detection time. Check the report's age. |

For a Lua error, capture its exact text, your game client, test/release build, `/kos status`, and the action that triggered it. For an aura import/display issue, include the import filename and the editor tab or screenshot.

## Deployment checklist

Before guild-wide use, confirm an officer can add/remove entries, a normal member can view but cannot edit them, and a normal member's sighting updates another member's last-seen row. Check search, latest-first sorting, last-seen pins, persistence after reload, removal after an older copy reconnects, and permission changes after a roster refresh. Finally test the native pin and the styled card in WoWForever itself.

The addon never reveals stealthed/hidden players whose information the client does not expose, scans an entire zone, auto-targets enemies, or automatically attacks. It does not broadcast sightings as public guild chat messages. Shared sightings are approximate observations, not verified enemy coordinates.


### 0.5.2: whole-guild KoS entries

Open **KoS Guilds** beside Guild List and Personal List. Officers and granted editors can enter an enemy guild's full name and reason, then Add / Save, or target an opposing-faction member and click **Target Guild**. Select a guild row to remove it. Members can view the list and report sightings automatically.

Commands: `/kos addguild "Enemy Guild" Reason` and `/kos removeguild "Enemy Guild"`.

Guild rules match the full guild name (case-insensitive, repeated ordinary spaces normalized). Hyphens are preserved. The addon must be able to read the enemy player's guild through the game API; guildless players and hidden/unavailable guild information cannot match a guild rule. No offline guild roster is downloaded. Same-faction players remain excluded from shared KoS alerts. Individual player entries take precedence over guild rules when both match. Cooldowns are per enemy character.

Fresh guild-member sightings alert online addon users with the actual enemy name and the matching guild/reason. Guild rows show the most recently seen member and the spotter's position; right-click the row to pin it. Sightings are reports, not verified remote identity or exact enemy coordinates. Removing a guild stops future guild-rule matches; existing explicit player entries continue to apply.

Guild rules sync automatically with your own guild and stay separate from other guilds' lists. All participants should update to **0.5.2**: earlier versions cannot process guild rules or the new guild-tagged sightings. The optional aura listens to the same event and does not require a fresh import. Game-client detection still requires in-game verification.


### 0.5.7: officer Addon Users view

Officers can open **Addon Users** to see detected online guild members with the addon, their version and current editing access. Select a player, then click **Grant Access** or **Revoke Access**. Grants remain officer-only; delegated editors cannot grant access. Revoking a named grant does not remove rank-based permissions.

Detection runs automatically in the background. Nobody needs to type commands or submit reports. **Refresh Users** refreshes detection (30-second cooldown). Version 0.5.6+ supports this detection. Offline, outdated and non-responding clients are omitted; absence from this list does not prove the addon is not installed. The view is officer-only, session-only and resets on guild changes. Detection never grants access by itself.


### 0.5.8: Users & Access and grant confirmation

The **Users & Access** button is always visible at the top, including from Personal List. Data and controls remain officer-only; clicking without recognized officer access gives a permission diagnostic instead of silently hiding the entry point.

Click **Show: Addon Users** to switch to **Show: KoS Editors**. Addon Users shows detected online users. KoS Editors includes recognized officers and named grantees in the loaded guild roster, including offline users and users without a detected addon. Rows explicitly show **KoS editing: YES/NO**, role, detected version and online/offline state. Select a row to fill Grant Access / Revoke Access.

New grants and revocations show **Awaiting player confirmation**, **Confirmed by player**, or **Rejected: officer not recognized on their client**. The target must be online and using 0.5.8+ for confirmations; older clients can still accept compatible grants but will not acknowledge them. A queued/local grant is not proof the target accepted it. Clients continue to validate the sending officer themselves; there is no self-asserted officer bypass. If rejected, collect `/kos status` from the sending officer and affected recipient. Existing rank-based access is never revoked by removing a named grant.

### 0.5.14: Requests, nearby panel and local markers

- Added a Requests tab for members to suggest a player with a mandatory reason. Officers and addon administrators can approve or decline; approved players join the shared KoS list. Members see their own requests and statuses. Duplicate pending requests are blocked, with 30 seconds between submissions.
- Declined requests disappear after three days. Hidden decision records prevent old syncs from restoring them; a new incident can be submitted as a fresh request.
- Added an independent Nearby KoS panel. Right-click the minimap button or use `/kos nearby` to show/hide it. It lists currently visible enemy nameplates, with class-coloured names, levels, classes, guilds and local markers. It expands to eight rows, then scrolls. Click an entry to pin its last reported location, if available.
- Nearby panel position, visibility, collapse and pin state are saved. Pin locks its position. Settings is now a main-window tab with an auto-fade checkbox and faded-opacity slider (5–100%). An empty, unhovered panel uses the selected opacity; populated or hovered panels show at 100%.
- Added automatic local nameplate markers in skull, cross, square, moon, triangle, diamond, circle and star order. Additional visible matches use red skulls. These are personal artwork, not real raid markers, and need enemy nameplates enabled.
- Enemy levels now appear in chat and aura alerts, including shared sightings. Hidden levels show `??`.
- Fixed repeated access confirmations caused by routine list syncs.

All participating guild members should update for the new request and sighting messages. This remains a beta; report in-game layout or compatibility issues.
### 0.5.15: Correct target-marker artwork

- Fixed incorrect icon cropping that could display a murloc-like image instead of the intended skull, cross or other raid symbol.
- Nameplate markers and nearby-panel icons now use the client marker-artwork helper, with corrected four-row texture coordinates as a fallback.
- Markers remain local visual indicators. No automatic protected raid-target assignment is used.
### 0.5.16: Guild selection error fix

Fixed a Lua error when selecting a KoS guild without a recorded sighting. Pin Last Seen stays disabled until a valid location is available. Guild selections no longer fall back to character sightings with the same name.