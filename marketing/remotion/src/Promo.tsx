import { type ReactNode } from 'react'
import { AbsoluteFill, Img, Sequence, interpolate, staticFile, useCurrentFrame, useVideoConfig } from 'remotion'
import { Bar, C, FONT, Icon, Mark, MarkCliq, Phone, Pill, Wordmark, card, ease, loadFont, useIn, useSpring } from './brand'

/*
  SolaCliq's promo, 31 s at 30 fps, 1920 × 1080
  --------------------------------------------------------------------
  - for solar EPC vendors, on markcliq.com and in posts: what the app is,
    in the app's own look, one idea per scene
  - intro (the mark, the sun rising behind the awning), the promise, then
    four features as they look in the app (proof photos, expenses, the
    homeowner's tracker, the vendor's own logo), and the lockup
  - every name and number is illustrative; the corner caption says so
*/

export const SCENES = {
  intro: [0, 100],
  promise: [100, 90],
  proof: [190, 210],
  expense: [400, 145],
  tracker: [545, 145],
  brand: [690, 130],
  outro: [820, 110],
} as const
export const DURATION = 930

/* The same story in both shapes: 16:9 for the website, 9:16 for Reels and
   WhatsApp Status. Scenes read the frame's shape and lay themselves out. */
function useVertical() {
  const { width, height } = useVideoConfig()
  return height > width
}

export function Promo() {
  loadFont()
  return (
    <AbsoluteFill style={{ background: C.page, fontFamily: FONT, color: C.ink }}>
      <Scene at="intro" last={false}>
        <Intro />
      </Scene>
      <Scene at="promise">
        <Promise />
      </Scene>
      <Scene at="proof">
        <Feature
          title="Proof photos, from the roof"
          body="Workers shoot each step on site. Every photo is GPS-tagged and goes straight to your admin."
          phone={<ProofScreen />}
        />
      </Scene>
      <Scene at="expense">
        <Feature title="Expenses, settled the same day" body="Fuel, tools, travel: logged with the receipt, approved from the office." phone={<ExpenseScreen />} flip />
      </Scene>
      <Scene at="tracker">
        <Feature title="Homeowners see every stage" body="From site survey to handover, and what to pay next, without calling you." phone={<TrackerScreen />} />
      </Scene>
      <Scene at="brand">
        <Feature title="Your logo. Your team's app." body="Upload it once. Every worker, agent and customer sees your brand." phone={<BrandScreen />} flip />
      </Scene>
      <Scene at="outro" fadeOut={false}>
        <Outro />
      </Scene>
    </AbsoluteFill>
  )
}

/* A scene's place on the timeline, fading in and out over 12 frames. */
function Scene({ at, children, last = true, fadeOut = true }: { at: keyof typeof SCENES; children: ReactNode; last?: boolean; fadeOut?: boolean }) {
  const [from, length] = SCENES[at]
  return (
    <Sequence from={from} durationInFrames={length} layout="none">
      <Fade length={length} fadeIn={last} fadeOut={fadeOut}>
        {children}
      </Fade>
    </Sequence>
  )
}

function Fade({ length, fadeIn, fadeOut, children }: { length: number; fadeIn: boolean; fadeOut: boolean; children: ReactNode }) {
  const frame = useCurrentFrame()
  const inO = fadeIn ? interpolate(frame, [0, 12], [0, 1], { extrapolateRight: 'clamp', easing: ease }) : 1
  const outO = fadeOut ? interpolate(frame, [length - 12, length], [1, 0], { extrapolateLeft: 'clamp' }) : 1
  const lift = fadeIn ? interpolate(frame, [0, 18], [14, 0], { extrapolateRight: 'clamp', easing: ease }) : 0
  return <AbsoluteFill style={{ opacity: Math.min(inO, outO), transform: `translateY(${lift}px)` }}>{children}</AbsoluteFill>
}

/* ---- Intro: the mark, the wordmark, by MarkCliq ---- */

