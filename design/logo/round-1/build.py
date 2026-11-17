"""SolaCliq logo concepts, built from exact geometry (viewBox 256)."""
import math, sys
V = sys.argv[1] if len(sys.argv) > 1 else "v1"

def svg(body, w=256, h=256):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f'{body}</svg>\n')

def f(x): return f"{x:.2f}".rstrip("0").rstrip(".")

# A: a core sun and 7 ring segments = the 7 install stages (gaps of constant width).
def concept_a(core=46, r_in=74, r_out=94, gap=16, n=7):
    cx = cy = 128
    parts = [f'<circle cx="128" cy="128" r="{core}"/>']
    for i in range(n):
        # Each segment spans 360/n degrees minus a gap of constant width (so gaps stay parallel).
        a0 = -90 + i * 360 / n
        a1 = a0 + 360 / n
        def ang(r, a, side):  # shift the edge by half the gap, measured as an arc at radius r
            return a + side * math.degrees((gap / 2) / r)
        pts = []
        o0, o1 = ang(r_out, a0, 1), ang(r_out, a1, -1)
        i0, i1 = ang(r_in, a0, 1), ang(r_in, a1, -1)
        P = lambda r, a: (cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
        (x0, y0), (x1, y1) = P(r_out, o0), P(r_out, o1)
        (x2, y2), (x3, y3) = P(r_in, i1), P(r_in, i0)
        parts.append(f'<path d="M{f(x0)} {f(y0)}A{r_out} {r_out} 0 0 1 {f(x1)} {f(y1)}'
                     f'L{f(x2)} {f(y2)}A{r_in} {r_in} 0 0 0 {f(x3)} {f(y3)}Z"/>')
    return svg("".join(parts))

# B: the roof is the horizon: a sun rising behind one roof ridge (30° pitch), cut by it with a gap.
# The sun sits off the ridge, so the pair can't read as a head and shoulders.
def concept_b(sun_c=(180, 110), sun_r=54, apex=(120, 128), half=88, stroke=30, gap=12):
    t = math.tan(math.radians(30))
    ax, ay = apex
    # The roof as a filled outline (round caps and ridge), not a stroke.
    h = stroke / 2
    L, R = (ax - half, ay + half * t), (ax + half, ay + half * t)
    n1, n2 = (-0.5, -math.sqrt(3) / 2), (0.5, -math.sqrt(3) / 2)   # upward normals of each slope
    add = lambda p, n, k: (p[0] + k * n[0], p[1] + k * n[1])
    pts = [add(L, n1, h), add((ax, ay), n1, h), add((ax, ay), n2, h), add(R, n2, h), add(R, n2, -h),
           (ax, ay + h / math.sin(math.radians(60))), add(L, n1, -h)]
    P2 = lambda p: f"{f(p[0])} {f(p[1])}"
    roof = (f'<path d="M{P2(pts[0])}L{P2(pts[1])}A{h} {h} 0 0 1 {P2(pts[2])}L{P2(pts[3])}'
            f'A{h} {h} 0 0 1 {P2(pts[4])}L{P2(pts[5])}L{P2(pts[6])}A{h} {h} 0 0 1 {P2(pts[0])}Z"/>')
    edge_y = ay - (stroke / 2) / math.cos(math.radians(30)) - gap
    edge = lambda x: edge_y + t * abs(x - ax)       # the roof's top edge, less the gap
    cx, cy = sun_c
    P = lambda a: (cx + sun_r * math.cos(a), cy + sun_r * math.sin(a))
    above = lambda a: P(a)[1] < edge(P(a)[0])
    # Walk the circle; find where it crosses the roof edge (bisection on each sign change).
    n = 3600; cross = []
    for k in range(n):
        a0, a1 = 2*math.pi*k/n, 2*math.pi*(k+1)/n
        if above(a0) != above(a1):
            lo, hi = a0, a1
            for _ in range(60):
                mid = (lo + hi) / 2
                (lo, hi) = (mid, hi) if above(mid) == above(lo) else (lo, mid)
            cross.append(((lo+hi)/2, above(a0)))
    # Going round (y down = clockwise on screen), the visible arc runs from the crossing where we enter
    # "above" to the one where we leave it.
    enter = [a for a, was in cross if not was][0]
    leave = [a for a, was in cross if was][0]
    span = (leave - enter) % (2*math.pi)
    (x0, y0), (x1, y1) = P(enter), P(leave)
    large = 1 if span > math.pi else 0
    d = f"M{f(x0)} {f(y0)}A{sun_r} {sun_r} 0 {large} 1 {f(x1)} {f(y1)}"
    if min(x0, x1) < ax < max(x0, x1):
        d += f"L{f(ax)} {f(edge_y)}"
    sun = f'<path d="{d}Z"/>'
    return svg(roof + sun)

# C: an S from a sunrise and its reflection: a dome over a bowl, offset, with a horizon gap.
def concept_c(r=60, gap=20, shift=34):
    top_y = 128 - gap / 2          # flat edge of the dome
    bot_y = 128 + gap / 2          # flat edge of the bowl
    lx, rx = 128 - shift, 128 + shift
    dome = f'<path d="M{f(lx-r)} {f(top_y)}A{r} {r} 0 0 1 {f(lx+r)} {f(top_y)}Z"/>'
    bowl = f'<path d="M{f(rx-r)} {f(bot_y)}A{r} {r} 0 0 0 {f(rx+r)} {f(bot_y)}Z"/>'
    return svg(dome + bowl)

for name, fn in [("a", concept_a), ("b", concept_b), ("c", concept_c)]:
    open(f"concept-{name}-{V}.svg", "w").write(fn())
print("built", V)
