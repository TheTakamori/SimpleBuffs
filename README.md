# Simple Buffs

`Simple Buffs` shows buff and debuff timers for supported unit frames in small
configurable displays. It is built for World of Warcraft Retail
`12.0.5 (Midnight)` and uses Blizzard cooldown widgets for countdown text so
the UI can display aura timers without custom combat-state calculations.

Current version: `1.6.1`.

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
  bar, a dedicated Bar Sort dropdown (A-Z, Z-A, Time Left, or Max Duration,
  each ascending or descending), and a Bar Anchor dropdown (Top or Bottom)
  for standalone (movable) displays: Bottom (default) keeps the top of the
  display fixed and grows downward as bars are added, Top keeps the bottom
  fixed and grows upward instead. Bars are still ordered by Bar Sort either
  way; only which edge stays put changes. Attached displays aren't affected
  by this setting yet.
- Adds a "Manage Auras" tab alongside Buffs/Debuffs on every unit tab, listing
  every buff/debuff ever seen on that unit with a checkbox to hide or show it
  (applies to both Icon and Bar Stack styles) and a Forget button to drop it
  from the list. New auras are discovered automatically, independent of that
  unit's Filter/Max Auras display settings, so the list reflects everything
  that can appear, not just what's currently configured to show. Hidden/known
  auras are scoped per unit group and are not carried over by Copy From. Each
  row shows whether the entry is a Buff or Debuff and, on hover, that spell's
  own Blizzard tooltip. A Show dropdown filters the list to Buffs, Debuffs, or
  Both, and a Sort dropdown orders it A-Z/Z-A or by when each aura was first
  or most recently seen (each ascending or descending).
- Adds a Simulate toggle to each unit tab's Buffs and Debuffs sub-tabs, right
  above Copy From. Turning it on shows several sample auras (varied
  durations, stack counts, and icons) so the current Style/Layout/Sort/Filter
  configuration can be previewed and tuned without needing real buffs or
  debuffs active. The sample count cycles up and down every couple of
  seconds while it's on, so you can watch the display actually grow and
  shrink - handy for checking a Bar Anchor or Layout choice looks right.
  Requires the unit to currently exist (e.g. a target/focus selected); it's a
  preview-only toggle that is never saved and always resets off on reload, so
  it can't accidentally leave fake auras showing later.
- Adds a "Hide Blizzard Player Buffs" toggle on the Player unit tab that hides
  Blizzard's own default player buff bar (and weapon enchant buffs) near the
  minimap, so only Simple Buffs' own display shows. Saved per character and
  applies immediately.
- Includes hover explanations on option labels and controls.
- Provides standalone grouped displays for users who prefer a custom placement.
  Buffs and Debuffs are separate standalone displays per unit group, so they
  can be dragged to different places on screen independently instead of
  moving together as one group. Unlocked standalone displays move with
  Shift-drag.
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
- Manage Auras hiding remembers each aura's spell ID the first time it can be
  read safely, then reuses that instead of re-reading it, so hiding keeps
  working through combat/instances/PvP/M+ even once Blizzard starts marking
  that aura's data as a Secret Value. A hidden aura applied for the very first
  time while already in a restricted context can't be identified yet and will
  briefly show until it's next seen outside that context. This is a Midnight
  platform limitation, not an addon bug.

## License

This project is released as `All Rights Reserved`.
