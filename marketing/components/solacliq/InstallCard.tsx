import { Stage, Phone, Bar } from '../kit'
import { SqIcon } from './icons'
import './look.css'
import './install.css'

// Feature card: what a homeowner sees. Their install at Stage 4 of 7, the
// stages done ticked off, and the next payment beside the phone with the
// way to pay. Real strings: Your solar, Stage 4 of 7, Installation, Next
// payment, ₹40,000, Pay with UPI. Illustrative data.

const DONE = [86, 64, 78]

export function InstallCard() {
  return (
    <Stage width={400} height={400} initial={{}} className="sq-tile sq-install">
      {() => (
        <>
          <Phone width={300} className="sq-phone">
            <div className="sq-app">
              <div className="sq-screen">
                <div className="sq-label">Your solar</div>
                <div className="sq-white sq-track">
                  <div className="sq-track__head">
                    <span className="sq-track__title">Stage 4 of 7</span>
                    <span className="sq-pill sq-pill--sun">Installation</span>
                  </div>
                  <div className="sq-segments">
                    {Array.from({ length: 7 }, (_, i) => (
                      <span key={i} className="sq-segment" data-on={i < 4 || undefined} />
                    ))}
                  </div>
                </div>
                <div className="sq-white sq-stages">
                  {DONE.map((w, i) => (
                    <span key={i} className="sq-stage">
                      <span className="sq-tick">
                        <SqIcon name="check" size={12} />
                      </span>
                      <Bar w={w} h={8} r={4} tone={3} />
                    </span>
                  ))}
                  <span className="sq-stage">
                    <span className="sq-now" />
                    <span className="sq-stage__name">Installation</span>
                  </span>
                  <span className="sq-stage">
                    <span className="sq-later" />
                    <Bar w={70} h={8} r={4} tone={2} />
                  </span>
                </div>
                <div className="sq-white sq-filler">
                  {[[34, 120], [34, 96], [34, 132]].map(([a, b], i) => (
                    <span key={i} className="sq-filler__row">
                      <span className="sq-filler__lead" />
                      <span className="sq-filler__lines">
                        <Bar w={b} h={8} r={4} tone={3} />
                        <Bar w={a + 30} h={7} r={3} tone={2} />
                      </span>
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </Phone>
          <div className="sq-satellite sq-pay">
            <span className="sq-label">Next payment</span>
            <span className="sq-pay__amount">₹40,000</span>
            <span className="sq-pill sq-pill--sun">Pay with UPI</span>
          </div>
        </>
      )}
    </Stage>
  )
}
