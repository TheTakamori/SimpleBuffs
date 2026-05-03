# Simple Buffs

`Simple Buffs` shows buff and debuff timers for supported unit frames in small
configurable displays. It is built for World of Warcraft Retail
`12.0.5 (Midnight)` and uses Blizzard cooldown widgets for countdown text so
the UI can display aura timers without custom combat-state calculations.

Current version: `1.1.0`.

## Features

- Shows player, target, focus, pet, party, party pet, raid, raid pet, boss,
  arena, and arena pet buffs/debuffs by default.
- Lets each unit group choose display mode, attached position, layout, sort,
  filter, and style behavior from a dedicated unit tab.
- Includes hover explanations on option labels and controls.
- Provides standalone grouped displays for users who prefer a custom placement.
  Unlocked standalone displays move with Shift-drag.
- Provides per-unit-group icon size, spacing, max aura count, scale, countdown
  text, cooldown swipe, stack counts, and quick enable/disable controls.
- Lets users copy settings from one unit tab to another with a Copy From
  dropdown.
- Lets users lock or unlock standalone display movement from the options panel
  or minimap button.
- Uses event-driven aura updates instead of constant polling.
- Stores settings in `SimpleBuffsDB`.
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

## License

This project is released as `All Rights Reserved`.
