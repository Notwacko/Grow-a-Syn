# Core (role A) integration notes

Everything here is what core actually does at runtime. The frozen contract is unchanged; additions are marked (extra).

## Startup order
`CoreMain.server.lua` builds lighting and the world, builds or adopts `workspace.Plots`, binds the Bridge and remotes, then sets `workspace.CoreOnline = true` last. If `workspace.Plots` already has Plot1 to Plot8 models, core uses them and only fills in missing parts.

## Player attributes
- Core writes: Money, MoneyPerSecond, Congregation, MaxCongregation, PlotId, LandTier, TutorialStep, HasMinyan.
- Core only reads: Denomination, Tier, IncomeMult, WelcomeBonus, BoostMult. Missing values use the 4.3 defaults. Core never writes them.
- (extra) `DataLoaded` boolean on the player, true once the core DataStore load succeeded.
- Congregation counts people who are seated (a congregant counts when they sit). At high seat counts only some have a visible model, the rest are "virtual" but still count for income.
- Before the minyan, arrivals come every 3 seconds and are capped at 9 people until tutorial step 4.

## Plots and buildings
- `Plot.Building` is a container Model. The synagogue is placed inside it as a child Model named after the model (`starter`, `ashkenazi_T3`, ...). Find parts with recursive searches, for example `plot.Building:FindFirstChild("Slots", true)`.
- The building model always has PrimaryPart `Floor`, a `Door`, a `Seats` folder and a `Slots` folder with all 26 slot names. Missing slots are created at default positions, so Slot lookups never fail.
- `BuildingVersion` on the plot is incremented after the new model is parented and `MaxCongregation` is set. Re-place items when it changes.
- Core orients every building so its Door faces the plaza, whatever the imported axis was.
- Land extensions live in `Plot.Expansion` and the fence in `Plot.Fence`. Decor inside a new building's footprint is removed automatically.
- The ClaimPad prompt claims a free plot, and for the owner it becomes the Expand Land prompt (same server path as `RE_ExpandLand`).

## For the client (role C)
- Congregant models carry the CollectionService tag `Congregant` and the attribute `OwnerUserId`. They are anchored Models with a `Root` part.
- `workspace` attributes `CongregantModels` and `CongregantsSeated` report the live counts.
- `RE_Notify` texts are short fixed strings. Core only sends info, success or error.
- Tutorial greeters have a ProximityPrompt (action text "Greet"). Land and claim use the ClaimPad prompt.

## For progression (role B)
- Fire `ServerStorage.Bridge.Purchased` as `(player, offerId)`. Any offerId type is accepted, tutorial step 3 advances on the first one.
- `SpendMoney` only works after the player's data loaded and returns false before that. Check `workspace.CoreOnline` first, as the contract says.
- `Economy.setEventMult(n)` is the Shabbat hook. It sets `workspace.EventMult`, which is read live every income tick.

## Tuning
All numbers are in `src/server/core/Config.lua` (land costs, arrival timing, congregant cap, palettes). Income and arrival math is in the pure module `Income.lua`.

## Dev tools
- `src/server/core/dev/ContractCheck.server.lua` runs in Studio 12 seconds after start and prints PASS, FAIL or MISSING for remotes, Bridge, plots, attributes and every model.
- `tools/StudioImportFixer.lua` is pasted into the Studio command bar with one or more imported models selected. It colors parts from their names, makes glass transparent, builds the Seats and Slots folders, sets the PrimaryPart, scales buildings so the Door is 9 studs tall and builds the kippah and tallit Accessories.
- `tools/tests/core_test.luau` runs with the `luau` CLI: `cd tools/tests && luau core_test.luau`.

## Model pipeline
Blender at 1 unit = 1 stud, FBX to `art/exports/` (not committed), Import 3D in Studio, run the fixer, right click and Save to File as `src/models/core/<name>.rbxm`, commit the `.rbxm`.
