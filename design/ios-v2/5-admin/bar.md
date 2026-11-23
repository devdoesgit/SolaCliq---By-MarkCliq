## bar.md
Reference: `design/ios-v2/5-admin/Admin2*.dc.html` (canvas page "v2 · 5 Admin web"), all 37 artboards at 1280 x 800; values measured from their markup, 2026-11-23.
Goal: the admin website looks like those artboards to the pixel in its borders, radii, spacing, type and alignment, with nothing generic or decorative the design doesn't have.

Each line is checked on the live preview by reading computed styles and by looking at 1280 x 800 and 360 x 800 screenshots beside the artboard.

1. **One radius per job.** Nav links, inputs, selects and list cells 14px; cards 20px; stat tiles 18px; buttons, pills and chips fully round. | measure: computed `border-radius` | check: probe `.side-link`, `.sc-input`, `.card`, `.stat`, `.sc-btn`, `.sc-pill`, `.chip` on every screen; no other radius on those.
2. **Hairlines, never boxes.** Dividers are 1px `rgba(46,33,27,0.08)` lines on top of a row; a control's edge is a 1px inset ring (`#DCCFC1` buttons, `#E2D7CB` fields); nothing has a solid outer border, and no card sits in a bordered box. | measure: computed `border-*` and `box-shadow` | check: no element with a visible `border` except the AA field edge (see Conflicts); rows use `border-top` only.
3. **Fixed control heights.** Buttons and back links 40px, nav links 42px, inputs and selects 44px, chips 36px, pills 26px, log in button 50px; 48px only on touch screens. | measure: computed height at 1280 with a mouse | check: probe each kind on each screen; tolerance ±1px.
4. **Four type steps do the work.** Page title 30px/700/-0.035em; card title 17px/600; body and rows 14–15px; meta 12–13px; eyebrows and table heads 11px/600/0.08em uppercase. | measure: computed `font-size`, `font-weight` | check: list every distinct font-size inside `main`; anything outside {11,12,13,14,15,17,22,30 and the stat number} is a fail.
5. **Cards are one recipe.** White, 20px radius, the design's two-layer shadow, padding 16–18px by 20px, 12px gap inside; nested surfaces are cream fills, not cards. | measure: computed padding, gap, shadow | check: every `.card` matches; no `.card` inside a `.card`.
6. **Pills read by tint.** 26px high, 0 11px padding, 12px/600, a pale fill with the same hue's dark text (green on mint, brown on tan, red on blush, ink on sun). | measure: computed size and colours | check: every `.sc-pill`; contrast of text on its fill ≥ 4.5:1.
7. **The grid is the artboard's.** Sidebar 236px with 22px/16px padding; content 22px from the top and 28px from the sides; 14–20px between blocks; edges of cards in a row line up. | measure: element boxes | check: at 1280 x 800, left edges of the title, toolbar and first card are equal (±1px); gaps between sibling cards are 14, 16 or 20px.

Not borrowed (the design's, or its demo): the sun-tile logo, the illustrative people and companies (Arka Solar, Rajeeb, Suresh...), the hero photo's crop beyond what the login uses, and every designed feature listed under "Drawn, and not built" in `docs/features/admin-website.md`.

Conflicts, where the design system and accessibility win (kept, not failures):
- Muted text is `--muted` (#6d635a), darker than the artboards' #8C7F74, for 4.5:1.
- A field's edge is darker than #E2D7CB, for the 3:1 a form control's boundary needs (WCAG 1.4.11); it stays a 1px ring.
- Touch screens get 48px targets.
