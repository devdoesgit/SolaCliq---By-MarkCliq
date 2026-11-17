"""
SolaCliq logo kit: every logo file, from one geometry
--------------------------------------------------------------------
- the chosen mark (owner, 2026-11-17): SolaCliq's sun rising behind
  MarkCliq's awning, on a cream app-icon tile (round 3, 02a)
- run from the repo root, with fontTools available (the wordmark's
  letters are outlines of Inter, the app's own font, OFL):
      python3 design/logo/kit/build_kit.py
- writes design/logo/kit/svg/ (masters), design/logo/kit/png/, the
  web icons, and the Android icons for every flavour in mobile/android
- the geometry lives in one place below; change it there and run again
"""
import math
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / "design/logo/kit"
SVG_DIR, PNG_DIR, WEB_DIR = KIT / "svg", KIT / "png", KIT / "web"
RES = ROOT / "mobile/android/app/src"
FONT = ROOT / "mobile/packages/sola_ui/assets/fonts/Inter-Variable.ttf"
RENDER = Path.home() / ".claude/skills/logo-design/scripts/render_png.py"

# ---------------------------------------------------------------- colours
RUST = "#b2402c"      # MarkCliq's awning red (AGENCY.md)
SUN = "#f6c445"       # SolaCliq's sun (design/tokens.json "sun")
INK = "#2a1f19"       # tokens "ink"
CREAM = "#fbf8f4"     # tokens "cream"
WHITE = "#ffffff"
MUTED = "#6d635a"     # tokens "muted": "Cliq", as MarkCliq greys its "Cliq"
LIGHT = {"rust": RUST, "sun": SUN, "rail": INK, "stripe": WHITE, "word": INK, "cliq": MUTED, "tile": CREAM}
DARK = {"rust": "#d2553f", "sun": SUN, "rail": CREAM, "stripe": CREAM, "word": CREAM, "cliq": "#a89d93",
        "tile": INK}


def one_colour(c):
    """Everything in colour c; the white stripes become holes (no fill)."""
    return {"rust": c, "sun": c, "rail": c, "stripe": None, "word": c, "cliq": c, "tile": None}


# --------------------------------------------------------------- geometry
# The symbol on a 256 canvas (the app icon's tile is the whole canvas).
SUN_C, SUN_R, SUN_FLAT = (128, 102), 60, 116       # a half-sun showing above y=116 (rising)
RAIL = (44, 126, 168, 12)                          # x, y, width, height (round ends)
AW_X0, AW_X1, AW_TOP, DROP, FLARE, N = 50, 206, 138, 34, 12, 5
STRIPE_LINE = 6                                    # the white stripes' rust outline
SYMBOL_BOX = (38, 42, 218, 190)                    # the symbol's ink: x0, y0, x1, y1

f = lambda x: f"{x:.2f}".rstrip("0").rstrip(".")
P = lambda p: f"{f(p[0])} {f(p[1])}"


def rail_path():
    x, y, w, h = RAIL
    r = h / 2
    return (f"M{f(x+r)} {f(y)}L{f(x+w-r)} {f(y)}A{f(r)} {f(r)} 0 0 1 {f(x+w-r)} {f(y+h)}"
            f"L{f(x+r)} {f(y+h)}A{f(r)} {f(r)} 0 0 1 {f(x+r)} {f(y)}Z")


def sun_path():
    cx, cy = SUN_C
    rise = cy - SUN_FLAT
    dy = SUN_FLAT - cy
    dx = math.sqrt(SUN_R ** 2 - dy ** 2)
    return f"M{P((cx-dx, SUN_FLAT))}A{SUN_R} {SUN_R} 0 {1 if rise < 0 else 0} 1 {P((cx+dx, SUN_FLAT))}Z"


