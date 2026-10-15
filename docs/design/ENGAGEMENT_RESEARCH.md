# Engagement and monetization research (summary)

Compiled from public sources (Roblox Creator Hub, Game Developer "Math of Idle Games", Duolingo streak research, Grow a Garden guides, DevForum threads). Numbers marked "proposed" are starting points to tune, not measured benchmarks.

## What we implement and why
- Variable rewards: shop restock every 5 minutes with weighted rarity, a free pity rule, and mutation rolls when an item finishes growing. Odds are shown in an Odds panel.
- Daily login streak paid in minutes of current income so rewards scale with progress. Streak freezes, a 36 hour claim window, and a soft penalty instead of a hard reset.
- Daily and weekly quests, a welcome back screen with offline earnings (25 percent of active income, capped), a free daily lucky wheel that never pays ritual items, a Collection Book with milestone rewards, rarity reveal moments, endowed progress (new bars start at 20 percent), and cohort style leaderboards ranked by collection score and congregation size, not by money.
- Infinite progression: tier costs that grow about 24x per tier, infinite station levels with a soft cap, deterministic 3 into 1 item merging up to star 10, and a prestige loop called Legacy with permanent multipliers.
- Money: passes for permanent boosts, developer products for consumables and cosmetics. No paid spins, no Robux restock, no streak saving for Robux, fixed outcome "Special Orders". Torah scrolls are never in a product, prize pool, merge or sale.
- Policy: paid random items need disclosed odds that update with modifiers. We avoid paid random items entirely. `PolicyService:GetPolicyInfoForPlayerAsync` gates anything restricted. No false scarcity, no always on sale, soft button text, at most one unsolicited offer per session, none in the first five minutes.

## Formulas (proposed)
- Tier cost: 5,000 x 24^(t-2).
- Upgrade cost: base x 1.15^level. Effect +4 percent per level up to level 25, then +1 percent per level.
- Merge: 3 items of star s become 1 item of star s+1. Income x4 per star up to 5, x3.5 for stars 6 to 8, x3.2 above, cap star 10.
- Income = items x stars x mutation x (1 + upgrades) x (1 + collection) x legacy x (1 + sum of boosts). The boost pool holds passes, VIP, events and potions and is additive inside the pool.
- Legacy points gained = floor(5 x (run earnings / 1e9)^0.5). Permanent multiplier 1 + 0.2 x total points.
- Offline: 25 percent rate, 4 hour cap plus 1 hour per hall tier, 12 hours for Patron.
- Daily streak (minutes of income): 10, 15, 20, 30, 45, 60, 90 with a freeze on day 3, a named Rare item on day 7.

## Sources
See the research hand-back in the project history. Primary ones: create.roblox.com/docs/production/monetization (including paid random items and managed pricing), gamedeveloper.com "The Math of Idle Games" parts I and III, blog.duolingo.com streak article, creation.dev game pass pricing, the Newzoo Roblox 2025 report.
