import { useState } from 'react';
import { Link } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import { useSettings } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  ActionDialog,
  DialogButton,
  Facts,
  PageHeader,
  QueryState,
  Section,
  TextField,
} from '../../components';

import { LeadKeySection } from './LeadKeySection';
import { LogoSection } from './LogoSection';

const UPI_ID = /^[A-Za-z0-9._-]{2,64}@[A-Za-z][A-Za-z0-9]{1,63}$/;

/** The stages (F19), the logo (W6), the UPI id (W4) and the lead key (F20). */
export function SettingsPage() {
  const { orgId, name, to } = useOrg();
  const settings = useSettings(orgId);
  return (
    <>
      <PageHeader title="Settings" meta={name} />
      <QueryState query={settings}>
        {(s) => (
          <div className="settings">
            <section className="card stages-card" aria-label="Install stages">
              <h2 className="eyebrow">The {s.stages.length} install stages</h2>
              <ol className="stage-list">
                {s.stages.map((stage, i) => (
                  <li key={stage}>
                    <span className="stage-number">{i + 1}</span>
                    {stage}
                  </li>
                ))}
              </ol>
              <Link className="sc-btn sc-btn-compact" to={to('settings/stages')}>
                Edit names and templates
              </Link>
            </section>
            <div className="col">
              <LogoSection />
              <Section
                title="Customer payments"
                actions={
                  <DialogButton
                    label={s.upi_id ? 'Change UPI ID' : 'Add UPI ID'}
                    variant={s.upi_id ? undefined : 'primary'}
                    compact
                    dialog={(close) => <UpiDialog current={s.upi_id ?? ''} onClose={close} />}
                  />
                }
              >
                <Facts items={[['UPI ID', s.upi_id ?? 'Not set']]} />
                <p className="cell-sub">
                  Customers see &ldquo;Pay by UPI&rdquo; in the app when this is set. The money goes
                  straight to this ID, never through SolaCliq.
                </p>
              </Section>
              <LeadKeySection />
            </div>
          </div>
        )}
      </QueryState>
    </>
  );
}

function UpiDialog({ current, onClose }: { current: string; onClose: () => void }) {
  const { orgId } = useOrg();
  const [upi, setUpi] = useState(current);
  return (
    <ActionDialog
      title="Where customers pay"
      body="Check it letter by letter: customers' money goes to this ID."
      confirm="Save"
      done="UPI ID saved."
      onClose={onClose}
      validate={() => ({
        upi_id:
          upi.trim() && !UPI_ID.test(upi.trim()) ? 'Enter a UPI id like name@bank.' : undefined,
      })}
      run={() =>
        unwrap(
          api.PUT('/orgs/{org_id}/admin/settings', {
            params: { path: { org_id: orgId } },
            body: { upi_id: upi.trim() || null },
          }),
        )
      }
    >
      {(errors) => (
        <TextField
          label="UPI ID"
          autoFocus
          autoCapitalize="none"
          autoComplete="off"
          spellCheck={false}
          value={upi}
          error={errors.upi_id}
          help="Leave empty to remove it."
          onChange={(e) => setUpi(e.target.value)}
        />
      )}
    </ActionDialog>
  );
}