def panels():
    """The five awning panels: (kind, fill path, outline path or None)."""
    tw = (AW_X1 - AW_X0) / N
    bx0, bx1 = AW_X0 - FLARE, AW_X1 + FLARE
    bw = (bx1 - bx0) / N
    yb = AW_TOP + DROP
    out = []
    for i in range(N):
        a, b = (AW_X0 + i * tw, AW_TOP), (AW_X0 + (i + 1) * tw, AW_TOP)
        c, d = (bx0 + (i + 1) * bw, yb), (bx0 + i * bw, yb)
        r = bw / 2
        fill = f"M{P(a)}L{P(b)}L{P(c)}A{f(r)} {f(r)} 0 0 1 {P(d)}Z"
        if i % 2 == 0:
            out.append(("rust", fill, None))
        else:  # outlined on its sides and scallop, not along the rail
            out.append(("stripe", fill, f"M{P(b)}L{P(c)}A{f(r)} {f(r)} 0 0 1 {P(d)}L{P(a)}"))
    return out


def shapes(c, small=False):
    """The symbol as (fill colour or None, path, stroke colour or None) in paint order.
    small: the small-size cut for 16-24 px (status bar, favicon): all five panels solid and
    joined, so the outline stays a scalloped awning hem (three separate panels read as legs)."""
    out = [(c["sun"], sun_path(), None), (c["rail"], rail_path(), None)]
    for kind, fill, line in panels():
        if kind == "rust" or small:
            out.append((c["rust"], fill, None))
        else:
            if c["stripe"]:
                out.append((c["stripe"], fill, None))
            out.append((None, line, c["rust"]))
    return out


def svg_paths(items, transform=None):
    out = []
    for fill, d, stroke in items:
        d = tpath(d, *transform) if transform else d
        if stroke:
            sw = STRIPE_LINE * (transform[0] if transform else 1)
            out.append(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{f(sw)}" '
                       f'stroke-linejoin="round" stroke-linecap="butt"/>')
        else:
            out.append(f'<path d="{d}" fill="{fill}"/>')
    return "".join(out)


def svg(body, w=256, h=256, title="SolaCliq"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {f(w)} {f(h)}">'
            f"<title>{title}</title>{body}</svg>\n")


def tile_path(r=58, size=256):
    return (f"M{r} 0H{size-r}A{r} {r} 0 0 1 {size} {r}V{size-r}A{r} {r} 0 0 1 {size-r} {size}"
            f"H{r}A{r} {r} 0 0 1 0 {size-r}V{r}A{r} {r} 0 0 1 {r} 0Z")


# ------------------------------------------------- path transform (s, dx, dy)
TOKEN = re.compile(r"[MLHVCQAZmlhvcqaz]|-?\d*\.?\d+(?:e-?\d+)?")


def tpath(d, s, dx, dy):
    """Scales (uniformly) and moves an absolute path: M L H V C Q A Z."""
    toks = TOKEN.findall(d)
    out, i, cmd = [], 0, None
    nums = lambda k: [float(t) for t in toks[i:i + k]]
    X = lambda x: f(x * s + dx)
    Y = lambda y: f(y * s + dy)
    while i < len(toks):
        t = toks[i]
        if t.isalpha():
            cmd = t
            i += 1
            if cmd in "Zz":
                out.append("Z")
            continue
        if cmd in "ML":
            x, y = nums(2); i += 2; out.append(f"{cmd}{X(x)} {Y(y)}")
            if cmd == "M":
                cmd = "L"   # more pairs after a move are lines (SVG's implicit lineto)
        elif cmd == "H":
            x, = nums(1); i += 1; out.append(f"H{X(x)}")
        elif cmd == "V":
            y, = nums(1); i += 1; out.append(f"V{Y(y)}")
        elif cmd == "C":
            a = nums(6); i += 6
            out.append("C" + " ".join(f"{X(a[k])} {Y(a[k+1])}" for k in (0, 2, 4)))
        elif cmd == "Q":
            a = nums(4); i += 4
            out.append("Q" + " ".join(f"{X(a[k])} {Y(a[k+1])}" for k in (0, 2)))
        elif cmd == "A":
            rx, ry, rot, la, sw, x, y = nums(7); i += 7
            out.append(f"A{f(rx*s)} {f(ry*s)} {f(rot)} {int(la)} {int(sw)} {X(x)} {Y(y)}")
        else:
            raise ValueError(f"unsupported command {cmd}")
    return "".join(out)


