# Client fixes (role C folder)

The pre-commit hook does not allow role A to commit `src/client`, so the fixed client scripts live here until role C merges them. The same files are untracked in `src/client` so the Studio sync tool keeps pushing them into the place.

- `Main.client.lua`: `ScreenInsets = CoreUISafeInsets` instead of `TopbarSafeInsets` (the old value sized the ScreenGui to the 58 pixel topbar strip and cut popups off), a smaller scale on desktop, and the Land and Upgrade buttons call the server and show the reason when a call fails.
- `HUD.lua`: decluttered. One money pill with the income rate under it, four small icon only buttons, a thin stage ladder shown after the denomination choice, one slim congregation bar. The duplicate quick buttons, stats text and price badges are gone.
- `Tutorial.lua`: banner moved up for the compact layout.
- `TierPopup.lua`: waits for `DataLoaded` so the saved tier no longer pops a "NEW TIER" window at join.
- `patch_components.lua`: run once in Studio (Edit mode) to give `Components` an `image` option for buttons and pills and to replace the unreadable close glyph with an X. It is idempotent.
- Icons are rendered in Blender (`art/src/build_icons.py`) and uploaded; their asset ids are in `src/shared/Icons.lua`.
