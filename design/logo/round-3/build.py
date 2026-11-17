"""SolaCliq round 3 (svg-design skill): MarkCliq's awning + a sun, warm & friendly.
Colours: MarkCliq rust #b2402c, sun #f6c445, ink #2a1f19, cream #fbf8f4. Each variant has a -dark file."""
import math, sys
RED, SUN, INK, CREAM, WHITE = "#b2402c", "#f6c445", "#2a1f19", "#fbf8f4", "#ffffff"
DARK = {"red": "#d2553f", "rail": CREAM, "white": CREAM, "sun": SUN}   # lifted red; cream instead of ink
LIGHT = {"red": RED, "rail": INK, "white": WHITE, "sun": SUN}
f = lambda x: f"{x:.2f}".rstrip("0").rstrip(".")
P = lambda p: f"{f(p[0])} {f(p[1])}"
def svg(body, w=256, h=256, title="SolaCliq"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">'
            f'<title>{title}</title>{body}</svg>\n')

def awning(c, x0, x1, y, drop, flare, n=5, rail_h=12, stroke=6, rail=True):
    """MarkCliq's awning: a rail, then n flared panels alternating red and white (red outline),
    each ending in a scallop. Returns svg and the panels' bottom y."""
    out = []
    if rail:
        out.append(f'<rect x="{f(x0-6)}" y="{f(y)}" width="{f(x1-x0+12)}" height="{rail_h}" rx="{rail_h/2}" fill="{c["rail"]}"/>')
        y += rail_h
    tw = (x1 - x0) / n
    bx0, bx1 = x0 - flare, x1 + flare
    bw = (bx1 - bx0) / n
    yb = y + drop
    for i in range(n):
        a, b = (x0 + i * tw, y), (x0 + (i + 1) * tw, y)
        cc, d = (bx0 + (i + 1) * bw, yb), (bx0 + i * bw, yb)
        r = bw / 2
        path = f"M{P(a)}L{P(b)}L{P(cc)}A{f(r)} {f(r)} 0 0 1 {P(d)}Z"
        if i % 2 == 0:
            out.append(f'<path d="{path}" fill="{c["red"]}"/>')
        else:
            edge = f"M{P(b)}L{P(cc)}A{f(r)} {f(r)} 0 0 1 {P(d)}L{P(a)}"
            out.append(f'<path d="{path}" fill="{c["white"]}"/>'
                       f'<path d="{edge}" fill="none" stroke="{c["red"]}" stroke-width="{stroke}" '
                       f'stroke-linejoin="round" stroke-linecap="butt"/>')
    return "".join(out), yb + bw / 2

def half_sun(c, cx, cy_flat, r, rise=0.0):
    """A sun showing above a flat cut at y=cy_flat; `rise` lifts the centre above the cut (more than half)."""
    cy = cy_flat - rise
    dx = math.sqrt(r * r - rise * rise)
    return (f'<path d="M{P((cx-dx, cy_flat))}A{f(r)} {f(r)} 0 {1 if rise > 0 else 0} 1 {P((cx+dx, cy_flat))}Z" '
            f'fill="{c["sun"]}"/>')

# 1 · Shopfront sunrise: the sun rises behind the awning's right half.
def shopfront(c):
    sun = half_sun(c, 172, 124, 50, rise=16)
    aw, _ = awning(c, 46, 206, 134, 34, 12)
    return svg(sun + aw)

# 2 · Sunrise window: an app-icon tile; the awning across the top, the sun rising in the window.
def window(c):
    tile = INK if c is DARK else CREAM
    body = f'<rect width="256" height="256" rx="58" fill="{tile}"/>'
    aw, _ = awning(c, 46, 210, 40, 30, 10)
    # The sun rises from the tile's bottom edge: the window frame is the horizon.
    sun = half_sun(c, 128, 256, 70, rise=0)
    return svg(body + aw + sun)

# 3 · Awning S: an S from two half-discs: a striped awning dome above, the sun below.
def awning_s(c, r=62, gap=14, shift=30, n=5):
    top_y, bot_y = 128 - gap / 2, 128 + gap / 2
    lx, rx = 128 - shift, 128 + shift
    out = []
    w = 2 * r / n
    for i in range(n):           # vertical stripes of the dome, each bounded by the arc
        x0, x1 = lx - r + i * w, lx - r + (i + 1) * w
        y = lambda x: top_y - math.sqrt(max(r * r - (x - lx) ** 2, 0))
        steps = 12
        pts = [(x0 + (x1 - x0) * k / steps, y(x0 + (x1 - x0) * k / steps)) for k in range(steps + 1)]
        d = f"M{P((x0, top_y))}" + "".join(f"L{P(q)}" for q in pts) + f"L{P((x1, top_y))}Z"
        fill = c["red"] if i % 2 == 0 else c["white"]
        out.append(f'<path d="{d}" fill="{fill}"/>')
    # The dome's outline keeps the white stripes from vanishing on a white background.
    out.append(f'<path d="M{P((lx-r+3, top_y))}A{f(r-3)} {f(r-3)} 0 0 1 {P((lx+r-3, top_y))}" fill="none" '
               f'stroke="{c["red"]}" stroke-width="6"/>')
    out.append(f'<path d="M{P((rx-r, bot_y))}A{r} {r} 0 0 0 {P((rx+r, bot_y))}Z" fill="{c["sun"]}"/>')
    return svg("".join(out))

