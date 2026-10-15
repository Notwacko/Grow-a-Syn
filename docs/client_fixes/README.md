# Client (role C folder)

The pre-commit hook does not allow role A to commit `src/client`, so the full client lives here until role C merges it. The same files are untracked in `src/client` so the Studio sync tool keeps pushing them into the place.

At the owner's request role A rewrote the whole interface. Copy `docs/client_fixes/client/` over `src/client/` and delete the old modules (Components, HUD, InventoryUI, Net, ShopUI, TierPopup, Tutorial, Contract, Theme, Format, FloatingNumbers, Notifications, DenominationPickerUI, BuildingUpgradeUI, LandExpandUI, IconSet, Sound, Dev, MockNet, Link, ModelLookup).

Layout:
- `Main.client.lua` builds five ScreenGuis (HUD, tutorial, menu, popups, toasts) with a scale that follows the screen height (phone layout when touch only).
- `InteriorCamera.lua` keeps the camera inside the hall (the building has an invisible tagged `CameraBox`).
- `ui/` shared components: `Theme`, `Ui` (buttons, bars, modals, pills, badges), `Store` (attributes, `RF_Game`/`RE_Game` sections, catalog and inventory caches), `Layers`, `Toasts`, `Hud`, `Menu` (tabbed menu), `Reveal` (reward popups), `Popups` (daily rewards, lucky wheel, welcome back), `Denomination`, `TierPopup`, `Tutorial`, `Events`, `ItemView`, `PetsWorld` (client side pets that follow every player), `Sfx`, `Util`, `Signal`.
- `panels/` one module per menu tab: Shop, Items, Pets, Style, Quests, Collection Book, Store, Legacy, Leaderboards, Settings.

Server contract used by the client: `RF_Game(action, payload)` with actions `service.action` (for example `pets.hatch`, `daily.claim`), `RE_Game(kind, payload)` pushes sections and events, plus the original contract remotes (`RF_GetCatalog`, `RF_Buy`, `RF_Merge`, ...). Details are in `docs/MODULES.md`.
