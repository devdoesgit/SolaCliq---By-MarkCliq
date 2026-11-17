# SolaCliq marketing graphics

Graphics of the SolaCliq app for the website, to show solar EPC vendors what
it does. Built with [Stageshow](https://github.com/benjitaylor/skills)
(MIT; `licenses/`), in the app's own look (`design/tokens.json`, the iOS v2
design: Inter, cream, the sun, the app's own icons).

This repo never touches the website (`~/Desktop/MarkCliq`): copy what you
need from here into it.

## The four graphics

| Graphic | What it shows | Size | Media | Component |
|---|---|---|---|---|
| Hero: proof photo | A worker's phone: the third proof photo lands with its GPS tag, Submit, then the admin's approval arrives as a notification and the task turns Approved. Loops through "Next task", 12.3 s | 440 × 540 (a 358 × 500 design below 440 wide) | `solacliq-proof.mp4`, `.webm`, `solacliq-proof-poster@2x.png` | `ProofHero` |
| Card: install tracker | A homeowner's install at Stage 4 of 7, with the next payment and Pay with UPI | 400 × 400 | `solacliq-install@2x.png` | `InstallCard` |
| Card: expenses | A worker's ₹1,240 fuel expense with its receipt, Approved, paid with salary | 400 × 400 | `solacliq-expense@2x.png` | `ExpenseCard` |
| Card: your brand inside | The worker's home under the vendor's own logo, with the admin's "Company logo: Uploaded" setting | 400 × 400 | `solacliq-brand@2x.png` | `BrandCard` |

Images are 2× (sharp on retina): show them at half their pixel size. The
video is 880 × 1080 (2×) over the site's page grey `#f5f5f7`, so its rounded
corners disappear on that page; the PNGs have transparent corners.

## Before publishing

1. **The photos.** The three proof photos in the hero are the app's
   bundled thumbnails from the design files, whose origin and licence are
   unknown (`docs/decisions.md`). Confirm them or replace them before these
   go on the public site.
2. **Illustrative data.** Every name and number is made up ("Arka Solar" is
   not a real vendor). Show a caption with them, as the website does for
   other sample data, for example: *Illustrative screens, sample data.*
3. **Real vendors.** Don't swap in a real client's logo or name (RY
   Enterprises, for one) without their permission.

## Using the media (simplest)

```html
<video autoplay muted loop playsinline width="440" height="540"
       poster="/solacliq/solacliq-proof-poster@2x.png">
  <source src="/solacliq/solacliq-proof.webm" type="video/webm" />
  <source src="/solacliq/solacliq-proof.mp4" type="video/mp4" />
</video>
<img src="/solacliq/solacliq-install@2x.png" width="400" height="400" alt="…" />
```

Give each an `alt` saying what it shows (the table above has the words).

## Using the components (sharp at any size, animate live)

`components/` holds the four components and a trimmed Stageshow kit (its
third-party brand artwork removed: we use none of it). In the website:

1. Copy `components/kit` and `components/solacliq` into the site, side by
   side.
2. Add `lucide-react@0.468.0` (the kit's icons) next to React 18.
3. Use them in a client component (they animate in the browser):

```tsx
'use client'
import { ProofHero, InstallCard } from '@/solacliq'

<div style={{ width: 440 }}><ProofHero /></div>
<div style={{ width: 400 }}><InstallCard /></div>
```

Each scales to its container's width; the hero switches to its compact
design below 440 px. Under reduced motion the hero shows its poster frame.
Its CSS is scoped to its own classes (`.sq-proof`, `.sq-tile`), so it
doesn't leak into the page.

## Changing them

The components were made in a Stageshow checkout's playground
(`examples/solacliq-*`), filmed with its `scripts/film.mjs --gate` (the hero
passes the rehearsal gate; the cards have no findings). To re-record the
media after a change, copy the components back in as examples and run
`tools/record.mjs` from that checkout (it steps the playground's virtual
clock frame by frame), then:

```
ffmpeg -framerate 30 -i frames/%05d.png -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart solacliq-proof.mp4
ffmpeg -framerate 30 -i frames/%05d.png -c:v libvpx-vp9 -b:v 0 -crf 32 solacliq-proof.webm
```