# --------------------------------------------------------------- wordmark
def wordmark_shapes(c):
    """'Sola' upright + 'Cliq' oblique (MarkCliq's way), the i's dot a sun.
    Returns (items, width, height) on a canvas with the baseline at 118, cap height ~70."""
    from fontTools.pens.boundsPen import BoundsPen
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer
    src = TTFont(FONT)
    axes = {"wght": 600}
    if "opsz" in [a.axisTag for a in src["fvar"].axes]:
        axes["opsz"] = 32
    font = instancer.instantiateVariableFont(src, axes)
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    k = 96 / font["head"].unitsPerEm
    base, slant = 118, math.tan(math.radians(10))
    x, items, dot = 0.0, [], None
    for ch, colour, oblique in [(ch, c["word"], False) for ch in "Sola"] + [(ch, c["cliq"], True) for ch in "Clıq"]:
        name = cmap[ord(ch)]
        pen = SVGPathPen(gs)
        sh = slant if oblique else 0
        gs[name].draw(TransformPen(pen, (k, 0, sh * k, -k, x, base)))
        items.append((colour, pen.getCommands(), None))
        if ch == "ı":
            bp = BoundsPen(gs)
            gs[name].draw(bp)
            xmin, _, xmax, ymax = bp.bounds
            top = ymax * k
            dot = (x + (xmin + xmax) / 2 * k + sh * (top + 30), base - top - 30)
        x += hmtx[name][0] * k + (1 if oblique else 2)
    if dot:
        r = 15
        items.append((c["sun"], f"M{P((dot[0]-r, dot[1]))}A{r} {r} 0 1 1 {P((dot[0]+r, dot[1]))}"
                                f"A{r} {r} 0 1 1 {P((dot[0]-r, dot[1]))}Z", None))
    return items, x, 160


# ------------------------------------------------------------- the masters
def symbol(c, small=False):
    return svg(svg_paths(shapes(c, small)))


def icon(c, small=False, round_tile=False):
    tile = (f'<circle cx="128" cy="128" r="128" fill="{c["tile"]}"/>' if round_tile
            else f'<path d="{tile_path()}" fill="{c["tile"]}"/>')
    return svg(tile + svg_paths(shapes(c, small)))


def wordmark(c):
    items, w, h = wordmark_shapes(c)
    pad = 8
    return svg(svg_paths(items, (1, pad, 0)), w=w + 2 * pad, h=h)


def lockup_horizontal(c):
    """The symbol left, the wordmark right; the symbol's height = the wordmark's cap height × 2."""
    items, w, _ = wordmark_shapes(c)
    sx0, sy0, sx1, sy1 = SYMBOL_BOX
    s = 132 / (sy1 - sy0)                        # symbol 132 tall
    sym = svg_paths(shapes(c), (s, -sx0 * s + 12, -sy0 * s + 14))
    sym_w = (sx1 - sx0) * s
    gap = 34
    word = svg_paths(items, (1, 12 + sym_w + gap, 0))
    return svg(sym + word, w=12 + sym_w + gap + w + 12, h=160)


def lockup_stacked(c):
    items, w, _ = wordmark_shapes(c)
    sx0, sy0, sx1, sy1 = SYMBOL_BOX
    s = 1.3
    sym_w, sym_h = (sx1 - sx0) * s, (sy1 - sy0) * s
    width = max(w, sym_w) + 24
    sym = svg_paths(shapes(c), (s, (width - sym_w) / 2 - sx0 * s, 12 - sy0 * s))
    word = svg_paths(items, (1, (width - w) / 2, 12 + sym_h + 6 - 33))
    return svg(sym + word, w=width, h=12 + sym_h + 6 + 148 - 33 + 14)