# 4 · Hem sun: the awning's hem, five scallops (red, white, SUN, white, red): one scallop has become the sun.
def hem_sun(c, n=5, w=40, x0=28, y=104, stroke=6):
    rail = f'<rect x="{x0-4}" y="{y-14}" width="{n*w+8}" height="14" rx="7" fill="{c["rail"]}"/>'
    out = [rail]
    r = w / 2
    for i in range(n):
        a, b = x0 + i * w, x0 + (i + 1) * w
        cx = (a + b) / 2
        if i == n // 2:
            # The sun: a full disc hanging from the rail, a little larger than a scallop.
            out.append(f'<circle cx="{f(cx)}" cy="{f(y + r + 4)}" r="{f(r + 6)}" fill="{c["sun"]}"/>')
        elif i % 2 == 0:
            out.append(f'<path d="M{P((a, y))}L{P((b, y))}A{f(r)} {f(r)} 0 0 1 {P((a, y))}Z" fill="{c["red"]}"/>')
        else:
            h = stroke / 2
            out.append(f'<path d="M{P((a+h, y))}A{f(r-h)} {f(r-h)} 0 0 0 {P((b-h, y))}" fill="{c["white"]}" '
                       f'stroke="{c["red"]}" stroke-width="{stroke}"/>')
    return svg("".join(out))

# 5 · Wordmark: MarkCliq's way ("Mark" upright, "Cliq" italic, a coloured dot) with the i's dot a sun.
def wordmark(c):
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.pens.boundsPen import BoundsPen
    font = instancer.instantiateVariableFont(
        TTFont("/home/dev/Desktop/SolaCliq/mobile/packages/sola_ui/assets/fonts/Inter-Variable.ttf"),
        {"wght": 600, "opsz": 32} if "opsz" in [a.axisTag for a in TTFont("/home/dev/Desktop/SolaCliq/mobile/packages/sola_ui/assets/fonts/Inter-Variable.ttf")["fvar"].axes] else {"wght": 600})
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    upm = font["head"].unitsPerEm
    size, base = 96, 118                      # font size and baseline in the viewBox
    k = size / upm
    slant = math.tan(math.radians(10))        # MarkCliq's italic "Cliq", as an oblique
    x, out, dot = 24.0, [], None
    muted = "#9a8f85" if c is DARK else "#6d635a"
    for ch, colour, oblique in [(ch, c["rail"], False) for ch in "Sola"] + [(ch, muted, True) for ch in "Clıq"]:
        name = cmap[ord(ch)]
        pen = SVGPathPen(gs)
        sh = slant if oblique else 0
        # font units, y up -> viewBox, y down; oblique shears x by height above the baseline
        tp = TransformPen(pen, (k, 0, sh * k, -k, x, base))
        gs[name].draw(tp)
        out.append(f'<path d="{pen.getCommands()}" fill="{colour}"/>')
        if ch == "ı":
            bp = BoundsPen(gs); gs[name].draw(bp)
            xmin, ymin, xmax, ymax = bp.bounds
            stem_top = ymax * k
            cx = x + (xmin + xmax) / 2 * k + sh * (stem_top + 30)
            dot = (cx, base - stem_top - 30)
        x += hmtx[name][0] * k + (2 if not oblique else 1)
    if dot:
        out.append(f'<circle cx="{f(dot[0])}" cy="{f(dot[1])}" r="15" fill="{c["sun"]}"/>')
    w = math.ceil(x + 20)
    return svg("".join(out), w=w, h=160, title="SolaCliq")

# 2b · Sunrise window, sun on top (owner, 2026-11-17): the sun above, the awning underneath.
def window_sky(c):
    """A full sun in the sky over the shopfront awning."""
    tile = INK if c is DARK else CREAM
    body = f'<rect width="256" height="256" rx="58" fill="{tile}"/>'
    sun = f'<circle cx="128" cy="86" r="44" fill="{c["sun"]}"/>'
    aw, _ = awning(c, 50, 206, 146, 34, 12)
    return svg(body + sun + aw)

def window_rise(c):
    """A half-sun rising from behind the awning's rail."""
    tile = INK if c is DARK else CREAM
    body = f'<rect width="256" height="256" rx="58" fill="{tile}"/>'
    sun = half_sun(c, 128, 116, 60, rise=14)
    aw, _ = awning(c, 50, 206, 126, 34, 12)
    return svg(body + sun + aw)

VARIANTS = {"window-sky": window_sky, "window-rise": window_rise, "shopfront": shopfront, "window": window, "awning-s": awning_s, "hem-sun": hem_sun, "wordmark": wordmark}
if __name__ == "__main__":
    only = sys.argv[1:] or list(VARIANTS)
    for name in only:
        open(f"logo-{name}.svg", "w").write(VARIANTS[name](LIGHT))
        open(f"logo-{name}-dark.svg", "w").write(VARIANTS[name](DARK))
    print("built", ", ".join(only))
