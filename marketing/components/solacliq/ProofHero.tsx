import { Stage, Phone, Notification, Bar, Roll, States, Spinner, type Act } from '../kit'
import { SqIcon } from './icons'
import { asset } from './asset'
import installImg from './assets/thumb-install.jpg'
import inverterImg from './assets/thumb-inverter.jpg'
import meterImg from './assets/thumb-meter.jpg'
import appIconImg from './assets/solacliq-icon-512.png'
import './proof.css'

// SolaCliq's landing-page hero: a field worker's phone. Story in four beats:
// the task with two of three proof photos (context), a tap on the camera tile
// lands the third photo with its GPS stamp (action), Submit sends it to the
// admin (result), and the admin's approval arrives as a notification while
// the task turns Approved (payoff). It loops through the app's own "Next
// task": the body fades out, the next task fades in, and it is the opening
// frame again, so nothing rewinds in view.
//
// Real strings: Panel installation, the status (In progress, In review,
// Approved), Proof photos, 2 of 3, ±6 m, the button's labels and the
// notification. Everything else is a line. All data is illustrative.

type Status = 'progress' | 'review' | 'approved'
type Button = 'submit' | 'sending' | 'sent' | 'next'
type S = { shot: boolean; status: Status; button: Button; banner: boolean; away: boolean }

const START: S = { shot: false, status: 'progress', button: 'submit', banner: false, away: false }
const REST = { x: 330, y: 470 }

const STATUS: Record<Status, string> = { progress: 'In progress', review: 'In review', approved: 'Approved' }

const script = async (a: Act<S>) => {
  await a.wait(1200)
  a.mark('photo')
  await a.click('camera')
  a.put({ shot: true })
  await a.wait(1500)
  a.mark('submit')
  await a.click('submit')
  a.put({ button: 'sending' })
  await a.wait(700)
  a.put({ button: 'sent', status: 'review' })
  await a.move(REST)
  await a.wait(1500)
  a.mark('approved')
  a.put({ banner: true })
  await a.wait(500)
  a.put({ status: 'approved', button: 'next' })
  await a.wait(2600)
  // iOS puts a banner away by itself after a few seconds
  a.put({ banner: false })
  await a.wait(700)
  a.mark('next')
  await a.click('submit')
  a.put({ away: true })
  await a.wait(260)
  // The next task is behind the fade: it starts where this one did
  await a.snap({ shot: false, status: 'progress', button: 'submit' })
  a.put({ away: false })
  await a.move(REST)
  await a.wait(300)
}

export function ProofHero() {
  return (
    <Stage<S>
      width={440}
      height={540}
      compact={{ below: 440, width: 358, height: 500 }}
      initial={START}
      poster={{ shot: true, status: 'approved', button: 'next', banner: true, away: false }}
      script={script}
      cursor={{ at: REST, style: 'touch' }}
      className="sq-proof"
    >
      {(s, _rect, layout) => (
        <Phone width={layout === 'compact' ? 310 : 344} className="sq-phone">
          <div className="sq-app">
            <div className="sq-nav">
              <span className="sq-back">
                <SqIcon name="back" size={20} />
              </span>
            </div>
            <div className="sq-body" data-away={s.away || undefined}>
              <span className="sq-status" data-status={s.status}>
                <Roll variant="fade">{STATUS[s.status]}</Roll>
              </span>
              <div className="sq-title">Panel installation</div>
              <Bar w={148} h={9} r={4} tone={3} />

              <div className="sq-card">
                <div className="sq-card__head">
                  <span className="sq-card__title">Proof photos</span>
                  <span className="sq-count">
                    <Roll>{s.shot ? '3 of 3' : '2 of 3'}</Roll>
                  </span>
                </div>
                <div className="sq-photos">
                  <img className="sq-photo" src={asset(installImg)} alt="" />
                  <img className="sq-photo" src={asset(inverterImg)} alt="" />
                  <span className="sq-slot" data-target="camera">
                    <span className="sq-camera">
                      <SqIcon name="camera" size={24} />
                    </span>
                    <img className="sq-photo sq-photo--new" src={asset(meterImg)} alt="" data-on={s.shot || undefined} />
                    <span className="sq-gps" data-on={s.shot || undefined}>
                      GPS ±6 m
                    </span>
                  </span>
                </div>
              </div>

              <span className="sq-button" data-target="submit" data-state={s.button}>
                <States
                  value={s.button}
                  states={{
                    submit: <>Submit for review</>,
                    sending: (
                      <>
                        <Spinner size={16} /> Sending
                      </>
                    ),
                    sent: (
                      <>
                        <SqIcon name="check" size={16} /> Sent to admin
                      </>
                    ),
                    next: (
                      <>
                        Next task <SqIcon name="chevronRight" size={16} />
                      </>
                    ),
                  }}
                />
              </span>
              <div className="sq-card sq-checks">
                {[132, 104, 118].map((w, i) => (
                  <span key={i} className="sq-check">
                    <span className="sq-tick">
                      <SqIcon name="check" size={12} />
                    </span>
                    <Bar w={w} h={8} r={4} tone={3} />
                  </span>
                ))}
              </div>
            </div>
          </div>
          <div className="sq-banner" data-on={s.banner || undefined}>
            <Notification
              banner
              icon={<img src={asset(appIconImg)} alt="" className="sq-banner__icon" />}
              title="Panel installation approved"
              body="Your admin approved all 3 proof photos."
            />
          </div>
        </Phone>
      )}
    </Stage>
  )
}
