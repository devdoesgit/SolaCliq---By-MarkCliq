import { Stage, Phone, Bar } from '../kit'
import { SqIcon } from './icons'
import './look.css'
import './expense.css'

// Feature card: a worker's expense, approved. The phone shows the expense as
// the app does (amount, what it was for, its receipt); beside it the admin's
// decision as it arrives. Real strings: Expense, ₹1,240, Fuel, Receipt,
// Approved, Paid with salary. Illustrative data.

export function ExpenseCard() {
  return (
    <Stage width={400} height={400} initial={{}} className="sq-tile sq-expense">
      {() => (
        <>
          <Phone width={300} className="sq-phone">
            <div className="sq-app">
              <div className="sq-screen">
                <div className="sq-label">Expense</div>
                <div className="sq-amount">
                  <span className="sq-amount__sign">₹</span>1,240
                </div>
                <div className="sq-white sq-rows">
                  <span className="sq-row">
                    <span className="sq-row__label">For</span>
                    <span className="sq-row__value">Fuel</span>
                  </span>
                  <span className="sq-row">
                    <span className="sq-row__label">
                      <Bar w={44} h={8} r={4} tone={2} />
                    </span>
                    <Bar w={92} h={8} r={4} tone={3} />
                  </span>
                  <span className="sq-row sq-row--receipt">
                    <span className="sq-receipt">
                      <SqIcon name="receipt" size={22} />
                    </span>
                    <span className="sq-row__value">Receipt</span>
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
          <div className="sq-satellite sq-decision">
            <span className="sq-pill sq-pill--ok">
              <SqIcon name="check" size={14} />
              Approved
            </span>
            <span className="sq-decision__line">Paid with salary</span>
          </div>
        </>
      )}
    </Stage>
  )
}
