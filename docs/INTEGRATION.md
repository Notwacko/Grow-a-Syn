# Integration notes (Core, B and C)

State on 2026-10-15: Core is online, B has not pushed anything, C's client UI exists only inside the Studio place (StarterPlayerScripts.Client), not in the repo.

## What Core does so the game still works without B
- The tutorial moves from Welcome to Claim Plot as soon as the player owns a plot, even if RE_AdvanceTutorial never arrives.
- The Buy step completes when the player buys something (`Bridge.Purchased`) and is skipped after 75 seconds while workspace attribute `ProgressionOnline` is not true, so the congregation can pass 9 people and reach the minyan. When B sets `ProgressionOnline` the contract behaviour (Bridge.Purchased) applies again.
- The three tutorial greeters stand at the synagogue door with a bobbing "!" marker.

## Client fixes made by the lead (2026-10-15)
- `Main.client.lua` used `ScreenInsets = TopbarSafeInsets`, which sizes the ScreenGui to the Roblox topbar rectangle (about 58 pixels tall). Popups centered inside that strip and were cut off. It now uses `CoreUISafeInsets` (the full area below the topbar).
- The mock never engages while Core is online: `ProgressionFallback` creates `RF_GetCatalog` and the other remotes, so `Net.init` binds the real server. The mock still exists for running the UI without any server.
- The Land and Upgrade buttons call `Net.expandLand()` and `Net.upgradeBuilding()` and show the reason when a call fails.

## Still needed from B
`RF_ChooseDenomination` and `RF_UpgradeBuilding` (they set `Denomination` and `Tier`, which Core turns into the building swap), the shop and inventory remotes, and `ProgressionOnline`.

## Studio preview
`tools/studio_sync/bake_world.lua` builds the world into the place while in Edit mode so the viewport is not empty. At runtime `WorldService`, `PlotService` and the ambient modules replace or adopt what was baked, nothing is duplicated.
