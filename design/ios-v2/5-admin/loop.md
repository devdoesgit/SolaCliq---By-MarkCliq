# Design loop: admin website vs its artboards

Bar: `bar.md` in this folder. Measured by `probe.js` (computed styles on
18 screens at 1280 x 800, mouse) and checked by eye beside the artboards.

## v1 (2026-11-23)
Score: 5/7 pass, 2 fail
Fixed: fields and sidebar links 12px → 14px radius (new token
`radius-14`); buttons 48px → the design's 40px for a mouse, 48px kept
for touch; the "File" placeholder used the 20px heading, now the 17px
card title.
Still failing: none measured. Seen: a cramped sidebar foot, an empty
chart drawn as four flat lines, labelled toolbars the design doesn't
have.
Note: small avatar initials are 10px on the artboards too, so the probe
allows 10px there.

## v2
Score: 7/7 pass
Fixed: sidebar foot quiet (one-line name, no underlines until hovered);
an empty week chart says so in a sentence; toolbar labels hidden
visually (screen readers keep them).
Still seen: selects show the browser's black arrow.

## v3
Score: 7/7 pass, no goal blockers. Stopped.
Fixed: selects draw the artboards' chevron.

Left as is, on purpose:
- Due date is the browser's date-time field (the artboard draws two
  custom pickers; the native one works on every phone).
- The Search button stays: the artboard searches on Enter only.
- Long illustrative names ("Ravi Example (illustrative)") truncate on
  task cards; real names are shorter.

## After the loop (2026-11-23)
- Variant artboards (task returned, approved, problem, assigned; customers
  with and without commission; projects) compared: task pages now lead
  with the task when it isn't in review, an approved one shows its
  banner and "This task is closed", the returned banner says "waiting
  for the retake". Probe: all measured lines pass.
- New screens: Leads (the artboard's cards, with the agreed actions) and
  Stage templates (as drawn, plus a name field).
