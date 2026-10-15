# Modular interior and upgrades

## Interior modules
Every ModuleScript inside `src/server/core/interior/` is loaded automatically by `InteriorService`, sorted by its `order` field, and called whenever a building is placed or swapped. Drop a new file in there and it runs, nothing else to register.

A module is a table with any of these:
- `name` and `order` (lower runs first)
- `build(context)` runs after the building is placed. `context` has `player`, `plot`, `info`, `model` and `folder`. Put everything you create inside `context.folder` (a Folder named `Interior` inside the building), so it disappears with the building and is rebuilt on a swap.
- `onUpgradeChanged(context, upgradeId, level)` runs after a purchase.
- `destroy(context)` runs before the folder is removed.

`info` is the same table BuildingService hands out: `floor`, `door`, `seats`, `seatCount`, `forward`, `floorTopY` (the walking height at the door).

Modules shipped now:
- `Collision` builds invisible walls with a 7.6 stud doorway around the interior (found from the seat and slot markers), a walkable deck when the door sits above the slab (T2), and moves anyone standing on a wall line out to the front of the door.
- `UpgradeStations` builds one upgrade station per catalog entry just inside the door. Each level adds a glow and sparkles, a maxed station gets a gold crown.
- `WarmLights` hangs warm point lights along the aisle and brightens them a little with every upgrade level.
- `Beacon` raises a tier coloured pillar of light over the synagogue so it can be found from the plaza.
- `Celebrate` fires fireworks, confetti and a "TIER N!" banner in front of the building when the tier goes up.

`InteriorService.start()` also sets Invisicam camera occlusion (walls fade when the camera is outside) and a 350 stud max zoom so big buildings fit on screen.

## Ambient modules
Every ModuleScript inside `src/server/core/ambient/` is loaded by `AmbientService` at startup (after the plots exist), sorted by `order`, and its `build()` is called once. Use it for world decoration that does not belong to one player.

Modules shipped now:
- `Meadow` scatters flower clusters, rocks and trees over the open ground, away from the plaza, paths and plots.
- `Motes` drifts glowing motes over the plaza and each plot.
- `PlotBeacons` raises a gold pillar of light over every free ClaimPad and removes it when the plot is claimed.
- `Balloons` floats colourful balloons around the sky.

`Fx` (shared effect helpers) gained `firework`, `fireworkShow`, `beacon` and `sound`. Sound ids live in `Config.SOUNDS` and tier colours in `Config.TIER_COLORS`. `PlayerFx` gives each player a soft sparkle trail tinted by their tier.

## Upgrades
`src/shared/UpgradeCatalog.lua` is pure data plus small functions. To add an upgrade, add a table to `UpgradeCatalog.list` (id, name, blurb, effect, perLevel, baseCost, growth, maxLevel, color). Station, saving and attribute `Upg_<id>` appear automatically (stations use fixed spots, four fit now).

Effects wired in core today:
- `arrival_speed` adds to the arrival rate (on top of the other team's WelcomeBonus).
- `arrival_tip` gives money for each new arrival, scaled by building tier.
- `dues` gives money per seated person per second. It is added to `MoneyPerSecond` and shown separately in the player attribute `BonusPerSecond`.

To add a new effect type, add its function to `UpgradeCatalog` and read it where it applies (`UpgradeService` exposes providers that Economy and CongregationService call).

Levels are saved in the same DataStore record (`upgrades`) and restored on join.

## Contract notes
- New player attributes (extras, not in the frozen table): `Upg_<id>` levels, `BonusPerSecond`, `DataLoaded`.
- `MoneyPerSecond` now equals the contract formula plus `BonusPerSecond`. With no upgrades bought it is identical to the contract.
