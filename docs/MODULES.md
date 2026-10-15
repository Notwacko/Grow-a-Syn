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

- `src/shared/ItemCatalog.lua` is pure data: 8 categories (the contract ones) times 6 rarities = 48 items, with ids like `siddur_common`. The model is the category name, the rarity is a skin applied in code (`src/shared/ItemSkin.lua`).
- Each shop shows 8 shelf slots that restock every 5 minutes (4 with the Swift Delivery pass). The stock for an epoch comes from the epoch number, so all servers agree. Fair odds: the rarity weights are in `ItemCatalog.RARITIES`, a Rare or better is guaranteed every 6 restocks, an Epic every 18 and a Legendary every 60, and a Simple Siddur is always on a permanent starter shelf. The Odds button in the shop shows all of it (`RF_GetCatalog` returns `odds`, `pity`).
- Prices scale by 4x per building stage (`Balance.priceScale`). Income is multiplied by 3x per stage (`Balance.TIER_MULT`).
- A bought item goes into the first free slot of its category and starts to grow. Growth only runs while the item is placed and is kept across sessions with a start time. Growth speed is the player attribute `GrowthRate` (Rapid Growth pass, Growth Lamp). Growth raises the item bonus from 40 percent to 100 percent.
- When an item finishes growing it rolls a mutation: Polished (6 percent, x1.5), Gilded (2.5 percent, x3), Radiant (1 percent, x6), Luminous (0.4 percent, x15) or Ancient (0.1 percent, x50). Golden Dew (from the wheel) guarantees a mutation of x3 or better.
- Merging three identical items gives the next rarity. Three identical Mythical items merge into the same item with one more star (up to 10 stars, big income multipliers). Sefer Torah items never merge and there is no sell or delete anywhere. `ItemService.mergeAll` powers the Quick Merge pass.
- `IncomeMult` is computed by `IncomeService` as the product of registered factors: stage multiplier, items, Membership Desk, Collection Book, Legacy, pets and friends. Each system registers its own factor.
- Items are saved in the core record under `progress.items` (uid, id, slot, grown seconds, start time, mutation, star).
- `ItemService.Changed`, `Grew`, `Matured`, `Bought`, `Merged` signals drive visuals, quests and the collection book. Bought items fire `Bridge.Purchased` so the tutorial step advances.

## Game systems (RF_Game)
`GameService` registers one module per system and exposes `RF_Game(action, payload)` where action is `service.action`, plus `sync` (all sections) and the server push `RE_Game(kind, payload)`. The client keeps sections in `ui/Store.lua`. All of them save under `data.sections` through `DataService.registerSection` (the `state` section is `PlayerState`, a small key value store).

| Service | What it does | Actions |
|---|---|---|
| BoostService | Festival Boost and Growth Lamp timers, pass effects on `BoostMult`, `GrowthRate`, `WelcomeBonus` | none |
| CollectionBook | discovered items, milestone rewards at 10/25/50/75/100 percent, permanent income bonus up to +20 percent | `claim` |
| LegacyService | prestige. Unlocks at stage 4. Points from lifetime earnings, income x(1 + 0.2 per point), heirlooms, Torah always kept | `info`, `confirm` |
| DailyService | 7 day calendar, 36 hour window, freezes, rewards in minutes of income, day 7 gives an item | `claim` |
| QuestService | 3 daily quests and 5 weekly goals, rewards in minutes of income | `claim` |
| OfflineService | earnings while away (25 percent, 4 to 12 hour cap), welcome back claim | `claim` |
| SpinService | one free wheel spin per day, honest odds, server picks the prize first | `spin`, `collect` |
| PetService | eggs for in-game money, pity, duplicates level pets, income bonus, follow you | `hatch`, `equip`, `unequip` |
| WardrobeService | cosmetics catalog, ownership, equip per slot, effects | `buy`, `equip`, `unequip`, `outfit`, `style` |
| MonetizationService | game passes, developer products, receipts, fixed outcome Robux items | `buyPass`, `buyProduct` |
| LeaderboardService | weekly OrderedDataStore boards (collector score and congregation size) | `refresh` |
| SettingsService | sound, colorblind colors, pets visibility | `set` |
| FriendsBonus | +5 percent income per friend in the server (max 5) | none |

Every action is rate limited per player and payloads are size checked (`GameService`). Rewards come from `Rewards.grantMinutes` (income minutes with a floor) and `Rewards.grantItem`.

## Congregants
`NpcAvatar` builds real R15 avatars (`Players:CreateHumanoidModelFromDescription`, six body shapes, kids at 0.72 scale) with a skin tone, hair, shirt and trouser colors and a list of `ofit_*` pieces picked by the building stage (casual kippot at the start, then jackets, hats and long coats toward Hasidic). The root is anchored, walking uses the default R15 walk animation, greeters wave, and seated guests get a baked sitting pose through the joint offsets, after which the Humanoid and Animator are removed. If the avatar templates cannot be built the old toy models are used.

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
`src/shared/UpgradeCatalog.lua` is pure data plus small functions. There is no maximum level: cost is `baseCost * 1.15^level` (`Balance.upgradeCost`) and the effect grows linearly to level 25, then at a quarter of the rate (`Balance.upgradeTotal`). The station shows "Level N" and five pips that cycle, with a crown from level 25.

Effects wired in core today:
- `arrival_speed` (Welcome Table) adds to the arrival rate.
- `arrival_tip` (Kiddush Table) gives money for each new arrival, scaled by the stage multiplier.
- `income` (Membership Desk) multiplies all income through `IncomeService`.

Levels are saved in the same DataStore record (`upgrades`) and restored on join. Legacy resets them.

## Contract notes
- New player attributes (extras, not in the frozen table): `Upg_<id>` levels, `BonusPerSecond`, `DataLoaded`, `GrowthRate`, `GrowthEndsAt`, `PetsEquipped`, `GoldenDew`, `FriendsBonus`, `FriendsCount`, `Pass_<key>`, `PassesLoaded`, `ShopEpoch`, `ShopRestockAt`, `ShopRestockSeconds`. New workspace attributes: `EventName`, `EventEndsAt`. `BoostMult` is now 1 plus the sum of active boosts (Double Income, Patron, Festival), which matches the contract when nothing is active.
- `MoneyPerSecond` equals the contract formula (`Congregation * IncomeMult * BoostMult * EventMult` after the minyan). `IncomeMult` is owned by `IncomeService` while `ProgressionOnline` is false.