# ----------------------------------------------------------------- splash
# Android 12+ draws the splash icon at 288 dp and shows what's inside the middle
# 192 dp circle (measured on the emulator, 2026-11-18); Android 7-11's launch
# screen and the app's SplashPage draw the same 288 square, centred.
SPLASH, SPLASH_CIRCLE = 288, 192


def ink_bounds(items):
    """The box around every point of the paths (arcs: their ends ± radius)."""
    xs, ys = [], []
    for _, d, _ in items:
        toks = TOKEN.findall(d)
        i, cmd = 0, None
        while i < len(toks):
            t = toks[i]
            if t.isalpha():
                cmd = t; i += 1
                continue
            if cmd == "A":
                rx, ry, _, _, _, x, y = (float(v) for v in toks[i:i + 7]); i += 7
                xs += [x - rx, x + rx]; ys += [y - ry, y + ry]
            elif cmd in "HV":
                (xs if cmd == "H" else ys).append(float(t)); i += 1
            else:
                xs.append(float(toks[i])); ys.append(float(toks[i + 1])); i += 2
    return min(xs), min(ys), max(xs), max(ys)


def splash_layout(c):
    """The mark over the wordmark, as two (items, scale, dx, dy) placements in the
    288 splash square: as large as fits the 192 circle, centred."""
    word, _, _ = wordmark_shapes(c)
    wx0, wy0, wx1, wy1 = ink_bounds(word)
    sx0, sy0, sx1, sy1 = SYMBOL_BOX
    # In symbol units: the wordmark 1.25× the mark’s width, 24 units below it.
    ws = 1.25 * (sx1 - sx0) / (wx1 - wx0)
    gap = 24
    w = max(sx1 - sx0, (wx1 - wx0) * ws)
    h = (sy1 - sy0) + gap + (wy1 - wy0) * ws
    k = SPLASH_CIRCLE * 0.97 / math.hypot(w, h)      # its box's corners just inside the circle
    top = SPLASH / 2 - h * k / 2
    left = SPLASH / 2 - (sx1 - sx0) * k / 2
    sym = (shapes(c), k, left - sx0 * k, top - sy0 * k)
    wk = ws * k
    wtop = top + ((sy1 - sy0) + gap) * k
    wleft = SPLASH / 2 - (wx1 - wx0) * wk / 2
    words = (word, wk, wleft - wx0 * wk, wtop - wy0 * wk)
    return [sym, words]


def splash_svg(c):
    body = "".join(svg_paths(items, (k, dx, dy)) for items, k, dx, dy in splash_layout(c))
    return svg(body, w=SPLASH, h=SPLASH)


def splash_vector(c):
    """One drawable with two groups: the mark, and the wordmark under it."""
    groups = []
    for items, k, dx, dy in splash_layout(c):
        g = (f'<group android:scaleX="{f(k)}" android:scaleY="{f(k)}" '
             f'android:translateX="{f(dx)}" android:translateY="{f(dy)}">')
        whole = vector(items, SPLASH, SPLASH, g)
        groups.append(re.search(r"  <group.*</group>\n", whole, re.S).group(0))
    head = vector([], SPLASH, SPLASH).rsplit("</vector>", 1)[0].rstrip("\n") + "\n"
    return head + "".join(groups) + "</vector>\n"


# ---------------------------------------------------------------- Android
BADGE_GROUP = '<group android:scaleX="0.0675" android:scaleY="0.0675" android:translateX="19.44" android:translateY="19.44">'


