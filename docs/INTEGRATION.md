# Integration notes (Core, B and C)

State on 2026-10-15: Core is online, B has not pushed anything, C's client UI exists only inside the Studio place (StarterPlayerScripts.Client), not in the repo.

## What Core does so the game still works without B
- The tutorial moves from Welcome to Claim Plot as soon as the player owns a plot, even if RE_AdvanceTutorial never arrives.
- The Buy step is skipped after a few seconds while workspace attribute `ProgressionOnline` is not true, so the congregation can pass 9 people and reach the minyan. When B sets `ProgressionOnline` the contract behaviour (Bridge.Purchased) applies again.
- The three tutorial greeters stand at the synagogue door with a bobbing "!" marker.

## Problems on C's side (reported in Discord)
1. `Net.init` falls back to `MockNet` whenever `RF_GetCatalog` is missing, even with Core online. MockNet writes fake Money, MoneyPerSecond, Congregation, PlotId, Tier and TutorialStep attributes on the client and its tutorial, buy and denomination calls never reach the server. Fix: mock only when `workspace:GetAttribute("CoreOnline")` is not true, never write game attributes on the client when Core is online, and still fire the real `RE_AdvanceTutorial` and `RE_ExpandLand`.
2. The HUD waits up to 10 seconds for `RF_GetCatalog` ("Loading..."). With `CoreOnline` true it should build immediately.
3. Welcome, Denomination picker and Tier popups are cut off at the top of the screen.
4. The Land and Upgrade buttons only show "coming soon". `RE_ExpandLand` is implemented in Core.

## Still needed from B
`RF_ChooseDenomination` and `RF_UpgradeBuilding` (they set `Denomination` and `Tier`, which Core turns into the building swap), the shop and inventory remotes, and `ProgressionOnline`.

## Studio preview
`tools/studio_sync/bake_world.lua` builds the world into the place while in Edit mode so the viewport is not empty. At runtime `WorldService`, `PlotService` and the ambient modules replace or adopt what was baked, nothing is duplicated.
