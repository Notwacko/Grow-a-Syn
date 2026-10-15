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
- `Items` puts the player's placed ritual items into the building slots (see "Item shop" below). `Items.layout(model, floor, folder, entries)` is a pure placement function that tests can call with made up entries.

`InteriorService.start()` also sets a 350 stud max camera zoom so big buildings fit on screen. The interior walls are not solid for the camera, so `Collision` adds an invisible `CameraBox` part (tag `InteriorCameraBox`) covering the hall, and the client module `InteriorCamera` keeps the camera inside it while the player is inside. Invisicam is not used, it made walls flicker translucent.

## Cosmetics (outfits)
`src/shared/OutfitCatalog.lua` lists one outfit per building tier, from Everyday Rabbi (tier 1) through Reform, Conservative, Orthodox, Ultra-Orthodox and Hasidic to Haredi Festive (tier 7). Each has a `classic` and a `modest` piece list. `OutfitBuilder` turns piece ids into small welded parts on the avatar (hats, coats, sleeves, gartel, tzitzit, socks, skirts, head coverings, beard, sidelocks) and recolours the real kippah and tallit models. `CosmeticsService` wears the outfit that matches the player's `Tier` (selection `auto`) on every spawn and tier change, and saves the player's choice in the core DataStore (`cosmetics`).

The Wardrobe mirror (interior module `Wardrobe`) lets the player preview and pick any outfit: E for the next outfit, F to switch between classic and modest dress. Attributes `Outfit` and `OutfitStyle` show what is worn. To add an outfit, add a table to `OutfitCatalog.list` and any new pieces to `OutfitBuilder`.

Religious details to review (neutral choices, listed for the rabbi): the exact dress per movement, beard and sidelocks on the Ultra-Orthodox, Hasidic and Haredi outfits, the fur hat and silk coat at the top tier, and the modest dress options. Sephardic and Mizrahi players use the tier outfits until those ladders are specified.

## Progression fallback
`ProgressionFallback` creates the progression remotes (`RF_GetCatalog`, `RF_ChooseDenomination`, `RF_UpgradeBuilding`, the inventory ones and `RE_InventoryChanged`) only if they do not exist yet, and marks them with the attribute `CoreFallback`. It serves a catalog with the Ashkenazi ladder and implements choosing a denomination (at the minyan) and upgrading the building tier for money (land tier N minus 1 required). It also writes `Denomination`, `Tier` and `IncomeMult` and saves them. It switches itself off as soon as `workspace.ProgressionOnline` is true, and role B only needs to assign its own `OnServerInvoke` handlers to take over. The shop and inventory remotes are served by `ItemService`.

## Item shop
The shop is a restocking market for ritual items, modelled on the "grow" loop of the big simulator games.

- `src/shared/ItemCatalog.lua` is pure data: 8 categories (the contract ones) times 6 rarities = 48 items, with ids like `siddur_common`. The model is the category name, the rarity is a skin applied in code (`src/shared/ItemSkin.lua`). Prices, income bonus, growth time and stock odds are in the rarity and category tables.
- The shop restocks every 5 minutes. Stock for an epoch is derived from the epoch number, so every server shows the same stock at the same time. `workspace` attributes `ShopEpoch` and `ShopRestockAt` tell the client. Buying lowers the server's stock. The first siddur (common, 50 money) is always in stock.
- A bought item goes into the first free slot of its category and starts to grow. Growth only runs while the item is placed and is kept across sessions with a start time. The item scales up and its income bonus rises from 40 percent to 100 percent while it grows.
- When an item finishes growing it rolls a mutation: Gilded (12 percent, x1.5), Radiant (4 percent, x2.2) or Ancient (1 percent, x3.5). The result is saved.
- Merging three identical items gives the next rarity and takes the slot of a placed ingredient. Sefer Torah items have no merge and there is no sell or delete anywhere.
- `IncomeMult` is the tier multiplier times one plus the bonus of all placed items. It is recomputed every two seconds while anything grows.
- Items are saved in the core record under `progress.items` (uid, id, slot, grown seconds, start time, mutation).
- `ItemService.Changed`, `Grew` and `Matured` signals drive the visuals and income. Bought items fire `Bridge.Purchased` so the tutorial step advances.

## Events
`EventService` runs a Shabbat event 4 minutes after the server starts and then every 15 minutes: `Economy.setEventMult(2)`, warm golden light, and the workspace attributes `EventName` and `EventEndsAt` (the HUD shows a timer pill). It lasts 3 minutes. `EventService.trigger(seconds)` starts one on demand.

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
- New player attributes (extras, not in the frozen table): `Upg_<id>` levels, `BonusPerSecond`, `DataLoaded`. New workspace attributes: `ShopEpoch`, `ShopRestockAt`, `EventName`, `EventEndsAt`.
- `MoneyPerSecond` now equals the contract formula plus `BonusPerSecond`. With no upgrades bought it is identical to the contract.
