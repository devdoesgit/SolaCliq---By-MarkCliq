"""Round 2, v4: MarkCliq's awning front-on (5 flared, alternating panels), the sun rising at the rail's end."""
import math, sys
V = sys.argv[1] if len(sys.argv) > 1 else "v4"
def f(x): return f"{x:.2f}".rstrip("0").rstrip(".")
def svg(body): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">{body}</svg>\n'
P = lambda p: f"{f(p[0])} {f(p[1])}"

RAIL_X0, RAIL_X1, RAIL_Y, RAIL_H = 40, 220, 128, 12
AW_TOP = RAIL_Y + RAIL_H
TOP_X0, TOP_X1 = 48, 212            # panels hang from here...
BOT_X0, BOT_X1 = 34, 226            # ...and flare out to here
DROP = 34                            # depth of the straight part
N = 5
STROKE = 6
SUN_C, SUN_R, GAP = (178, 102), 48, 10

def panels():
    out = []
    tw, bw = (TOP_X1 - TOP_X0) / N, (BOT_X1 - BOT_X0) / N
    y = AW_TOP + DROP
    for i in range(N):
        a, b = (TOP_X0 + i * tw, AW_TOP), (TOP_X0 + (i + 1) * tw, AW_TOP)
        c, d = (BOT_X0 + (i + 1) * bw, y), (BOT_X0 + i * bw, y)
        r = bw / 2
        if i % 2 == 0:  # MarkCliq's red stripe: solid
            out.append(f'<path d="M{P(a)}L{P(b)}L{P(c)}A{f(r)} {f(r)} 0 0 1 {P(d)}Z"/>')
        else:           # its white stripe: just the scalloped hem, outlined
            h = STROKE / 2
            out.append(f'<path d="M{P((c[0]-h, c[1]-6))}L{P((c[0]-h, c[1]))}A{f(r-h)} {f(r-h)} 0 0 1 '
                       f'{P((d[0]+h, d[1]))}L{P((d[0]+h, d[1]-6))}" fill="none" stroke="#000" stroke-width="{STROKE}"/>')
    return "".join(out)

def rail():
    return f'<rect x="{RAIL_X0}" y="{RAIL_Y}" width="{RAIL_X1-RAIL_X0}" height="{RAIL_H}" rx="{RAIL_H/2}"/>'

def sun():
    # The sun sits behind the rail's right end: cut flat just above the rail, only where the rail runs.
    cx, cy = SUN_C
    cut = RAIL_Y - GAP
    dy = cut - cy
    dx = math.sqrt(SUN_R**2 - dy**2)
    left, right = cx - dx, cx + dx
    if right <= RAIL_X1 + GAP:      # whole bottom over the rail: one flat cut
        return f'<path d="M{P((left, cut))}A{SUN_R} {SUN_R} 0 1 1 {P((right, cut))}Z"/>'
    # Past the rail's end the sun shows in full: cut only up to the rail's end (plus the gap), then down and round.
    xe = RAIL_X1 + GAP
    ye = cy + math.sqrt(SUN_R**2 - (xe - cx) ** 2)
    return (f'<path d="M{P((left, cut))}A{SUN_R} {SUN_R} 0 1 1 {P((xe, ye))}'
            f'L{P((xe, cut))}Z"/>')

open(f"concept-d-{V}.svg", "w").write(svg(sun() + rail() + panels()))
print("built", V)