def badge_paths(flavour):
    """The flavour's existing DEV/STG band and label (kept as they were)."""
    if flavour == "main":
        return []
    old = (KIT / "android-badges" / f"{flavour}.xml").read_text()
    return re.findall(r'<path android:pathData="([^"]+)" android:fillColor="([^"]+)"/>', old)


def vector(items, size_dp, viewport, group=None, tint=None, extra=""):
    """An Android VectorDrawable from (fill, path, stroke) items in the 256 symbol space."""
    head = (f'<?xml version="1.0" encoding="utf-8"?>\n'
            f'<!-- Generated by design/logo/kit/build_kit.py: edit the geometry there, not here. -->\n'
            f'<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            f'    android:width="{size_dp}dp" android:height="{size_dp}dp"\n'
            f'    android:viewportWidth="{viewport}" android:viewportHeight="{viewport}"'
            + (f'\n    android:tint="{tint}"' if tint else "") + ">\n")
    body = []
    for fill, d, stroke in items:
        if stroke:
            body.append(f'    <path android:pathData="{d}" android:strokeColor="{stroke}" '
                        f'android:strokeWidth="{STRIPE_LINE}" android:strokeLineJoin="round" '
                        f'android:strokeLineCap="butt"/>')
        else:
            body.append(f'    <path android:pathData="{d}" android:fillColor="{fill}"/>')
    inner = "\n".join(body)
    if group:
        inner = f"  {group}\n{inner}\n  </group>"
    return head + inner + "\n" + extra + "</vector>\n"


def symbol_group(target, center=(54, 54), lift=1.5):
    """Places the symbol so its ink is `target` dp wide, centred (a little above centre: optical)."""
    sx0, sy0, sx1, sy1 = SYMBOL_BOX
    s = target / (sx1 - sx0)
    tx = center[0] - (sx0 + sx1) / 2 * s
    ty = center[1] - lift - (sy0 + sy1) / 2 * s
    return (f'<group android:scaleX="{f(s)}" android:scaleY="{f(s)}" '
            f'android:translateX="{f(tx)}" android:translateY="{f(ty)}">')


def write_android():
    # The adaptive icon's foreground, per flavour (dev and staging keep their badge).
    for flavour in ["main", "development", "staging"]:
        res = RES / flavour / "res"
        badge = badge_paths(flavour)
        extra = ""
        if badge:
            extra = ("  " + BADGE_GROUP + "\n" + "\n".join(
                f'    <path android:pathData="{d}" android:fillColor="{c}"/>' for d, c in badge)
                + "\n  </group>\n")
        # 48 dp wide: the whole mark sits inside the launcher's circle (the middle 72 dp of
        # the 108 dp layer, 66 dp safe), clear of the flavour badge along the bottom.
        fg = vector(shapes(LIGHT), 108, 108, symbol_group(48, center=(54, 51 if badge else 54)), extra=extra)
        (res / "drawable/ic_launcher_foreground.xml").write_text(fg)
        (res / "values/ic_launcher_background.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
            f'    <color name="ic_launcher_background">{CREAM.upper()}</color>\n</resources>\n')
        for name in ["ic_launcher", "ic_launcher_round"]:
            (res / f"mipmap-anydpi-v26/{name}.xml").write_text(
                '<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
                '</adaptive-icon>\n')
    # Themed icons (Android 13+): the small cut in one colour; the system tints it.
    mono = vector(shapes(one_colour("#000000"), small=True), 108, 108, symbol_group(48))
    (RES / "main/res/drawable/ic_launcher_monochrome.xml").write_text(mono)
    # The status-bar icon: the small cut, white (Android tints it), 24 dp.
    s = 22 / (SYMBOL_BOX[2] - SYMBOL_BOX[0])
    g = (f'<group android:scaleX="{f(s)}" android:scaleY="{f(s)}" '
         f'android:translateX="{f(12 - (SYMBOL_BOX[0]+SYMBOL_BOX[2])/2*s)}" '
         f'android:translateY="{f(12 - (SYMBOL_BOX[1]+SYMBOL_BOX[3])/2*s)}">')
    note = ("<!-- The status-bar icon for push notifications: SolaCliq's mark, small cut, one colour\n"
            "     (Android tints it). Generated by design/logo/kit/build_kit.py. -->\n")
    xml = vector(shapes(one_colour("#FFFFFFFF"), small=True), 24, 24, g)
    (RES / "main/res/drawable/ic_notification.xml").write_text(xml.replace("<vector", note + "<vector", 1))
    # The launch screen's mark and wordmark, the same for every flavour.
    (RES / "main/res/drawable/ic_splash.xml").write_text(splash_vector(LIGHT))


