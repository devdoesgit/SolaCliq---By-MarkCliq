import { type CSSProperties, type ReactNode } from 'react'
import { Img, continueRender, delayRender, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig, Easing } from 'remotion'

// SolaCliq's look (design/tokens.json, the iOS v2 design).
export const C = {
  ink: '#2a1f19',
  brown: '#2e211b',
  muted: '#6d635a',
  faint: '#8d837b',
  sun: '#f6c445',
  sunDeep: '#c9971a',
  cream: '#fbf8f4',
  sandTop: '#fcf7ee',
  sandBottom: '#f4e8d3',
  tan: '#f1e7db',
  tanText: '#835f3c',
  avatar: '#e6d3bc',
  butter: '#fdf1cc',
  warning: '#875d09',
  success: '#2e7445',
  successTint: '#e1f1e4',
  track: '#e4dad0',
  rust: '#b2402c',
  page: '#f5f5f7',
}

export const FONT = "'SQ Inter', system-ui, sans-serif"

// Inter, the app's own font (OFL), loaded before the first frame renders.
let fontLoaded: Promise<void> | null = null
export function loadFont() {
  if (fontLoaded) return
  const handle = delayRender('Inter')
  const face = new FontFace('SQ Inter', `url(${staticFile('Inter-Variable.ttf')})`, { weight: '100 900' })
  fontLoaded = face.load().then((f) => {
    ;(document.fonts as unknown as { add(face: FontFace): void }).add(f)
    continueRender(handle)
  })
}

// Ease helpers on the video's clock.
export const ease = Easing.bezier(0.25, 0.8, 0.25, 1)
export const travel = Easing.bezier(0.45, 0, 0.1, 1)

export function useIn(start: number, duration = 18) {
  const frame = useCurrentFrame()
  return interpolate(frame, [start, start + duration], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease })
}

export function useSpring(start: number, damping = 18) {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()
  return spring({ frame: frame - start, fps, config: { damping, mass: 0.8 } })
}

/* The mark: the sun rising behind MarkCliq's awning (design/logo/kit). The
   sun rises from behind the rail; the awning's panels drop in one by one. */
const PANELS = [
  { d: 'M50 138L81.2 138L74 172A18 18 0 0 1 38 172Z', fill: C.rust },
  { d: 'M81.2 138L112.4 138L110 172A18 18 0 0 1 74 172Z', fill: '#ffffff', line: 'M112.4 138L110 172A18 18 0 0 1 74 172L81.2 138' },
  { d: 'M112.4 138L143.6 138L146 172A18 18 0 0 1 110 172Z', fill: C.rust },
  { d: 'M143.6 138L174.8 138L182 172A18 18 0 0 1 146 172Z', fill: '#ffffff', line: 'M174.8 138L182 172A18 18 0 0 1 146 172L143.6 138' },
  { d: 'M174.8 138L206 138L218 172A18 18 0 0 1 182 172Z', fill: C.rust },
]

export function Mark({ size, start = 0, still = false }: { size: number; start?: number; still?: boolean }) {
  const frame = useCurrentFrame()
  const rise = still ? 1 : interpolate(frame, [start + 8, start + 38], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease })
  const rail = still ? 1 : interpolate(frame, [start, start + 14], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease })
  return (
    <svg width={size} height={(size * 148) / 180} viewBox="38 42 180 148" style={{ display: 'block', overflow: 'visible' }}>
      <defs>
        <clipPath id="sq-above-rail">
          <rect x="0" y="0" width="256" height="126" />
        </clipPath>
      </defs>
      <g clipPath="url(#sq-above-rail)">
        <path d="M69.66 116A60 60 0 1 1 186.34 116Z" fill={C.sun} transform={`translate(0 ${(1 - rise) * 80})`} />
      </g>
      <path
        d="M50 126L206 126A6 6 0 0 1 206 138L50 138A6 6 0 0 1 50 126Z"
        fill={C.ink}
        style={{ transformOrigin: '128px 132px', transform: `scaleX(${rail})` }}
      />
      {PANELS.map((p, i) => {
        const t = still ? 1 : interpolate(frame, [start + 12 + i * 3, start + 30 + i * 3], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease })
        return (
          <g key={i} style={{ opacity: t, transform: `translateY(${(1 - t) * -10}px)` }}>
            <path d={p.d} fill={p.fill} />
            {p.line && <path d={p.line} fill="none" stroke={C.rust} strokeWidth={6} strokeLinejoin="round" />}
          </g>
        )
      })}
    </svg>
  )
}

/* The wordmark, exactly as the logo kit draws it ("Sola" upright, "Cliq"
   oblique, the i's dot a sun): design/logo/kit/svg/solacliq-wordmark.svg. */
