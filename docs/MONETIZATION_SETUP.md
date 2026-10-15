# Robux setup (game passes and developer products)

The game ships with every pass and product wired up and tested. The only thing missing is the Roblox ids, because only the owner of the experience can create them. Until an id is filled in, that item shows "Coming soon" in the Store tab and cannot be bought.

All ids live in one file: `src/shared/Monetization.lua` (`id = 0` means not created yet).

## Fast way: one command (recommended)
1. Creator Hub > Credentials > API Keys > Create API Key.
2. Add two systems: **Game Passes** (read and write) and **Developer Products** (read and write). Under experiences choose "Grow a Synagogue" (universe 10770936985). Leave IP restriction open or add your own IP. Copy the key.
3. In a terminal:
   ```
   cd /path/to/growasyn
   python3 tools/monetization/setup_monetization.py --dry-run
   ROBLOX_API_KEY=your_key python3 tools/monetization/setup_monetization.py
   ```
   It creates all 8 passes and 22 products with the names, descriptions, prices and icons below, then writes every new id into `src/shared/Monetization.lua`. It is safe to run again, it only creates items whose id is still 0.
4. Sync the changed file into Studio (or open the repo with Rojo), save and publish. Delete the API key afterwards.

The endpoints used are the Open Cloud beta endpoints `POST /game-passes/v1/universes/{id}/game-passes` and `POST /developer-products/v2/universes/{id}/developer-products`. If Roblox changed the beta, the script prints the HTTP error and you can fall back to the manual way.

## Manual way
Creator Hub > Monetization > Passes / Developer Products > Create. Use the exact name and price, upload the icon from `docs/store/icons`, switch "Item for sale" on, then paste the id into `src/shared/Monetization.lua`.

### Game passes (one time purchases)
| Key | Name | Price | What it does | Icon |
|---|---|---|---|---|
| double_income | Double Income | 249 | +100% money | pass_double_income.png |
| patron | Patron Pass | 499 | +50% money, 12 hour offline cap, double Welcome Back reward, 3 streak freezes, golden cape | pass_patron.png |
| rapid_growth | Rapid Growth | 299 | items grow 50% faster | pass_rapid_growth.png |
| helping_hands | Helping Hands | 149 | guests arrive 50% faster, quests collect themselves | pass_helping_hands.png |
| swift_delivery | Swift Delivery | 199 | shop restocks every 4 minutes | pass_swift_delivery.png |
| quick_merge | Quick Merge | 99 | Merge All button | pass_quick_merge.png |
| premium_wardrobe | Premium Wardrobe | 799 | every premium cosmetic | pass_golden_wardrobe.png |
| pet_lover | Pet Lover | 199 | +1 pet slot, +10% pet bonus | pass_pet_lover.png |

### Developer products (repeatable purchases)
| Key | Name | Price | Grant |
|---|---|---|---|
| bundle_s / bundle_m / bundle_l | Small, Medium, Large Money Bundle | 49 / 149 / 499 | 2h / 8h / 36h of income |
| growth_lamp | Growth Lamp | 39 | everything grows 2x for 30 minutes |
| festival_boost | Festival Boost | 59 | +100% money for 15 minutes |
| complete_s / complete_m / complete_l | Grow 15 Minutes, 1 Hour, 4 Hours | 19 / 49 / 129 | skips growth time on placed items |
| order_rare / order_epic / order_legendary | Special Order | 99 / 299 / 799 | the player picks a category, gets that item in that rarity (no luck) |
| pet_pick_1 / pet_pick_2 / pet_pick_3 | Pick a Pet | 149 / 399 / 999 | the player picks a pet up to that rarity (no luck) |
| legacy_boost | Legacy Boost | 199 | +25% Legacy Points on the next Legacy |
| cosmetic_49 ... cosmetic_799 | Style Unlock | 49, 99, 149, 249, 399, 799 | unlocks the cosmetic the player picked whose price matches |
| starter_pack | New Congregation Pack | 149 | first 7 days only: 4h of income, a Rare ornament, a black and gold kippah |

## How purchases are handled
- Passes are checked on join with `UserOwnsGamePassAsync` and on `PromptGamePassPurchaseFinished`. Each one sets a `Pass_<key>` player attribute that the boost, pet, shop and quest code reads.
- Products go through `MarketplaceService.ProcessReceipt`: the purchase id is stored in the player data first, then saved, and only then is `PurchaseGranted` returned, so a crash cannot double grant. If the player is not loaded yet, the receipt is retried by Roblox.
- Special Orders, Pick a Pet and Style Unlocks remember what the player picked for 15 minutes (saved with the player). If the pick is lost, a safe default is granted.
- Policy: there are no paid random items, no paid spins, no Robux restocks and streaks are never sold. The Odds buttons show every free random chance. Torah scrolls are never part of any product. No unsolicited pop up appears in the first five minutes.

## Testing without spending Robux
In Studio, set `workspace:SetAttribute("DevFreeStore", true)` (command bar or the Server console). Items whose id is 0 can then be "bought" for free so you can test every grant. The attribute does nothing outside Studio.
