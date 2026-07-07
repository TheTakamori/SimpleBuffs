# Simple Buffs

`Simple Buffs` shows buff and debuff timers for supported unit frames in small
configurable displays. It is built for World of Warcraft Retail
`12.0.5 (Midnight)` and uses Blizzard cooldown widgets for countdown text so
the UI can display aura timers without custom combat-state calculations.

Current version: `1.3.0`.

## Features

- Shows player, target, focus, pet, party, party pet, raid, raid pet, boss,
  arena, and arena pet buffs/debuffs by default.
- Lets each unit group choose display mode, attached position, layout, sort,
  filter, and style behavior from a dedicated unit tab, with separate Buffs and
  Debuffs sub-tabs for per-type settings.
- Lets each unit group's buffs/debuffs render as the classic icon grid, or as a
  "Bar Stack" of labeled horizontal bars (icon + spell name + shrinking
  time-remaining fill + countdown), with its own Bar Width slider, a Show Icon
  toggle (on by default) to hide the leading icon and let the name fill the
  bar, and a dedicated Bar Sort dropdown (A-Z, Z-A, Time Left, or Max
  Duration, each ascending or descending).
- Includes hover explanations on option labels and controls.
- Provides standalone grouped displays for users who prefer a custom placement.
  Unlocked standalone displays move with Shift-drag.
- Provides per-aura-type icon size, spacing, max aura count, scale, countdown
  text, cooldown swipe, and enable/disable controls within each unit tab's
  Buffs and Debuffs sub-tabs.
- Lets users copy settings from one unit tab to another with a Copy From
  dropdown.
- Lets users lock or unlock standalone display movement from the options panel
  or minimap button.
- Uses event-driven aura updates instead of constant polling.
- Stores settings in `SimpleBuffsDB`. Existing settings migrate automatically
  when upgrading from 1.1.3 or earlier.
- Includes `package.py` to build a release zip without tests or local files.

## Slash Commands

- `/sbuff`: Open the Blizzard Settings panel.
- `/sbuff lock`: Lock movable standalone displays.
- `/sbuff unlock`: Unlock Shift-drag for standalone displays.
- `/sbuff reset`: Reset settings to defaults.

## Installing

1. Close World of Warcraft.
2. Copy the `SimpleBuffs` folder into `_retail_/Interface/AddOns/`.
3. Start the game and enable `Simple Buffs` from the addon list if needed.

## Notes

- Unit displays hide when their unit token does not currently exist.
- Attached mode uses stable Blizzard frames for player, target, focus, pet,
  party, party pet, raid, raid pet, boss, arena, and arena pet units when
  available.
- Right-click the minimap button to lock or unlock standalone display dragging.
- Aura icons pass mouse clicks through to frames underneath, so attached
  displays do not block unit frame interaction.
- Bar Stack's "Max Duration" sort options compare each aura's base duration
  locally, since Blizzard has no native sort rule for it. Aura duration data
  can be a Secret Value in restricted content (combat, instances, PvP, M+); if
  it can't be read safely, Max Duration sort silently falls back to leaving
  auras in their native scan order rather than reordering them. This is a
  Midnight platform limitation, not an addon bug.

## License

This project is released as `All Rights Reserved`.
