# Hardcore Challenges (WoW Classic Era)

`HardcoreChallenges` is a challenge-tracking addon for **WoW Classic Era**. Pick rulesets at level 1, track progress and failures, earn **account-wide** hub points, and show **display titles** to other players who use the addon.

## Features

- **Challenge selection** (level 1 only) and **active challenges** window (minimap after start)
- **Achievement-style toasts** when a challenge is credited to the **Account Hub** (queued if several complete at once); click toast to open the hub
- Fail-state and rule enforcement for restrictions (Hardcore, No Bank, No Mail, No World Buffs, mounts, hearthstone, etc.)
- **Progress** challenges: Slayer kill count, Single Spec, Dungeon Once, Crafted Locked (solo/duo), Exalted (racial capital rep)
- **Lore / quest** challenges detected on turn-in and on login where applicable
- **Account Hub**: each challenge key counts **once per account** toward total points
- **Titles**: choose a short title from hub-completed challenges; sync via addon messages (party/raid/guild/whisper chat)

## Categories (UI)

Order and labels live in `ui/chrome.lua` (`CHALLENGE_CATEGORY_ORDER`):

- **Lore** — quests, items, world goals  
- **Restrictions** — economy, travel, buffs, survival  
- **Progression** — builds, dungeons, reputation  
- **Alliance** / **Horde** — faction-specific goals  
- **Combat** — Slayer  

Add challenges in `core/challenges.lua` with matching `category` (and extend `chrome.lua` if you add a new section).

## Hub completion (summary)

- **Level 60:** Most active challenges grant hub credit when you hit 60 on a started run. Exceptions: `EXCLUDE_FROM_AUTO_60` in `core/hub.lua` (lore quests, attunements, Exalted, world-buff rule, etc.—they complete when their condition is met).
- **Quest lore / attunement:** Handled in `core/events.lua` (turn-in + entering world checks).
- **Slayer:** Hub credit when the kill goal is reached (combat log), not only at 60.
- **Paragon (All Challenges):** Unlocks in the hub when every non–hub-only challenge is completed there.

## Level 1 rule

- **Start / pick challenges** only at **level 1**.
- **Minimap** opens **Active Challenges** (and titles) on any level after a run has started.
- Above level 1 with **no** started run: minimap opens **Account Hub** only.
- **Reset character** / **Reset hub** are in the hub footer (with confirmations).

## Installation

1. Copy the `HardcoreChallenges` folder into `_classic_era_/Interface/AddOns/`.
2. Confirm `.../HardcoreChallenges/HardcoreChallenges.toc` exists.
3. Enable the addon in the character screen **AddOns** list.

## Release zip (CurseForge, WoWInterface, etc.)

Avoid zips that contain `__MACOSX/`, `._*`, `.git/`, or `.vscode/` (common with Finder “Compress”).

From the addon directory:

```bash
chmod +x scripts/make-release-zip.sh
./scripts/make-release-zip.sh
```

This creates `HardcoreChallenges-<version>-release.zip` (version from `## Version` in the `.toc`) with a single top-level `HardcoreChallenges/` folder.

Manual alternative (from the parent of the addon folder):

```bash
cd …/Interface/AddOns
COPYFILE_DISABLE=1 zip -r ~/Desktop/HardcoreChallenges.zip HardcoreChallenges \
  -x "HardcoreChallenges/.git/*" \
  -x "*__MACOSX*" \
  -x "*.DS_Store"
```

## Technical

- **Libraries:** Ace3 (Addon, Event, DB), LibDBIcon  
- **Saved variables:** `HardcoreChallengesDB` (per character), `HardcoreChallengesHubDB` (account hub)  
- **Toast sound:** `Sounds/AchievementSound1.ogg` (bundled)

See also **`CURSEFORGE.md`** for CurseForge project description text.