export function Wordmark({ height, style }: { height: number; style?: CSSProperties }) {
  return <Img src={staticFile('solacliq-wordmark.svg')} style={{ height, width: 'auto', display: 'block', ...style }} />
}

/* MarkCliq, its "Cliq" italic as its wordmark sets it. */
export function MarkCliq() {
  return (
    <>
      Mark<span style={{ fontStyle: 'italic' }}>Cliq</span>
    </>
  )
}

/* An iPhone-shaped frame: black bezel, the island, a status bar. */
export function Phone({ width = 400, children, style }: { width?: number; children: ReactNode; style?: CSSProperties }) {
  const k = width / 400
  const h = 820 * k
  return (
    <div
      style={{
        position: 'relative',
        width,
        height: h,
        borderRadius: 64 * k,
        background: '#111',
        padding: 12 * k,
        boxSizing: 'border-box',
        boxShadow: '0 40px 80px -20px rgba(46, 33, 27, 0.35), 0 12px 24px -8px rgba(46, 33, 27, 0.18)',
        ...style,
      }}
    >
      <div style={{ position: 'relative', width: '100%', height: '100%', borderRadius: 52 * k, overflow: 'hidden', background: `linear-gradient(180deg, ${C.sandTop} 0%, ${C.sandBottom} 100%)` }}>
        <div style={{ position: 'absolute', top: 12 * k, left: '50%', width: 118 * k, height: 34 * k, marginLeft: -59 * k, borderRadius: 17 * k, background: '#000', zIndex: 5 }} />
        <div
          style={{
            position: 'absolute',
            top: 17 * k,
            left: 34 * k,
            right: 30 * k,
            display: 'flex',
            justifyContent: 'space-between',
            fontFamily: FONT,
            fontSize: 16 * k,
            fontWeight: 600,
            color: C.ink,
            zIndex: 4,
          }}
        >
          <span>9:41</span>
          <span style={{ display: 'flex', gap: 5 * k, alignItems: 'center' }}>
            <span style={{ width: 17 * k, height: 11 * k, borderRadius: 2 * k, background: `linear-gradient(90deg, ${C.ink} 0 22%, transparent 22% 26%, ${C.ink} 26% 48%, transparent 48% 52%, ${C.ink} 52% 74%, transparent 74% 78%, ${C.ink} 78%)`, clipPath: 'polygon(0 100%, 100% 0, 100% 100%)' }} />
            <span style={{ width: 25 * k, height: 12 * k, borderRadius: 3.5 * k, background: C.ink }} />
          </span>
        </div>
        <div style={{ position: 'absolute', inset: 0, paddingTop: 64 * k, fontFamily: FONT, color: C.ink }}>{children}</div>
      </div>
    </div>
  )
}

/* SolaCliq's own line icons (mobile/packages/sola_ui/lib/src/icons). */
const ICONS = {
  back: ['M15 5l-7 7 7 7', 1.7],
  check: ['M5 12.5l4.5 4.5L19 7.5', 2.2],
  camera: ['M4 8h3l2-3h6l2 3h3v11H4z M12 9.5a3.5 3.5 0 1 0 0 7a3.5 3.5 0 1 0 0-7', 2],
  chevronRight: ['M9 6l6 6-6 6', 2],
  receipt: ['M6 3h12v18l-3-2-3 2-3-2-3 2z M9 8h6M9 12h6', 1.7],
  bell: ['M6 16V11a6 6 0 0 1 12 0v5l1.5 1.5H4.5z M10 20.5h4', 1.7],
} as const

export function Icon({ name, size = 16, color = 'currentColor' }: { name: keyof typeof ICONS; size?: number; color?: string }) {
  const [d, w] = ICONS[name]
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" style={{ display: 'block', flex: 'none' }}>
      <path d={d} />
    </svg>
  )
}

export const card: CSSProperties = { background: '#fff', borderRadius: 24, boxShadow: '0 1px 2px rgba(46,33,27,0.05)' }

export function Bar({ w, h = 9, tone = 0.09 }: { w: number; h?: number; tone?: number }) {
  return <span style={{ display: 'block', width: w, height: h, borderRadius: h / 2, background: `rgba(46,33,27,${tone})` }} />
}

export function Pill({ children, bg, color, size = 15 }: { children: ReactNode; bg: string; color: string; size?: number }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, height: size * 2, padding: `0 ${size * 0.8}px`, borderRadius: size, background: bg, color, fontSize: size, fontWeight: 600, whiteSpace: 'nowrap' }}>
      {children}
    </span>
  )
}