function Intro() {
  const v = useVertical()
  const word = useIn(34, 22)
  const by = useIn(50, 20)
  return (
    <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center', background: `radial-gradient(70% 70% at 50% 40%, ${C.cream} 0%, ${C.page} 100%)` }}>
      <div style={{ display: 'grid', justifyItems: 'center', gap: 34 }}>
        <Mark size={v ? 340 : 260} start={2} />
        <div style={{ opacity: word, transform: `translateY(${(1 - word) * 18}px)` }}>
          <Wordmark height={v ? 190 : 150} />
        </div>
        <div style={{ opacity: by, marginTop: -40, fontSize: v ? 38 : 30, color: C.muted, fontWeight: 500 }}>
          by <MarkCliq />
        </div>
      </div>
    </AbsoluteFill>
  )
}

/* ---- The promise ---- */

function Promise() {
  const vertical = useVertical()
  const lines = vertical ? ['Every solar', 'install,', 'in one place'] : ['Every solar install,', 'in one place']
  const sub = useIn(30, 20)
  return (
    <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ display: 'grid', justifyItems: 'center', gap: 6 }}>
        {lines.map((l, i) => (
          <Rise key={l} start={4 + i * 8}>
            <div style={{ fontSize: vertical ? 124 : 104, fontWeight: 600, letterSpacing: '-0.035em', lineHeight: 1.05 }}>{l}</div>
          </Rise>
        ))}
        <div style={{ opacity: sub, marginTop: 30, fontSize: vertical ? 40 : 34, color: C.muted, fontWeight: 400, textAlign: 'center', maxWidth: vertical ? 820 : undefined, lineHeight: 1.35 }}>
          For solar EPC companies, their field teams and their customers
        </div>
      </div>
    </AbsoluteFill>
  )
}

function Rise({ start, children }: { start: number; children: ReactNode }) {
  const t = useIn(start, 20)
  return <div style={{ opacity: t, transform: `translateY(${(1 - t) * 40}px)` }}>{children}</div>
}

/* ---- A feature: words on one side, the phone on the other ---- */

function Feature({ title, body, phone, flip = false }: { title: string; body: string; phone: ReactNode; flip?: boolean }) {
  const vertical = useVertical()
  const t = useIn(2, 22)
  const s = useSpring(4, 20)
  if (vertical) {
    // Words on top, centred; the phone below, larger, running off the bottom
    return (
      <AbsoluteFill style={{ alignItems: 'center', overflow: 'hidden' }}>
        <div style={{ marginTop: 160, width: 920, display: 'grid', gap: 26, justifyItems: 'center', textAlign: 'center', opacity: t, transform: `translateY(${(1 - t) * 24}px)` }}>
          <div style={{ fontSize: 92, fontWeight: 600, letterSpacing: '-0.03em', lineHeight: 1.05, textWrap: 'balance' }}>{title}</div>
          <div style={{ fontSize: 40, lineHeight: 1.35, color: C.muted, maxWidth: 820, textWrap: 'balance' }}>{body}</div>
          <div style={{ fontSize: 24, color: C.faint }}>Illustrative screens, sample data</div>
        </div>
        {/* The phone as designed (460 wide), scaled up whole so its screen fills the frame */}
        <div style={{ marginTop: 70, transform: `translateY(${(1 - s) * 200}px) scale(${780 / 460})`, transformOrigin: 'top center' }}>
          <Phone width={460}>{phone}</Phone>
        </div>
      </AbsoluteFill>
    )
  }
  const text = (
    <div style={{ position: 'relative', width: 720, display: 'grid', gap: 26, opacity: t, transform: `translateX(${(1 - t) * (flip ? 30 : -30)}px)` }}>
      <div style={{ fontSize: 76, fontWeight: 600, letterSpacing: '-0.03em', lineHeight: 1.06, textWrap: 'balance' }}>{title}</div>
      <div style={{ fontSize: 32, lineHeight: 1.4, color: C.muted, maxWidth: 640 }}>{body}</div>
      <div style={{ position: 'absolute', bottom: -330, fontSize: 18, color: C.faint }}>Illustrative screens, sample data</div>
    </div>
  )
  const device = (
    <div style={{ transform: `translateY(${(1 - s) * 140}px)`, alignSelf: 'flex-start', marginTop: 230 }}>
      <Phone width={460}>{phone}</Phone>
    </div>
  )
  return (
    <AbsoluteFill style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 150, overflow: 'hidden' }}>
      {flip ? device : text}
      {flip ? text : device}
    </AbsoluteFill>
  )
}

