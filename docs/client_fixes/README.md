# Client fixes (role C folder)

These three files are the fixed versions of the client scripts that now run in the Studio place. The pre-commit hook does not allow committing `src/client` for role A, so the copies live here until role C merges them into `src/client`.

- `Main.client.lua`: `ScreenInsets = CoreUISafeInsets` instead of `TopbarSafeInsets` (the old value sized the ScreenGui to the 58 pixel topbar strip and cut popups off), Land and Upgrade buttons call the server, and the garden panel is created.
- `Tutorial.lua`: the Buy step points at the Seed Shop.
- `GardenHUD.lua`: new, shows basket, seeds, weather and restock timers.

The `src/client` copies are untracked in the working tree so the Studio sync tool keeps pushing them into the place.
