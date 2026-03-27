# Hardcore Challenges (WoW Classic Era)

`HardcoreChallenges` is a challenge-tracking addon for WoW Classic Era.  
It lets players pick rulesets, track progress/fail states, earn hub points, and display challenge titles.

## Features

- Challenge selection and active challenge UI
- Fail-state tracking for gameplay rules (Hardcore, No Bank, No Mail, etc.)
- Progress challenge support (Slayer kills)
- Account Hub with completed challenge points
- Display titles from completed challenges
- Addon-message sync between players with the addon:
  - selected title
  - active selected challenges
  - completed hub challenges

## Challenge categories (UI)

Challenges are grouped in the selection and active windows:

- **Lore** — story / world flavoured goals (expand here over time)
- **Restrictions** — economy, travel, and survival rules
- **Progression** — builds, leveling, dungeon rules
- **Combat** — kill-based goals

Add new challenges in `core/challenges.lua` with `category = "Lore"` (or another id from `UI.CHALLENGE_CATEGORY_ORDER` in `ui/chrome.lua`).

## Current Challenges

- Hardcore
- No Bank
- No Mail
- No Auction House
- No Mount
- No Hearthstone
- Dungeon Once (each 5-man dungeon map only once per character)
- Self Found
- Single Continent
- Crafted Locked (Solo / Duo)
- Single Spec
- Slayer
- Lord of the Rings (destroy `item:8350` in Blackrock Mountain)
- Scarlet Tabard (equip `item:23192`)
- Horde Champion (reach level 60 on Horde)
- Alliance Champion (reach level 60 on Alliance)
- Meta: All Challenges (hub-only)

## Installation (manual)

1. Download/clone this repository.
2. Put the folder `HardcoreChallenges` into:
   - `World of Warcraft/_classic_era_/Interface/AddOns/`
3. Make sure the final path is:
   - `.../AddOns/HardcoreChallenges/HardcoreChallenges.toc`
4. Start/restart the game and enable the addon.

## Development Notes

- Project uses Ace3 and LibDBIcon.
- Addon metadata is in `HardcoreChallenges.toc`.
- Character/account data:
  - `HardcoreChallengesDB`
  - `HardcoreChallengesHubDB`

