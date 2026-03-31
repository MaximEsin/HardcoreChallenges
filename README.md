# Hardcore Challenges (WoW Classic Era)

`HardcoreChallenges` is a challenge-tracking addon for WoW Classic Era.  
It lets players pick rulesets, track progress/fail states, earn hub points, and display challenge titles.

## Features

- Challenge selection and active challenge UI
- Fail-state tracking for gameplay rules (Hardcore, No Bank, No Mail, etc.)
- Progress challenge support (Slayer kill count)
- Account Hub with completed challenge points (each key counts once per account)
- Display titles from completed challenges
- Addon-message sync between players with the addon:
  - selected title
  - active selected challenges
  - completed hub challenges

## Challenge categories (UI)

Challenges are grouped in the selection and active windows. Category order is defined in `ui/chrome.lua` (`CHALLENGE_CATEGORY_ORDER`):

- **Lore** — story / world goals (quests, items, locations)
- **Restrictions** — economy, travel, and survival rules
- **Progression** — builds, leveling paths, dungeon rules
- **Alliance** — faction-specific Alliance goals (level 60 champion, Onyxia attunement)
- **Horde** — faction-specific Horde goals (level 60 champion, Onyxia attunement)
- **Combat** — kill-based goals

Add new challenges in `core/challenges.lua` with `category` set to one of these ids (or extend the order/labels in `ui/chrome.lua`).

### Hub completion behavior

- **Level 60:** For most active challenges, reaching level 60 on a started character grants hub credit (see `ProcessHubLevel60Completions` in `core/hub.lua`). Exceptions are listed in `EXCLUDE_FROM_AUTO_60` (they complete only when their special rule is met).
- **Quest-based lore / attunement:** Completion is detected on **`QUEST_TURNED_IN`** and on login/entering world (`RunEnteringWorldChallengeChecks` in `core/events.lua`) via quest completion APIs, for:
  - **In Dreams** — quest `5944`
  - **Onyxia Attunement (Horde)** — quest `6602` (*Blood of the Black Dragon Champion*)
  - **Onyxia Attunement (Alliance)** — quest `6502` (*Drakefire Amulet*)
- **Level 60 faction champions:** `Level60Horde` / `Level60Alliance` still require the matching `UnitFactionGroup` when the level-60 hub pass runs.
- **Slayer:** Hub credit when kill goal is reached (combat log), not automatically at 60.

## Current challenges

| Category | Challenge | Notes |
|----------|-----------|--------|
| **Restrictions** | Hardcore | Death fails the challenge |
| | No Bank / No Mail / No Auction House | Using blocked services fails or is prevented |
| | No Mount / No Hearthstone | Mount / Hearthstone spell fails |
| | Self Found | Must keep Self-Found buff while active |
| | Single Continent | Must stay on start continent |
| **Progression** | Dungeon Once | Each 5-man dungeon map once; hub credit at 60 |
| | Crafted Locked (Solo / Duo) | Craft-only equip rules |
| | Single Spec | One talent tree only |
| **Lore** | Lord of the Rings | Destroy ring item `8350` in Blackrock Mountain |
| | Scarlet Tabard | Equip tabard item `23192` |
| | In Dreams | Complete quest `5944` |
| **Alliance** | Alliance Champion | Level 60 on Alliance |
| | Onyxia Attunement (Alliance) | Complete quest `6502` |
| **Horde** | Horde Champion | Level 60 on Horde |
| | Onyxia Attunement (Horde) | Complete quest `6602` |
| **Combat** | Slayer | 10 000 NPC kills (kill credit rules in `core/slayer.lua`) |
| *(hub only)* | All Challenges (Paragon) | Meta: every other challenge completed in hub |

## Level 1 rule

- **Choosing challenges** and pressing **Start** are only allowed at **level 1** (new run).
- **Active Challenges** (progress, failures, **Titles** tab) opens from the **minimap on any level** once a run has been started.
- If you are **above level 1** and **never started**, the minimap opens **Account Hub** only (you cannot begin a run mid-level).
- **Reset character** / **Reset hub** are in the Hub footer (with confirmation dialogs).

### Crafted Lock chat notices

- On load, the addon prints a short **loaded** line with the version.
- When a new equippable item ID is **crafted** into your bags, it prints that the ID was **added to your allowed list**.
- In **duo** mode, after you open trade with your saved partner and the allowlists **merge**, it prints how many **new** allowed IDs you gained from them (if any).

## Installation (manual)

1. Download/clone this repository.
2. Put the folder `HardcoreChallenges` into:
   - `World of Warcraft/_classic_era_/Interface/AddOns/`
3. Ensure the path:
   - `.../AddOns/HardcoreChallenges/HardcoreChallenges.toc`
4. Enable the addon in the client.

## Packaging for uploads (CurseForge, WoWInterface, etc.)

Hosts often reject zips that contain **`__MACOSX/`**, **`._*`** (macOS metadata), **`.git/`**, or **`.vscode/`**.  
That happens if you use **Finder → Compress** on a folder that is also a git checkout.

**Option A — script (recommended on macOS):** from the addon folder:

```bash
chmod +x scripts/make-release-zip.sh
./scripts/make-release-zip.sh
```

This writes `HardcoreChallenges-<version>-release.zip` next to the addon (version is read from `## Version` in `HardcoreChallenges.toc`). Inside: one top-level folder `HardcoreChallenges/` with `HardcoreChallenges.toc`.

**Option B — GitHub:** **Code → Download ZIP** gives an archive **without `.git`**, but re-compressing on Mac can still add `__MACOSX`. Prefer the script or terminal `zip` with `COPYFILE_DISABLE=1`.

**Option C — manual `zip` from the parent of the addon:**

```bash
cd …/Interface/AddOns
COPYFILE_DISABLE=1 zip -r ~/Desktop/HardcoreChallenges.zip HardcoreChallenges \
  -x "HardcoreChallenges/.git/*" \
  -x "*__MACOSX*" \
  -x "*.DS_Store"
```

## Development notes

- Ace3 + LibDBIcon.
- Metadata: `HardcoreChallenges.toc`.
- Saved variables:
  - `HardcoreChallengesDB` — per-character profile (challenges, progress)
  - `HardcoreChallengesHubDB` — account hub completed keys
