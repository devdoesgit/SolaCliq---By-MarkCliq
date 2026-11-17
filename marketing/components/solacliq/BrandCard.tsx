import { Stage, Phone, Bar } from '../kit'
import { SqIcon } from './icons'
import './look.css'
import './brand.css'

// Feature card: the vendor's own brand inside the app. The worker's home
// carries the company's logo above "Ravi's day"; beside it, the setting the
// company's admin used to upload it. "Arka Solar" is an illustrative vendor
// and its logo a plain wordmark (no invented mark). Real strings: the
// wordmark, Ravi's day, Arka Solar · EPC Installer, Company logo, Uploaded.

const DAYS = [16, 17, 18, 19, 20]

export function BrandCard() {
  return (
    <Stage width={400} height={400} initial={{}} className="sq-tile sq-brand">
      {() => (
        <>
          <Phone width={300} className="sq-phone">
            <div className="sq-app">
              <div className="sq-screen">
                <div className="sq-header">
                  <span className="sq-avatar">RE</span>
                  <span className="sq-header__middle">
                    <span className="sq-vendor">
                      <span>Arka</span>
                      <span className="sq-vendor__sun" />
                      <span>Solar</span>
                    </span>
                    <span className="sq-header__title">Ravi's day</span>
                    <span className="sq-header__line">Arka Solar · EPC Installer</span>
                  </span>
                  <span className="sq-bell">
                    <SqIcon name="bell" size={18} />
                  </span>
                </div>
                <div className="sq-white sq-week">
                  {DAYS.map((d, i) => (
                    <span key={d} className="sq-day" data-on={i === 2 || undefined}>
                      <Bar w={18} h={6} r={3} tone={i === 2 ? 1 : 2} />
                      <span className="sq-day__n">{d}</span>
                    </span>
                  ))}
                </div>
                <div className="sq-tiles">
                  <span className="sq-tile-dark">
                    <Bar w={52} h={7} r={3} tone={1} />
                    <span className="sq-tile__n">6</span>
                  </span>
                  <span className="sq-white sq-tile-light">
                    <Bar w={58} h={7} r={3} tone={2} />
                    <span className="sq-tile__n">49</span>
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
          <div className="sq-satellite sq-setting">
            <span className="sq-setting__logo">
              <span>Arka</span>
                      <span className="sq-vendor__sun" />
                      <span>Solar</span>
            </span>
            <span className="sq-setting__text">
              <span className="sq-setting__title">Company logo</span>
              <span className="sq-setting__ok">
                <SqIcon name="check" size={12} /> Uploaded
              </span>
            </span>
          </div>
        </>
      )}
    </Stage>
  )
}
