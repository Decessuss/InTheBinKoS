# <in the bin> KoS List

A shared guild KoS list and private personal avoid list for **WoWForever**. One addon serves the whole guild: rank permissions and named editor grants control the management tools. This repository publishes only the WoWForever edition.

## Install and update

In **WowUp**, select **WoWForever**, choose **Install from URL**, and enter:

`https://github.com/Decessuss/InTheBinKoS`

Once a packaged GitHub release is published, WowUp can track subsequent releases. Right-click the addon in WowUp to enable Auto Update if desired. Updater support and release recognition still need a first live WowUp install test.

For manual installation, download the appropriate ZIP from [Releases](https://github.com/Decessuss/InTheBinKoS/releases), extract **InTheBinKoS** into your client's `Interface/AddOns` folder and restart WoW. Do not use GitHub's automatically generated source ZIP as the addon installer.

The release asset is named **InTheBinKoS-vVERSION-forever.zip**. TBC and Retail packages are not published by this repository.

All packages contain one standalone `InTheBinKoS` folder. No required addon dependency is included. WeakAuras/ForeverAuras is optional for the styled card; TomTom supplies waypoints on clients without native pin APIs.

## What it does

- Guild list with search, pagination, newest-sighting sorting and saved spotter positions.
- Officer-chat speakers and the guild master can edit and grant named characters editing access. Granted editors cannot grant further access.
- Members get a compact read-only guild view and can report sightings automatically.
- Any online guild peer can serve its cached list; officers need not be online for list sync.
- Fresh sightings generate private chat, sound and an aura event for participating guild members. Cached history stays silent.
- Personal List tab with character-private same-faction reminders and party/raid warnings. These notes never sync.
- Guild-logo window background and draggable minimap button.

Open the window with the minimap button or `/kos`. Use `/kos test` for a private test notification. Editing privileges never determine whether you can report a sighting.

Locations are the **spotter's position when detection happened**, not live enemy coordinates. Detection relies on units the game exposes through mouseover, target or nameplates. Reports are rate-limited; this is not a zone scanner. Cached list syncing trusts saved guild-peer data, while new editor grants require an actual officer sender.

## Aura setup

Import [the ForeverAuras string](docs/ForeverKoS-ForeverAura-import.txt) with `/fa`. The card listens to `FOREVER_KOS_SPOTTED`; folder/display renames do not change that event. Open `/fa`, select Import, paste the entire line, confirm, close the editor and run `/kos test`.

## Migrating an earlier test installation

Close WoW and back up your saved data before migration. The current folder and TOC are `InTheBinKoS/InTheBinKoS.toc`. If you already use that folder, replace its contents and retain your account's saved data. If upgrading from a full addon folder named `ForeverKoS`, do not run both full implementations simultaneously. With WoW closed, copy the account's `SavedVariables/ForeverKoS.lua` to `SavedVariables/InTheBinKoS.lua` if the destination does not already exist, then disable/remove the old full addon folder. If both saved files already exist, retain both backups and ask for a merge rather than overwriting either. Existing users with only the tiny legacy data loader can leave it installed temporarily; this clean release does not require it.

Internal database names stay `ForeverKoSDB` and `ForeverKoSTestDB` for compatibility. Real saved lists and account files are not part of this repository. This release contains **no hard-coded character permission overrides**; the Decshock testing bypass is not included.

## Release status

TBC TomTom links, Retail native pins, shared guild chat/aura alerts and list changes have been tested in-game during development. Personal warnings, permission grants, peer-sync edge cases and other checks also have simulated Lua tests. WoWForever-specific behaviour and first-time WowUp installation need in-game verification. Do not mistake an interface-version declaration for proof that every client behaviour has been tested.

[Full feature guide](docs/FULL-GUIDE.md) describes the development editions and all features; installation paths/folder names in older guide sections refer to the earlier test packaging. This README is authoritative for the repository release.

## Publishing an update

Change and test the code, update the TOC version, then push a version tag such as `v0.5.1`. GitHub Actions runs the Lua checks and builds one WoWForever ZIP. If validation passes, it publishes a GitHub release with that asset. A tag such as `v0.5.1-beta.1` is published as a prerelease. No personal access token or additional publishing service is needed: Actions uses its own repository-scoped token.

The repository uses a small explicit packaging script so release archives contain only runtime files, documentation, aura strings and the guild artwork. There is no install-time build step for guild members.

## Development checks

```sh
python -m pip install -r requirements-dev.txt
python tests/run_tests.py
python scripts/package.py --version 0.5.1
```

Tests use Lua 5.1 through Lupa and simulated WoW APIs. They do not replace multiplayer/client testing. No open-source license has been selected yet; the guild logo is supplied artwork.

### 0.5.1: first and last names

Enter the full character name in the UI, or use `/kos add "First Last" Reason` and `/kos remove "First Last"`. Guild entries, named editor grants, sightings and private lists support spaces. Update every guild member to 0.5.1 for full-name syncing. Existing single-word entries remain compatible. No BattleTag override is included.


### 0.5.2: whole-guild KoS entries

Open **KoS Guilds** beside Guild List and Personal List. Officers and granted editors can enter an enemy guild's full name and reason, then Add / Save, or target an opposing-faction member and click **Target Guild**. Select a guild row to remove it. Members can view the list and report sightings automatically.

Commands: `/kos addguild "Enemy Guild" Reason` and `/kos removeguild "Enemy Guild"`.

Guild rules match the full guild name (case-insensitive, repeated ordinary spaces normalized). Hyphens are preserved. The addon must be able to read the enemy player's guild through the game API; guildless players and hidden/unavailable guild information cannot match a guild rule. No offline guild roster is downloaded. Same-faction players remain excluded from shared KoS alerts. Individual player entries take precedence over guild rules when both match. Cooldowns are per enemy character.

Fresh guild-member sightings alert online addon users with the actual enemy name and the matching guild/reason. Guild rows show the most recently seen member and the spotter's position; right-click the row to pin it. Sightings are reports, not verified remote identity or exact enemy coordinates. Removing a guild stops future guild-rule matches; existing explicit player entries continue to apply.

Guild rules sync automatically with your own guild and stay separate from other guilds' lists. All participants should update to **0.5.2**: earlier versions cannot process guild rules or the new guild-tagged sightings. The optional aura listens to the same event and does not require a fresh import. Game-client detection still requires in-game verification.


### Automated CurseForge publishing

Version tags (`v*`) validate the addon, publish the GitHub ZIP and submit the same package to CurseForge project 1784566. CurseForge uploads are Beta (Alpha for `-alpha` tags), WoW Forever 1.60.1 only, and publish automatically after approval. The GitHub release and CurseForge upload run independently after validation, so a CurseForge failure does not block GitHub downloads.

One-time setup: create a CurseForge **author upload token** and store it in GitHub repository Settings → Secrets and variables → Actions as **CF_API_TOKEN**. Never commit the token. Run the release workflow manually with **check_curseforge** enabled to verify the token and version lookup without uploading a duplicate file. A missing/invalid secret fails clearly. This does not bypass CurseForge moderation.

Before retrying an upload job after a connection error, check CurseForge Files first: the server might have accepted it before the timeout. Do not rerun successful upload jobs, as CurseForge can create duplicate files. Version 0.5.2 was already uploaded manually and should not be submitted again.


### 0.5.3: officer access compatibility

Own-player officer detection now also uses the game's native officer query, without waiting for the roster cache. Rank permission lookup prefers GUID-based rank order where available, falls back to the existing rank-index lookup, and refreshes on guild-rank changes. A player's native officer result is never used to authorize another sender. Missing/unreadable permission data does not grant remote access. `/kos status` includes native officer, cached rank, resolved rank order and officer-chat speak diagnostics. All guild members should update so sender validation uses the new lookup. The reported in-game issue still needs confirmation from the affected officer after updating.


### 0.5.4: Enemy spotted radio alert

Shared KoS sightings and Test Alert now use the classic Counter-Strike 1.6 "Enemy spotted" radio clip. The Sound checkbox still mutes it. Missing/unsupported audio falls back to the previous alert tone. Personal-list reminders keep their existing sound. Audio credits are included in Media/CREDITS.txt.


### 0.5.5: corrected alert recording

Replaced the previous radio clip with the exact Enemy spotted MP3 supplied by the addon author. Sound controls and fallback behavior are unchanged.


### 0.5.7: officer Addon Users view

Officers can open **Addon Users** to see detected online guild members with the addon, their version and current editing access. Select a player, then click **Grant Access** or **Revoke Access**. Grants remain officer-only; delegated editors cannot grant access. Revoking a named grant does not remove rank-based permissions.

Detection runs automatically in the background. Nobody needs to type commands or submit reports. **Refresh Users** refreshes detection (30-second cooldown). Version 0.5.6+ supports this detection. Offline, outdated and non-responding clients are omitted; absence from this list does not prove the addon is not installed. The view is officer-only, session-only and resets on guild changes. Detection never grants access by itself.


### 0.5.8: Users & Access and grant confirmation

The **Users & Access** button is always visible at the top, including from Personal List. Data and controls remain officer-only; clicking without recognized officer access gives a permission diagnostic instead of silently hiding the entry point.

Click **Show: Addon Users** to switch to **Show: KoS Editors**. Addon Users shows detected online users. KoS Editors includes recognized officers and named grantees in the loaded guild roster, including offline users and users without a detected addon. Rows explicitly show **KoS editing: YES/NO**, role, detected version and online/offline state. Select a row to fill Grant Access / Revoke Access.

New grants and revocations show **Waiting for recipient addon**, **Confirmed by recipient addon**, or **Rejected: officer not recognized on their client**. The target must be online and using 0.5.8+ for confirmations; older clients can still accept compatible grants but will not acknowledge them. A queued/local grant is not proof the target accepted it. Clients continue to validate the sending officer themselves; there is no self-asserted officer bypass. If rejected, collect `/kos status` from the sending officer and affected recipient. Existing rank-based access is never revoked by removing a named grant.


### 0.5.9: Realm-independent character access

Character identity now uses the full first and last name without realm suffixes across guild rosters, grants, messages, sightings and personal lists. Existing saved records migrate automatically, retaining legacy snapshots. Characters with the same name across realms share an identity; guild lists remain separate by guild name. Alts require separate grants.

Grant confirmation is an automatic reply from the recipient addon, not a popup. Both players should update to 0.5.9. Mixed-realm grant, acknowledgement and revocation tests pass; in-game verification is still required.


### 0.5.10: WoWForever surname compatibility

Fixes character identity when WoWForever returns first name and surname separately from UnitFullName. Full names now match guild roster entries so existing named access grants apply correctly. The same name handling is used for sightings and personal lists. Confirmed in-game with an existing grant to Decessuss Reaper.

Adds member-accessible /kos accessdebug to inspect roster identity and trace incoming grants. Diagnostics are off by default; use /kos accessdebug off to stop them. No confirmation popup is required.


### 0.5.11: Add a targeted player's guild

Open KoS Guilds, target an opposing-faction player, and click Target's Guild. This fills the guild name without saving immediately. Enter an optional reason and click Add / Save to confirm. Officers and granted editors can save; the entry syncs through the existing guild KoS system. Guildless, unavailable, non-player and same-faction targets show a message instead.


### 0.5.12: Guild alert throttle

Guild-wide KoS alerts now share a 60-second cooldown per enemy guild across local and received sightings. Chat, sound and aura notifications are throttled together; last-known locations continue updating. Different enemy guilds and individually listed players retain independent alerts.


### 0.5.13: Login update notification

On login, the addon automatically requests versions from online guild members. If a newer stable release is detected, a chat notice directs the player to update through CurseForge or WowUp. The notice appears once per session, works for ordinary members, and does not open a popup or play a sound. Version checks use guild addon messages, not a direct connection to CurseForge; a newer version must be running on an online guild member to be detected.

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
### 0.5.17: Personal PvP records in tooltips

- Enemy player tooltips now show your wins and losses against that player, whether or not they are on KoS. Friendly tooltips do not show the record.
- Wins count killing blows from you or your pet. Losses use confirmed kill events or an identifiable fatal hit from your death recap. Assists and unidentified deaths are not counted.
- Records are saved separately for each character, work outside a guild and start from installation. Past fights cannot be recovered.
- Added “Show PvP record in player tooltips” to Settings. Turning it off hides the display while tracking continues.
- Uses the dedicated kill event and death recap without registering the blocked legacy combat-log event.

The local Oven Baked preview numbers are not included in this release.

## 0.6.0 beta

**Counting starts with this patch.** Existing PvP wins, losses, killing-blow/assist totals and guild leaderboard summaries reset once when you first load 0.6.0. KoS lists, requests, permissions and settings are preserved.

- Credited assists now count toward wins when the game's honorable-kill message identifies the defeated player. Unnamed honor rewards are not guessed.
- Killing blows and assists are tracked separately and shown below the combined win/loss record in enemy player tooltips. Duplicate signals for the same kill do not award another win.
- Added a **PvP** tab with personal **Top Kills**, **Most Deaths** and **Recent Opponents** views. Recent Opponents shows the latest recorded encounter per opponent.
- Added a **Guild** leaderboard showing members' tracked wins and their most-killed opponent. It shares summaries rather than full personal histories. Members need this update to participate; offline entries show their last-shared totals.
- Battleground and arena encounters do not add wins, assists or losses. These records are for world PvP.

Update through CurseForge or WowUp and restart the game to load the new files. This remains a beta; report any tracking or layout issues.