def legacy_pngs():
    """Pre-Android-8 launcher PNGs, per flavour: the tile (rounded square) and a round one."""
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    tmp = KIT / ".tmp"
    tmp.mkdir(exist_ok=True)
    for flavour in ["main", "development", "staging"]:
        badge = badge_paths(flavour)
        band = ""
        if badge:
            # The badge in the icon's 256 space: the 1024 badge canvas covered the 108 dp
            # foreground's middle 69 dp; on a full tile that's the tile's lower part.
            band = ('<g transform="scale(0.25)">'
                    + "".join(f'<path d="{d}" fill="{c}"/>' for d, c in badge) + "</g>")
        for shape, round_tile in [("ic_launcher", False), ("ic_launcher_round", True)]:
            src = tmp / f"{flavour}-{shape}.svg"
            body = icon(LIGHT, round_tile=round_tile)
            if band:
                clip = ('<clipPath id="t"><circle cx="128" cy="128" r="128"/></clipPath>' if round_tile
                        else f'<clipPath id="t"><path d="{tile_path()}"/></clipPath>')
                body = body.replace("</svg>", f'<defs>{clip}</defs><g clip-path="url(#t)">{band}</g></svg>')
            src.write_text(body)
            for dens, px in sizes.items():
                out = RES / flavour / f"res/mipmap-{dens}"
                render(src, out, px, f"{shape}.png")
    for p in tmp.iterdir():
        p.unlink()
    tmp.rmdir()