/* ---- Proof photos: the third lands, Submit, the admin approves ---- */

function ProofScreen() {
  const frame = useCurrentFrame()
  const shot = useIn(48, 16)
  const gps = useIn(62, 12)
  const press = interpolate(frame, [82, 86, 92], [1, 0.97, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
  const sent = frame >= 92
  const banner = useSpring(122, 16)
  const approved = frame >= 132
  return (
    <div style={{ padding: '0 22px', position: 'relative', height: '100%', display: 'flow-root' }}>
      <div
        style={{
          position: 'absolute',
          top: -8 + (1 - banner) * -130,
          left: 12,
          right: 12,
          zIndex: 6,
          display: 'flex',
          gap: 14,
          alignItems: 'center',
          padding: '14px 16px',
          borderRadius: 26,
          background: 'rgba(255,255,255,0.96)',
          boxShadow: '0 10px 30px rgba(46,33,27,0.16)',
          opacity: banner,
        }}
      >
        <Img src={staticFile('solacliq-icon-512.png')} style={{ width: 44, height: 44, borderRadius: 11 }} />
        <div style={{ display: 'grid', gap: 2, flex: 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 17, fontWeight: 600 }}>
            Panel installation approved <span style={{ fontSize: 14, fontWeight: 400, color: C.faint }}>now</span>
          </div>
          <div style={{ fontSize: 16 }}>Your admin approved all 3 proof photos.</div>
        </div>
      </div>
      <div style={{ marginTop: 122 }}>
        <Status approved={approved} review={sent} />
      </div>
      <div style={{ fontSize: 34, fontWeight: 600, letterSpacing: '-0.02em', margin: '14px 0 12px' }}>Panel installation</div>
      <Bar w={170} />
      <div style={{ ...card, marginTop: 24, padding: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
          <span style={{ fontSize: 20, fontWeight: 600 }}>Proof photos</span>
          <span style={{ fontSize: 17, color: C.muted, fontWeight: 500 }}>{shot > 0.5 ? '3 of 3' : '2 of 3'}</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          <Photo src="thumb-install.jpg" />
          <Photo src="thumb-inverter.jpg" />
          <div style={{ position: 'relative', aspectRatio: '1', borderRadius: 16, overflow: 'hidden', background: C.sun, display: 'grid', placeItems: 'center' }}>
            <Icon name="camera" size={30} color={C.ink} />
            <Img
              src={staticFile('thumb-meter.jpg')}
              style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', opacity: shot, transform: `scale(${1.08 - 0.08 * shot})` }}
            />
            <span
              style={{
                position: 'absolute',
                left: 7,
                bottom: 7,
                padding: '4px 9px',
                borderRadius: 11,
                fontSize: 13,
                fontWeight: 600,
                color: '#fff',
                background: 'rgba(42,31,25,0.8)',
                opacity: gps,
                transform: `translateY(${(1 - gps) * 6}px)`,
              }}
            >
              GPS ±6 m
            </span>
          </div>
        </div>
      </div>
      <div
        style={{
          marginTop: 20,
          height: 62,
          borderRadius: 31,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 10,
          fontSize: 20,
          fontWeight: 600,
          transform: `scale(${press})`,
          background: sent && !approved ? '#fff' : C.sun,
          color: sent && !approved ? C.success : C.ink,
          boxShadow: sent && !approved ? '0 1px 2px rgba(46,33,27,0.06)' : '0 8px 20px rgba(201,151,26,0.25)',
        }}
      >
        {approved ? (
          <>
            Next task <Icon name="chevronRight" size={20} />
          </>
        ) : sent ? (
          <>
            <Icon name="check" size={20} /> Sent to admin
          </>
        ) : (
          'Submit for review'
        )}
      </div>
      <Checklist />
      <Touch at={[0.83, 0.437]} frame={46} />
      <Touch at={[0.5, 0.58]} frame={82} />
    </div>
  )
}

function Checklist() {
  return (
    <div style={{ ...card, marginTop: 18, padding: 22, display: 'grid', gap: 18 }}>
      {[170, 130, 150].map((w, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ width: 28, height: 28, borderRadius: '50%', background: C.successTint, color: C.success, display: 'grid', placeItems: 'center' }}>
            <Icon name="check" size={15} />
          </span>
          <Bar w={w} />
        </div>
      ))}
    </div>
  )
}

function Status({ approved, review }: { approved: boolean; review: boolean }) {
  if (approved) return <Pill bg={C.successTint} color={C.success}>Approved</Pill>
  if (review) return <Pill bg={C.tan} color={C.tanText}>In review</Pill>
  return <Pill bg={C.butter} color={C.warning}>In progress</Pill>
}

function Photo({ src }: { src: string }) {
  return <Img src={staticFile(src)} style={{ width: '100%', aspectRatio: '1', objectFit: 'cover', borderRadius: 16, display: 'block' }} />
}

/* A fingertip: a soft ring where the finger taps, nothing between taps. */
function Touch({ at, frame: tap }: { at: [number, number]; frame: number }) {
  const frame = useCurrentFrame()
  const t = interpolate(frame, [tap - 4, tap, tap + 14], [0, 1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
  const grow = interpolate(frame, [tap - 4, tap + 14], [0.7, 1.25], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
  return (
    <span
      style={{
        position: 'absolute',
        left: `${at[0] * 100}%`,
        top: `${at[1] * 100}%`,
        width: 54,
        height: 54,
        marginLeft: -27,
        marginTop: -27,
        borderRadius: '50%',
        background: 'rgba(42,31,25,0.16)',
        border: '2px solid rgba(255,255,255,0.8)',
        opacity: t,
        transform: `scale(${grow})`,
        zIndex: 7,
      }}
    />
  )
}

/* ---- Expenses: ₹1,240 of fuel, approved ---- */

function ExpenseScreen() {
  const frame = useCurrentFrame()
  const amount = Math.round(interpolate(frame, [14, 44], [0, 1240], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease }))
  const approved = useSpring(64, 15)
  return (
    <div style={{ padding: '0 22px', position: 'relative' }}>
      <div style={{ marginTop: 20, fontSize: 17, color: C.muted, fontWeight: 500 }}>Expense</div>
      <div style={{ fontSize: 76, fontWeight: 600, letterSpacing: '-0.04em', margin: '4px 0 16px', fontVariantNumeric: 'tabular-nums' }}>
        ₹{amount.toLocaleString('en-IN')}
      </div>
      <div style={{ opacity: approved, transform: `scale(${0.9 + 0.1 * approved})`, transformOrigin: 'left center', marginBottom: 18 }}>
        <Pill bg={C.successTint} color={C.success} size={17}>
          <Icon name="check" size={18} /> Approved · paid with salary
        </Pill>
      </div>
      <div style={{ ...card, padding: '6px 20px' }}>
        <Row label="For" value="Fuel" />
        <Row label={<Bar w={60} />} value={<Bar w={110} tone={0.13} />} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 0', borderTop: '1px solid rgba(46,33,27,0.08)' }}>
          <span style={{ width: 56, height: 56, borderRadius: 14, background: C.tan, color: C.tanText, display: 'grid', placeItems: 'center' }}>
            <Icon name="receipt" size={28} />
          </span>
          <span style={{ fontSize: 19, fontWeight: 600 }}>Receipt</span>
        </div>
      </div>
      <Filler />
    </div>
  )
}

function Row({ label, value }: { label: ReactNode; value: ReactNode }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', minHeight: 58, fontSize: 19, borderTop: '1px solid rgba(46,33,27,0.08)', marginTop: -1 }}>
      <span style={{ color: C.muted }}>{label}</span>
      <span style={{ fontWeight: 600 }}>{value}</span>
    </div>
  )
}

function Filler() {
  return (
    <div style={{ ...card, marginTop: 16, padding: 20, display: 'grid', gap: 18 }}>
      {[150, 120, 165].map((w, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ width: 48, height: 48, borderRadius: '50%', background: C.tan }} />
          <span style={{ display: 'grid', gap: 9 }}>
            <Bar w={w} />
            <Bar w={w * 0.55} h={8} tone={0.06} />
          </span>
        </div>
      ))}
    </div>
  )
}

/* ---- The homeowner's tracker: stages fill to 4 of 7 ---- */

const STAGES = ['Site survey', 'Design', 'Approval', 'Installation']

function TrackerScreen() {
  const frame = useCurrentFrame()
  const filled = interpolate(frame, [16, 70], [0, 4], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
  const pay = useSpring(84, 16)
  return (
    <div style={{ padding: '0 22px', position: 'relative' }}>
      <div style={{ marginTop: 20, fontSize: 17, color: C.muted, fontWeight: 500 }}>Your solar</div>
      <div style={{ ...card, marginTop: 14, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <span style={{ fontSize: 28, fontWeight: 600, letterSpacing: '-0.02em' }}>Stage {Math.max(1, Math.ceil(filled))} of 7</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 5 }}>
          {Array.from({ length: 7 }, (_, i) => (
            <span key={i} style={{ height: 8, borderRadius: 4, background: C.track, overflow: 'hidden' }}>
              <span style={{ display: 'block', height: '100%', width: `${Math.max(0, Math.min(1, filled - i)) * 100}%`, background: C.sun }} />
            </span>
          ))}
        </div>
      </div>
      <div style={{ ...card, marginTop: 16, padding: 22, display: 'grid', gap: 18 }}>
        {STAGES.map((name, i) => {
          const done = filled >= i + 1 && i < 3
          const now = i === 3 && filled > 3.2
          return (
            <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 14, fontSize: 20, fontWeight: now ? 600 : 500, color: done || now ? C.ink : C.faint }}>
              <span
                style={{
                  width: 28,
                  height: 28,
                  borderRadius: '50%',
                  display: 'grid',
                  placeItems: 'center',
                  boxSizing: 'border-box',
                  background: done ? C.successTint : '#fff',
                  color: C.success,
                  border: now ? `8px solid ${C.sun}` : done ? 'none' : `2px solid ${C.track}`,
                }}
              >
                {done && <Icon name="check" size={15} />}
              </span>
              {name}
            </div>
          )
        })}
      </div>
      <div
        style={{
          ...card,
          marginTop: 16,
          padding: 22,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          opacity: pay,
          transform: `translateY(${(1 - pay) * 30}px)`,
        }}
      >
        <span style={{ display: 'grid', gap: 4 }}>
          <span style={{ fontSize: 16, color: C.muted, fontWeight: 500 }}>Next payment</span>
          <span style={{ fontSize: 32, fontWeight: 600, letterSpacing: '-0.02em' }}>₹40,000</span>
        </span>
        <Pill bg={C.sun} color={C.ink} size={17}>
          Pay with UPI
        </Pill>
      </div>
      <Filler />
    </div>
  )
}

