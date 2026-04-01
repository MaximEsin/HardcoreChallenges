# Hardcore Challenges — CurseForge / project page copy

Use the sections below in your CurseForge **Description** (Markdown is supported). Trim or merge as you like.

---

## Summary

Pick hardcore-style rules at **level 1**, track them on your run, and earn **account-wide** points in the **Account Hub**. Show a **title** from completed challenges to other players who use the addon. **WoW Classic Era.**

## What it does

- **Challenge picker** at level 1; **active window** from the **minimap** after you start a run  
- **Account Hub**: each challenge counts **once per account** toward your total score  
- **Toasts** (WoW achievement–style alerts) when a challenge is added to the hub; **multiple completions queue** one after another  
- **Titles** tab: equip a short label; synced via addon messages in guild, party, raid, whisper  
- Rules enforcement and fail tracking for restrictions (e.g. no bank/mail/AH, no mounts/hearth, **no world buffs**, Self-Found, single continent, crafted-lock gear, single talent tree)  
- **Lore & attunement** goals (quests, items, faction reps) where supported  
- **Slayer** combat challenge with kill counting  

## Who it’s for

Players doing **self-imposed hardcore or challenge runs** who want a clear UI, account-wide “trophy” progress, and optional visible titles for the community.

## How to start

1. Create or use a character at **level 1**.  
2. Open the addon from the **minimap**, choose challenges, press **Start**.  
3. Use **Active Challenges** during the run; open **Account Hub** anytime for account progress.  

**Note:** You cannot start a new challenge loadout above level 1 (by design).

## Slash commands

There is no required slash command; the **minimap button** is the main entry. (If you add commands later, document them here.)

## Dependencies / libraries

Embedded: **Ace3**, **LibDBIcon**. No separate download required.

## Localization

Primarily **English** UI strings; some messages are generic. Faction names for the **Exalted** challenge use the client language when the API provides them.

## Permissions / privacy

Uses **addon messages** only to exchange **title** and **challenge profile** metadata with other clients that run this addon (typical channels: guild, party, raid, whisper). No external servers.

## Support & source

Issues and source: your **GitHub** or **repository** link (add here).  
Latest **release zip** should be built with the included `scripts/make-release-zip.sh` so the archive is clean for CurseForge upload.

---

*Replace the “Support & source” line with your real links before publishing.*