def render(src, out_dir, px, name):
    """A PNG `px` wide, keeping the SVG's proportions (square marks: px × px)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', Path(src).read_text()).group(1).split()]
    h = round(px * vb[3] / vb[2])
    subprocess.run([sys.executable, "-I", str(RENDER), str(src), "-o", str(out_dir / name),
                    "--width", str(px), "--height", str(h)], check=True, stdout=subprocess.DEVNULL)


def tool_render(src, out_dir, px, name):
    render(src, out_dir, px, name)


# ---------------------------------------------------------------- Flutter
FLUTTER_LOGO = ROOT / "mobile/packages/sola_ui/lib/src/brand/logo.g.dart"


def write_flutter():
    """The mark, the splash square and the wordmark for the app (sola_ui), as Dart strings."""
    x0, y0, x1, y1 = SYMBOL_BOX
    mark = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {x1-x0} {y1-y0}">'
            f"{svg_paths(shapes(LIGHT))}</svg>")
    items, _, _ = wordmark_shapes(LIGHT)
    wx0, wy0, wx1, wy1 = ink_bounds(items)
    word = (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'viewBox="{f(wx0)} {f(wy0)} {f(wx1-wx0)} {f(wy1-wy0)}">{svg_paths(items)}</svg>')
    FLUTTER_LOGO.parent.mkdir(parents=True, exist_ok=True)
    FLUTTER_LOGO.write_text(
        "// Generated by design/logo/kit/build_kit.py: edit the geometry there, not here.\n\n"
        "/// SolaCliq's mark (the sun rising behind MarkCliq's awning), tight to its\n"
        f"/// ink: {x1-x0} × {y1-y0}.\n"
        f"const double solaLogoAspect = {x1-x0} / {y1-y0};\n\n"
        "/// The mark's SVG.\n"
        f"const solaLogoSvg = '''{mark}''';\n\n"
        "/// The launch screen's square: the mark over the wordmark, as Android draws\n"
        f"/// it ({SPLASH} dp, centred).\n"
        f"const double solaSplashSize = {SPLASH};\n\n"
        "/// The launch screen's SVG.\n"
        f"const solaSplashSvg = '''{splash_svg(LIGHT).strip()}''';\n\n"
        "/// The wordmark (\"Sola\" upright, \"Cliq\" oblique, the i's dot a sun), tight\n"
        f"/// to its ink: {f(wx1-wx0)} × {f(wy1-wy0)}.\n"
        f"const double solaWordmarkAspect = {f(wx1-wx0)} / {f(wy1-wy0)};\n\n"
        "/// The wordmark's SVG.\n"
        f"const solaWordmarkSvg = '''{word}''';\n")


# ------------------------------------------------------------------- main
def main():
    for d in (SVG_DIR, PNG_DIR, WEB_DIR):
        d.mkdir(parents=True, exist_ok=True)
    files = {
        "solacliq-icon.svg": icon(LIGHT),
        "solacliq-icon-dark.svg": icon(DARK),
        "solacliq-icon-small.svg": icon(LIGHT, small=True),
        "solacliq-symbol.svg": symbol(LIGHT),
        "solacliq-symbol-dark.svg": symbol(DARK),
        "solacliq-symbol-small.svg": symbol(LIGHT, small=True),
        "solacliq-symbol-black.svg": symbol(one_colour("#000000")),
        "solacliq-symbol-white.svg": symbol(one_colour("#ffffff")),
        "solacliq-wordmark.svg": wordmark(LIGHT),
        "solacliq-wordmark-dark.svg": wordmark(DARK),
        "solacliq-wordmark-black.svg": wordmark(one_colour("#000000")),
        "solacliq-lockup-horizontal.svg": lockup_horizontal(LIGHT),
        "solacliq-lockup-horizontal-dark.svg": lockup_horizontal(DARK),
        "solacliq-lockup-stacked.svg": lockup_stacked(LIGHT),
        "solacliq-lockup-stacked-dark.svg": lockup_stacked(DARK),
        "solacliq-splash.svg": splash_svg(LIGHT),
    }
    for name, text in files.items():
        (SVG_DIR / name).write_text(text)
    # PNGs for documents and the website.
    for name, px in [("solacliq-icon.svg", 1024), ("solacliq-icon.svg", 512), ("solacliq-symbol.svg", 512),
                     ("solacliq-lockup-horizontal.svg", 1200), ("solacliq-lockup-horizontal-dark.svg", 1200),
                     ("solacliq-lockup-stacked.svg", 800)]:
        tool_render(SVG_DIR / name, PNG_DIR, px, f"{Path(name).stem}-{px}.png")
    # Web icons: the full tile from 32 px up, the small cut below.
    for name, px in [("solacliq-icon.svg", 180), ("solacliq-icon.svg", 192), ("solacliq-icon.svg", 512),
                     ("solacliq-icon.svg", 48), ("solacliq-icon.svg", 32), ("solacliq-icon-small.svg", 16)]:
        tool_render(SVG_DIR / name, WEB_DIR, px, f"icon-{px}.png")
    (WEB_DIR / "favicon.svg").write_text(files["solacliq-icon-small.svg"])
    subprocess.run([sys.executable, "-I", str(RENDER), str(WEB_DIR / "favicon.svg"), "--ico",
                    str(WEB_DIR / "favicon.ico"), "--ico-sizes", "16", "32", "48"],
                   check=True, stdout=subprocess.DEVNULL)
    write_android()
    legacy_pngs()
    write_flutter()
    print("kit built:", len(files), "SVGs, PNGs, web icons, Android icons for main, development, staging")


if __name__ == "__main__":
    main()
