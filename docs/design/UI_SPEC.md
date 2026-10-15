# UI spec (research summary)

Sources: Roblox Creator Hub UI docs (animation, size modifiers, appearance modifiers, on-screen containers, flex and grid layouts, 9-slice, viewport frames, adaptive design, accessibility, paid random items), creation.dev UI best practices, DevForum threads on UI critique and GUI optimization.

## Scaling and layout
- Author in 1080 px high design space with one root UIScale. Desktop `clamp(viewport.Y / 1080, 0.6, 1.5)`, touch `clamp(viewport.Y / 540, 0.7, 1.0)`. UIScale scales strokes and corners too.
- Interactive ScreenGuis use `ScreenInsets = CoreUISafeInsets`. Keep both bottom corners clear on touch (thumbstick, jump). Frequent buttons between 15 and 65 percent of the screen height on the edges.
- Tap targets at least 48 px after scaling, 8 px apart. At most 5 persistent HUD groups. One modal at a time, HUD fades while a modal is open, close button always in the same corner, tabs when a menu has more than 5 sections.
- Layers: HUD 1, menus 10, popups and reveal 20, toasts 30, tutorial 40. Closed menus are `Enabled = false`. Build panel content lazily.

## Style
- Fonts: FredokaOne for titles, buttons and numbers, a clean bold body font for small text, LuckiestGuy only for hero words. Text stroke in ink (2 px at 16 to 22, 3 px at 24 to 32, 4 px at 40+). Fixed text sizes, not TextScaled.
- Palette: ink `#1E2A4A`, panel cream `#FFF4DC`, header blue `#5B9BFF` to `#2E6AD9`, primary green `#5BD66A` to `#2FB24A`, money gold `#FFD23F` to `#F5A524`, danger red `#FF6B6B` to `#E03E3E`, premium purple `#8B5CF6`, disabled `#B8BFCC`.
- Rarity: common `#9AA5B1`, uncommon `#2BB673`, rare `#2F80ED`, epic `#9B51E0`, legendary `#F2A900`, mythic `#FF3D9A`. Border 3, 3, 4, 4, 5, 6 px. Pair every color with a name and a pip count. Settings toggle for a colorblind safe set.
- Shapes: panels 20 px radius, cards and buttons 14, pills fully round. Strokes: panel 4, card 3, button 3. Glossy top highlight, a darker 3D lip under buttons, soft shadow.
- Button states: idle, hover (1.06 scale, desktop only), pressed (0.94, lip shrinks), selected, disabled, locked (lock icon), loading, unaffordable (red price, shake).

## Motion
- Modal open scale 0.85 to 1 Back Out 0.28 s, close 0.15 s Quad In. Button press 0.08 s down, 0.18 s Back Out up. Hover 0.12 s. Tab switch 0.15 s fade, indicator 0.2 s.
- Count-up 0.5 to 0.8 s driven by one loop, label pop to 1.15. Toasts slide in 0.3 s, hold 2.5 s, max 3 stacked, merge duplicates.
- Reward reveal: dim, anticipation shake 0.5 to 1.0 s scaled by rarity, flash, item scale 0 to 1.15 to 1 over 0.45 s, confetti, name slide up, Collect button at +0.6 s. Skippable by tap.
- Avoid CanvasGroup on mobile, many simultaneous tweens, tweening UIStroke thickness on text, hover only effects on touch. Honor `GuiService.ReducedMotionEnabled`.

## Components
Currency pill 240x56, tab bar 64 tall, modal 0.62W x 0.78H (max 1100x720, phone 0.9 x 0.9), shop card 220x300, item card 128x152, quest row 560x96, daily calendar 7 tiles of 120x160 with a double width day 7, spin wheel 520 diameter, toast 360x64, tooltip max 260 wide, progress bar 28 tall with a centered label. Previews: one live ViewportFrame for detail views, pre-rendered icons (spritesheet) for grids of 12 or more items.
