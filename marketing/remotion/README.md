# SolaCliq promo video (Remotion)

A 31-second promo in two shapes, both at 30 fps: `Promo`, 1920 × 1080 for
the website, and `PromoVertical`, 1080 × 1920 for Instagram Reels and
WhatsApp Status. Same story, scenes laid out for each shape. In the app's
own look: the mark
(the sun rising behind the awning), the promise, four features as they look
in the app (proof photos, expenses, the homeowner's tracker, the vendor's own
logo) and the lockup with markcliq.com. Code in `src/` (`Promo.tsx` holds the
scenes and their timings, `brand.tsx` the colours, mark, phone and icons).

## Licence: read before publishing

Remotion is free only for individuals, non-profits, companies of up to 3
employees, or while **evaluating** it. MarkCliq has four people, so using a
Remotion-made video commercially (on the website, in ads) needs a Remotion
Company License: https://www.remotion.dev/docs/license/pricing. This video
was made as an evaluation.

## Also before publishing

- The proof photos are the app's sample thumbnails from the design files,
  licence unknown (`docs/decisions.md`): confirm or replace them.
- Every name and number is illustrative; the feature scenes say so under
  their text. "Arka Solar" is a made-up vendor.

## Commands

```
npm install
npm run studio            # preview and scrub in the browser
npx remotion render src/index.ts Promo out/solacliq-promo.mp4 --concurrency=2 --crf=18 \
  --browser-executable=/usr/bin/google-chrome
npx remotion render src/index.ts PromoVertical out/solacliq-promo-vertical.mp4 --concurrency=2 --crf=18 \
  --browser-executable=/usr/bin/google-chrome
npx remotion still src/index.ts Promo out/frame.png --frame=340 \
  --browser-executable=/usr/bin/google-chrome
```

`out/` and `node_modules/` are git-ignored; the rendered videos are copied
to `../media/solacliq-promo.mp4` and `../media/solacliq-promo-vertical.mp4`.
