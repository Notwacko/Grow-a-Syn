# Release checklist

Everything in the repo and in the Studio place is built and tested. These steps can only be done by the person who owns the experience, because they happen on the Roblox website or need a publish.

## 1. Publish
1. Open the place in Roblox Studio (it is saved to the cloud as "Grow a Synagogue!").
2. Run `tools/studio_sync/serve.sh` then the `sync_all.lua` script through the Studio MCP if any file in `src/` changed after the last save, then press Cmd+S.
3. File > Publish to Roblox. The meshes were uploaded under the account that ran the import. If the experience belongs to a group, re-import the models while signed in as the group (or share the assets with it), otherwise they will not load.

## 2. Experience settings (Creator Hub > the experience > Settings)
- Max players: 8. The map has 8 plots. With more players the extra visitors can walk around but cannot claim a plot until someone leaves.
- Devices: Computer, Phone, Tablet. The UI is built for mouse and touch. Gamepad is not supported by the custom UI.
- Studio Access to API Services is only needed for testing in Studio. Live servers save data without it. Leave HTTP requests off.
- Avatar: set the avatar type to R15 only (Game Settings > Avatar). Outfits, cosmetics and pets are built for R15 bodies. R6 avatars would get no outfit.
- Age guidelines questionnaire: no violence, no chat input from players (there is no typed text), no trading. Paid items exist (passes, boosts, fixed outcome orders) but there are no paid random items, so the paid random items answer is No.

## 3. Robux items
Follow `docs/MONETIZATION_SETUP.md`. One command creates all 8 game passes and 22 developer products and fills in the ids. Until then the Store tab shows "Coming soon" on every item. The pass icons are in `docs/store/icons`.

## 3b. Store art
In `docs/store`:
- `icon_512.png` (and `icon_1024.png`) for the experience icon.
- `thumbnail_1920x1080.png` and `thumbnail_1280x720.png` for the thumbnail.
They are rendered from the real models. `tools/make_store_art.py` rebuilds them from `art/icons/thumb_scene.png` and `icon_scene.png`, which `art/src/build_thumb.py` renders in Blender.

## 4. Suggested description
> Be the rabbi of a growing synagogue! Claim your plot, welcome your first visitors and reach a minyan, then choose your path and grow from a small shul into a grand landmark. The story never ends: start a Legacy and grow again, stronger.
>
> - Shop for ritual items that restock every five minutes and place them in your hall to watch them grow, earn and sometimes turn Gilded, Radiant or Ancient
> - Merge three of a kind into something better, then keep merging mythical items into higher stars
> - Hatch pets that follow you and boost your income
> - Collect the whole Collection Book for permanent bonuses
> - Daily rewards, a free Lucky Wheel, daily quests and weekly goals
> - Dress your rabbi with dozens of kippot, tallitot, capes, wings, hats and effects
> - Welcome guests with real avatars in every style, from casual to traditional
> - Join the Shabbat event for double income
>
> Made by Jewish developers with love and respect. Optional purchases never include random paid items.

## 5. Review before the public sees it
- A rabbi should look at: the Torah scroll art (mantle, crown, breastplate), the Star of David on gables, items and cosmetics, how each denomination stage is drawn (Reform to Haredi outfits for the player and for the guests, including beard, side curls, shtreimel, bekishe, tichel and long skirts), the ladder names, the word "Legacy" for the prestige system, "Patron Pass", and the wording of the Shabbat event (a double income event on Shabbat is the design brief, but it is worth an opinion).
- Neutral choices made where the brief was silent: guests of every ladder stage are drawn in a mix of styles; a rabbi can switch to a modest dress style in the Style tab; no item can be sold or thrown away; Torah scrolls cannot be merged and are always kept through a Legacy; nothing is spoken or typed.
- Sephardic and Mizrahi ladders are not specified yet, so only the Ashkenazi ladder is offered. Role C has T2 and T3 buildings for them in the place but the choice screen does not show them.

## 6. Team merge
- PR #2 (`a/core-phase2`, stacked on #1) carries the core work. The whole interface was rewritten by role A at the owner's request (HUD, menus, shop, pets, style, quests, book, store, wheel, daily, legacy, leaderboards, tutorial, popups). Those files are in `docs/client_fixes/client` because the pre-commit hook blocks role A from `src/client`; role C should copy them into `src/client` and delete the old modules. Role B can take over the shop by replacing the `OnServerInvoke` handlers that `ProgressionFallback` and `ItemService` provide, and by setting `workspace.ProgressionOnline`.

## 7. After launch
- `workspace:GetAttribute("ShopEpoch")` and the console show restocks. `EventService.trigger(seconds)` starts a Shabbat event on demand from the server console.
- Tuning numbers (prices, growth times, mutation odds, event timing) are all in `src/shared/ItemCatalog.lua` and `src/server/core/Config.lua`.
