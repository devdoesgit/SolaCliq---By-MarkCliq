---
name: design-polish
description: Polish a SolaCliq mobile screen's visual design (hierarchy, typography, colour and contrast, spacing, section clarity) against the SolaCliq design system, by driving the app on the Android emulator, making targeted widget and theme edits, and getting an independent evaluator's verdict. Use when asked to improve, polish, refine, critique or audit how a Flutter screen looks ("make this look better", "this screen feels off", "design pass", "review the UI", "feels too Material default"). Skip for feature work, routing or behaviour changes, and the admin website.
license: MIT
metadata:
  adapted_from: https://github.com/chunkytofustudios/flutter-skills (skills/design-polish, MIT, Chunky Tofu Studios)
  changes: Design tone comes from the SolaCliq design system instead of a reference screen; emulator control uses mobile-mcp and the Dart MCP server instead of the original emu.sh script; tests run through the Very Good CLI MCP.
---

# Design polish (SolaCliq mobile)

You polish screens in the SolaCliq Flutter app (`mobile/`) so an installer on a
rooftop, an agent between visits, or a customer instantly knows what the screen
says and what to tap. The work is evidence-driven and bounded: every round ends
with an independent evaluator's verdict, not your own opinion.

If the user didn't name screens, ask which ones (route names or files under
`mobile/lib/`).

## Design tone: the SolaCliq design system

Don't infer tone from screens. It is markcliq.com's look, with values in
`design/tokens.json` (read it before the first screen) and the widgets in
`mobile/packages/sola_ui`. The tone in short:

- **Mood:** editorial, flat, calm, square. Rust red on warm paper, as on
  markcliq.com.
- **Fonts:** Space Grotesk (light 300 for running text, 400 for headings and
  values) and Space Mono (uppercase, widely tracked labels and buttons;
  every number). Bundled in `sola_ui`. Emphasis by case, size and colour,
  not bold.
- **Colour:** tokens only. `surface` ground, never pure white. `accent` for the
  one primary action, the current install stage, and links; two accent things
  on a screen means one is wrong. Status colours always with a word.
- **Surfaces:** no shadows, no gradients, no elevation. Square corners
  everywhere. Rows separated by 1px `line` rules, not cards.
- **Hierarchy lever:** type weight and size, spacing, uppercase `label`
  headings, accent or a status tint. Never elevation.
- **Motion:** immediate tap feedback (<100ms); slow easing only for entrances;
  honour reduce-motion.
- **Field use:** 48dp minimum tap targets, 16px body, nothing under 14px on
  mobile except `label`. Primary action at the bottom, full width.

Every interactive widget keeps its `Key` and `Semantics` label (project rule);
polish never removes them.

If you believe the design system itself is the problem, stop and tell the
owner. That is a design-system change, not a polish task.

## Tools

- **mobile-mcp** drives the emulator (`solacliq_phone`):
  `mobile_list_elements_on_screen` to see what's addressable (prefer this),
  tap by ref, `mobile_swipe_on_screen`, `mobile_take_screenshot` to judge
  appearance.
