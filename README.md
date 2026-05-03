# Simple Buffs

`Simple Buffs` shows buff and debuff timers for supported unit frames in small
configurable displays. It is built for World of Warcraft Retail
`12.0.5 (Midnight)` and uses Blizzard cooldown widgets for countdown text so
the UI can display aura timers without custom combat-state calculations.

Current version: `0.0.4`.

## Features

- Shows player, target, focus, pet, party, party pet, raid, raid pet, boss,
  arena, and arena pet buffs/debuffs by default.
- Supports attached displays near stable Blizzard unit frames, including party
  frames when Blizzard exposes a usable anchor.
- Provides standalone grouped displays for units without attached anchors or
  for users who prefer a custom placement. Unlocked standalone displays move
  with Shift-drag.
- Provides configurable icon size, spacing, layout, max aura count, sorting,
  basic filtering, and quick enable/disable controls for all unit groups.
- Uses event-driven aura updates instead of constant polling.
- Stores settings in `SimpleBuffsDB`.

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
- Attached mode uses stable Blizzard frames for player, target, focus, pet, and
  party frames when available. Standalone grouped displays are used for units
  without reliable attached anchors.
- Right-click the minimap button to lock or unlock standalone display dragging.

## License

This project is released as `All Rights Reserved`.
