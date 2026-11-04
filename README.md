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
