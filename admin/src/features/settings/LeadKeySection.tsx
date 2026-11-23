import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import { useOrg } from '../../app/org';
import { ActionDialog, DialogButton, Facts, QueryState, Section } from '../../components';
import { formatDateTime } from '../../lib/format';

/*
  F20: the key the company's landing page sends leads with
  ----------------------------------------------------------------------
  - shown once, when made: only its hash is kept
  - a new key stops the old one at once, so the dialog says so
*/
export function LeadKeySection() {
  const { orgId } = useOrg();
  const info = useQuery({
    queryKey: ['org', orgId, 'lead-key'],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/lead-key', { params: { path: { org_id: orgId } }, signal }),
      ),
  });
  const [made, setMade] = useState('');

  return (
    <Section
      title="Leads from your landing page"
      actions={
        info.data && (
          <DialogButton
            key={info.data.made_at ?? 'none'}
            label={info.data.set ? 'Make a new key' : 'Make a key'}
            variant={info.data.set ? undefined : 'primary'}
            compact
            dialog={(close) => (
              <MakeKeyDialog replacing={info.data.set} onMade={setMade} onClose={close} />
            )}
          />
        )
      }
    >
      <QueryState query={info}>
        {(k) => (
          <>
            {made ? (
              <div className="key-shown">
                <p className="eyebrow">Your new key. Copy it now: it isn&apos;t shown again.</p>
                <code className="key-value">{made}</code>
                <button
                  type="button"
                  className="link-button"
                  onClick={() => void navigator.clipboard?.writeText(made)}
                >
                  Copy key
                </button>
              </div>
            ) : (
              <Facts
                items={[
                  ['Key', k.set ? 'Set' : 'Not made yet'],
                  ['Made', k.made_at && formatDateTime(k.made_at)],
                  [
                    'Last lead',
                    k.set
                      ? k.last_used_at
                        ? formatDateTime(k.last_used_at)
                        : 'None yet'
                      : undefined,
                  ],
                ]}
              />
            )}
            <p className="cell-sub">
              Your landing page&apos;s server sends each form to{' '}
              <code>{`${window.location.origin}/api/v1/leads`}</code> with this key as{' '}
              <code>Authorization: Bearer</code>. Keep it on that server, never in the page itself.
            </p>
          </>
        )}
      </QueryState>
    </Section>
  );
}

function MakeKeyDialog({
  replacing,
  onMade,
  onClose,
}: {
  replacing: boolean;
  onMade: (key: string) => void;
  onClose: () => void;
}) {
  const { orgId } = useOrg();
  return (
    <ActionDialog
      title={replacing ? 'Make a new lead key?' : 'Make a lead key?'}
      body={
        replacing
          ? 'The old key stops at once: leads sent with it are refused until the landing page has the new one.'
          : 'You see it once. Put it on your landing page’s server.'
      }
      confirm="Make key"
      danger={replacing}
      done="Key made. Copy it now."
      onClose={onClose}
      run={async () => {
        const made = await unwrap(
          api.POST('/orgs/{org_id}/admin/lead-key', { params: { path: { org_id: orgId } } }),
        );
        onMade(made.key);
      }}
    />
  );
}
