# Simple Buffs

`Simple Buffs` shows buff and debuff timers for supported unit frames in small
configurable displays. It is built for World of Warcraft Retail
`12.0.5 (Midnight)` and uses Blizzard cooldown widgets for countdown text so
the UI can display aura timers without custom combat-state calculations.

## Features

- Shows core, party, raid, boss, arena, pet, and nameplate buffs/debuffs by
  default.
- Supports attached displays near Blizzard unit frames and standalone
  draggable grouped displays.
- Provides configurable icon size, spacing, layout, max aura count, sorting,
  and basic filtering.
- Uses event-driven aura updates instead of constant polling.
- Stores settings in `SimpleBuffsDB`.

## Slash Commands

- `/sbuff`: Open the Blizzard Settings panel.
- `/sbuff lock`: Lock movable standalone displays.
- `/sbuff unlock`: Unlock movable standalone displays.
- `/sbuff reset`: Reset settings to defaults.

## Installing

1. Close World of Warcraft.
2. Copy the `SimpleBuffs` folder into `_retail_/Interface/AddOns/`.
3. Start the game and enable `Simple Buffs` from the addon list if needed.

## Notes

- Unit displays hide when their unit token does not currently exist.
- Attached mode uses stable Blizzard frames for player, target, focus, and pet.
  Standalone grouped displays are used for the larger unit categories.

## License

This project is released as `All Rights Reserved`.