/* ---- The vendor's own brand: their logo arrives in the header ---- */

function BrandScreen() {
  const logo = useSpring(30, 16)
  return (
    <div style={{ padding: '0 22px', position: 'relative' }}>
      <div style={{ display: 'grid', gridTemplateColumns: '52px 1fr 52px', alignItems: 'center', marginTop: 16 }}>
        <span style={{ width: 52, height: 52, borderRadius: '50%', background: C.avatar, display: 'grid', placeItems: 'center', fontWeight: 600, fontSize: 18 }}>RE</span>
        <span style={{ display: 'grid', justifyItems: 'center', gap: 3 }}>
          <span style={{ height: 34, display: 'grid', placeItems: 'center' }}>
            <span style={{ opacity: logo, transform: `scale(${0.8 + 0.2 * logo})`, display: 'inline-flex', alignItems: 'center', gap: 8, fontSize: 25, fontWeight: 700, color: '#1d4f91', letterSpacing: '-0.01em' }}>
              Arka
              <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#e8a317' }} />
              Solar
            </span>
          </span>
          <span style={{ fontSize: 21, fontWeight: 600 }}>Ravi's day</span>
          <span style={{ fontSize: 16, color: C.muted }}>Arka Solar · EPC Installer</span>
        </span>
        <span style={{ width: 52, height: 52, borderRadius: '50%', background: '#fff', display: 'grid', placeItems: 'center' }}>
          <Icon name="bell" size={22} />
        </span>
      </div>
      <div style={{ ...card, marginTop: 22, padding: 12, display: 'flex', justifyContent: 'space-between' }}>
        {[16, 17, 18, 19, 20].map((d, i) => (
          <span
            key={d}
            style={{ width: 62, padding: '12px 0', borderRadius: 18, display: 'grid', justifyItems: 'center', gap: 10, background: i === 2 ? C.brown : 'transparent', color: i === 2 ? '#fff' : C.ink }}
          >
            <Bar w={26} h={7} tone={i === 2 ? 0.0 : 0.1} />
            <span style={{ fontSize: 22, fontWeight: 600 }}>{d}</span>
          </span>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 14 }}>
        <span style={{ height: 160, borderRadius: 26, background: C.brown, color: '#fff', padding: 20, boxSizing: 'border-box', display: 'grid', alignContent: 'space-between' }}>
          <span style={{ fontSize: 17, opacity: 0.8 }}>To submit</span>
          <span style={{ fontSize: 54, fontWeight: 600, letterSpacing: '-0.04em' }}>6</span>
        </span>
        <span style={{ ...card, height: 160, padding: 20, boxSizing: 'border-box', display: 'grid', alignContent: 'space-between' }}>
          <span style={{ fontSize: 17, color: C.muted }}>Expenses</span>
          <span style={{ fontSize: 54, fontWeight: 600, letterSpacing: '-0.04em' }}>49</span>
        </span>
      </div>
      <Filler />
    </div>
  )
}

/* ---- Outro: the lockup and where to find it ---- */

function Outro() {
  const v = useVertical()
  const t = useIn(6, 22)
  const line = useIn(26, 20)
  return (
    <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center', background: `radial-gradient(70% 70% at 50% 45%, ${C.cream} 0%, ${C.page} 100%)` }}>
      <div style={{ display: 'flex', flexDirection: v ? 'column' : 'row', alignItems: 'center', gap: v ? 28 : 44, opacity: t, transform: `scale(${0.96 + 0.04 * t})` }}>
        <Mark size={v ? 300 : 190} still />
        <Wordmark height={v ? 190 : 170} />
      </div>
      <div style={{ opacity: line, marginTop: v ? 10 : 40, fontSize: v ? 42 : 36, color: C.muted, display: 'grid', justifyItems: 'center', gap: 14 }}>
        <span>The app for solar EPC companies</span>
        <span style={{ fontSize: v ? 36 : 30, color: C.ink, fontWeight: 600 }}>
          by <MarkCliq /> · markcliq.com
        </span>
      </div>
    </AbsoluteFill>
  )
}