- **Dart MCP server:** `hot_reload` after widget edits, `hot_restart` after
  theme, `ColorScheme`, `TextTheme` or state-initialisation changes (theme
  edits often don't show after a hot reload). `get_runtime_errors` and
  `widget_inspector` when something renders wrong.
- If no app is running, start it with
  `flutter run -d emulator-5554 --print-dtd` in the background and connect
  with the Dart MCP `dtd` tool.

## Workflow (per screen)

### 1. Observe

Navigate to the screen like a user. Screenshot every meaningful state: empty,
loading, error, a long list, long names, offline. Read the screen's widget
source and every shared widget and theme file it uses.

### 2. Diagnose

Write 3–7 specific problems, each naming exact widgets and what's wrong, e.g.
"Stage name and date in `StageRow` are both 16px regular; the current stage
doesn't stand out." Not acceptable: "needs more contrast", "feels cluttered".

### 3. Fix

Targeted widget edits, not rewrites. One concern at a time (hierarchy, then
spacing, then colour emphasis). Hot reload or restart, then screenshot to
verify. If a change looks wrong, revert it; don't pile fixes on a broken
direction.

### 4. Evaluate (sub-agent)

Take "after" screenshots, then spawn an evaluator sub-agent with the Agent
tool, using this prompt (fill in SCREEN_NAME and NAVIGATION_HINT):

---

You are an independent design evaluator with no relationship to the agent
that made these changes. Be a skeptical, demanding critic. You are reviewing a
screen in SolaCliq, a Flutter app used by solar installers on cheap Android
phones in daylight, by sales agents and by homeowners.

Read the design tokens first: design/tokens.json. The app should look like
markcliq.com: Space Grotesk and Space Mono, uppercase tracked labels and
buttons, square corners, 1px rules. Judge against that.

The app is running on an Android emulator. Use mobile-mcp: call
`mobile_list_available_devices`, then `mobile_list_elements_on_screen`, tap
to reach SCREEN_NAME (NAVIGATION_HINT), and `mobile_take_screenshot` for each
meaningful state. Scroll, tap every tab, open menus. Do not edit any files.

Score 1–10 on each, with a 2–3 sentence justification:

- **Design quality (high weight):** a coherent whole that reads as SolaCliq
  (markcliq.com: flat, editorial, square, rust on warm paper), or a collection of parts?
- **Originality (high weight):** deliberate choices from the design system,
  or Material defaults and AI patterns? Sparkle icons, "smart"/"AI" badges,
  decorative charts or decoration foreign to the design system = automatic
  failure.
- **Craft (medium weight):** type hierarchy, spacing on the 4px scale,
  contrast, alignment, tabular numbers, money as `₹1,85,000.00`, dates as
  `18 Oct 2026`.
- **Functionality (medium weight):** can an installer find the action and
  finish the task one-handed in sunlight? Tap targets ≥ 48dp? Text readable?
  One accent action?

Calibration: 9–10 Apple Design Award calibre, almost never given; 7–8 solid
professional work; 5–6 generic Material defaults; 3–4 obvious problems; 1–2
broken. For any score above 7, name one thing a skeptical senior designer
would still criticise; if you can't, lower the score.

Then 3–5 bullets of remaining problems (specific widgets) and a verdict:
PASS (all 7+), ITERATE (any high-weight under 7), FAIL (any under 5).

```
DESIGN_QUALITY: X/10 — ...
ORIGINALITY: X/10 — ...
CRAFT: X/10 — ...
FUNCTIONALITY: X/10 — ...

CRITIQUE:
- ...

VERDICT: PASS/ITERATE/FAIL
```

---

### 5. React to the verdict

- **PASS:** next screen.
- **ITERATE:** the critique is your new diagnosis; back to step 3.
- **FAIL:** consider reverting to "before" and taking a different approach.
- At most 3 evaluation rounds per screen; at the cap keep the best-scoring
  version and report what's still open.

## Hierarchy toolkit (SolaCliq versions)

- 1px `line` rules between rows and sections; `line-strong` for control edges.
- `surface-sunken` behind a region that needs separating, not a card.
- Type weight and size; uppercase `label` headings to group.
- Spacing: related items 4–8, unrelated 24–32.
- `accent` for the single primary action; `ink-muted` to de-emphasise.
- A status tint (`success-tint` …) with its word for state.

## Anti-patterns

Anything foreign to the design system is wrong here, however good elsewhere:
shadows, elevation, gradients, rounded cards or `StadiumBorder` pills, blur,
FABs, hero banners, Lottie, parallax, decorative illustrations, emoji, and
"Welcome back!" greeters on a screen people open every day. Also:

- Shimmer or skeleton loaders without a real wait behind them.
- Charts or gauges that don't show real data.
- Inline `TextStyle(...)`, `Color(0x...)` or raw `EdgeInsets` numbers in
  widgets. When a screen looks off-tone, look for these first; the theme is
  usually fine and the widget is bypassing it.
- Functionality changes (routes, removed features, widget API changes): out
  of scope. Flag them, don't do them.

## Process rules

- One screen at a time; full cycle before the next.
- A new or changed token goes in the theme and applies to every screen that
  uses it; then re-screenshot those screens.
- Ignore status-bar differences between before/after screenshots.
- After each screen, run the analyzer (Dart MCP `analyze_files`) and the
  tests (Very Good CLI MCP `test`; plain `flutter test` is blocked by the VGV
  plugin hook). Fix issues before evaluating.
- Demo data on screen must be labelled "Illustrative".
