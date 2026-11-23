import { useQueries, useQuery } from '@tanstack/react-query';
import { Link, Navigate, useLocation, useParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Customer, TaskSummary } from '../../api/types';
import { FILE_LINKS_MS, usePages, useSettings } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Amount,
  Button,
  DialogButton,
  Facts,
  FileView,
  Icon,
  MapLink,
  Notice,
  PageHeader,
  QueryState,
  Section,
  StageBar,
  StatusPill,
} from '../../components';
import { formatDateTime, formatDay, formatShortDate, formatWhen } from '../../lib/format';
import { ADVANCE, CONNECTION, DOCUMENT, KYC, PAYMENT, ROOF, SIDE, TASK } from '../../lib/labels';
import { CommissionPanel } from '../money/CommissionActions';
import { PaymentActions, PaymentWhen } from '../money/PaymentActions';
import {
  HandoverDialog,
  PriceDialog,
  RejectDialog,
  ReturnDocumentDialog,
  StageDialog,
  VerifyDialog,
} from './CustomerDialogs';

/*
  W2: one person, in the design's two shapes
  ----------------------------------------------------------------------
  - before verifying: a new customer, to check and decide (Customers)
  - after: their project, the install and its money (Projects)
  - either address opens the right one
*/
export function CustomerPage() {
  const { orgId, to } = useOrg();
  const { customerId = '' } = useParams();
  const { pathname } = useLocation();
  const customer = useQuery({
    queryKey: ['org', orgId, 'customer', customerId],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/customers/{customer_id}', {
          params: { path: { org_id: orgId, customer_id: customerId } },
          signal,
        }),
      ),
    // Its file links expire.
    refetchInterval: FILE_LINKS_MS,
  });

  return (
    <QueryState query={customer}>
      {(c) => {
        const part = c.kyc_status === 'approved' ? 'projects' : 'customers';
        if (!pathname.startsWith(to(`${part}/`))) {
          return <Navigate to={to(`${part}/${c.id}`)} replace />;
        }
        return part === 'projects' ? <Project customer={c} /> : <NewCustomer customer={c} />;
      }}
    </QueryState>
  );
}

function NewCustomer({ customer: c }: { customer: Customer }) {
  const { to } = useOrg();
  const deciding = c.kyc_status === 'in_review' || c.kyc_status === 'needs_fix';
  return (
    <>
      <PageHeader
        title={deciding ? `${c.name} · new customer` : c.name}
        meta={[
          'Customers',
          deciding ? 'New requests' : KYC[c.kyc_status].label,
          c.agent_name && `added by ${c.agent_name}`,
        ]
          .filter(Boolean)
          .join(' / ')}
        back={{ to: to('customers'), label: 'Back' }}
      />
      <div className="split">
        <div className="col">
          {c.kyc_status === 'needs_fix' && (
            <Notice
              tone="warning"
              title="Waiting for the agent to send a document again"
              body="You can verify once every document sent back has been replaced."
            />
          )}
          {c.kyc_status === 'rejected' && (
            <Notice tone="danger" title="Not taken up" body={c.rejected_note} />
          )}
          <Details customer={c} />
          <Documents customer={c} />
          {deciding && (
            <Section title="Documents decision" aside={<StatusPill {...KYC[c.kyc_status]} />}>
              <div className="actions">
                <DialogButton
                  key="verify"
                  label="Verify"
                  icon="check"
                  variant="primary"
                  disabled={c.kyc_status === 'needs_fix'}
                  dialog={(close) => <VerifyDialog customer={c} onClose={close} />}
                />
                <DialogButton
                  key="reject"
                  label="Don't take up"
                  variant="danger"
                  dialog={(close) => <RejectDialog customer={c} onClose={close} />}
                />
              </div>
              <p className="cell-sub">
                Verifying sets the price and starts the install. To return one document with a note,
                use Send back under it.
              </p>
            </Section>
          )}
        </div>
        <div className="col col-side">
          {c.commission && c.kyc_status !== 'rejected' ? (
            <CommissionPanel commission={c.commission} />
          ) : (
            <Section title="Commission">
              <p className="cell-sub">
                {c.agent_name ? `None for ${c.agent_name}. ` : ''}
                {deciding ? 'Only the documents need your decision.' : 'Nothing to pay.'}
              </p>
            </Section>
          )}
        </div>
      </div>
    </>
  );
}

function Project({ customer: c }: { customer: Customer }) {
  const { orgId, to } = useOrg();
  const tasks = usePages(orgId, ['tasks', 'of', c.id], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/tasks', {
        params: { path: { org_id: orgId }, query: { customer_id: c.id, cursor } },
        signal,
      }),
    ),
  );
  const listed = tasks.data?.pages.flatMap((page) => page.items);
  return (
    <>
      <PageHeader
        title={c.name}
        meta={['Projects', c.reference, c.system_kw && `${c.system_kw} kW`, c.place]
          .filter(Boolean)
          .join(' / ')}
        back={{ to: to('projects'), label: 'Back to projects' }}
      />
      <div className="split">
        <div className="col">
          <Install customer={c} />
          <Section
            title="Tasks by stage"
            actions={
              !c.handed_over_on && (
                <Link
                  className="sc-btn sc-btn-secondary sc-btn-compact"
                  to={`${to('tasks/new')}?customer=${c.id}`}
                >
                  <Icon name="plus" size={16} />
                  <span>New task</span>
                </Link>
              )
            }
          >
            <QueryState query={tasks}>
              {() =>
                !listed?.length ? (
                  <p className="empty">No tasks yet.</p>
                ) : (
                  <>
                    <ul className="rows">
                      {listed.map((task) => (
                        <li key={task.id}>
                          <TaskRow task={task} />
                        </li>
                      ))}
                    </ul>
                    {tasks.hasNextPage && (
                      <div className="more">
                        <Button
                          compact
                          disabled={tasks.isFetchingNextPage}
                          onClick={() => void tasks.fetchNextPage()}
                        >
                          Show more
                        </Button>
                      </div>
                    )}
                  </>
                )
              }
            </QueryState>
          </Section>
          <Documents customer={c} />
          <Details customer={c} />
        </div>
        <div className="col col-side">
          <Money customer={c} />
          {c.commission && <CommissionPanel commission={c.commission} />}
          <InstallPhotos tasks={listed} />
        </div>
      </div>
    </>
  );
}

function TaskRow({ task: t }: { task: TaskSummary }) {
  const { to } = useOrg();
  const state =
    t.status === 'approved'
      ? `Approved ${formatShortDate(t.status_at)}`
      : t.status === 'assigned'
        ? `Assigned · ${formatWhen(t.due_at)}`
        : TASK[t.status].label;
  return (
    <Link className="row" to={to(`tasks/${t.id}`)}>
      <span className="row-icon row-stage">S{t.stage.index}</span>
      <span className="cell-main row-main">
        <span className="row-title">{t.title}</span>
        <span className="cell-sub">{t.assignee_name}</span>
      </span>
      <span className="cell-sub">{state}</span>
      <span className="row-chevron">
        <Icon name="chevron" />
      </span>
    </Link>
  );
}

// The design's photo wall: the last few approved tasks' proof.
const PHOTO_TASKS = 4;
const PHOTOS_SHOWN = 6;

function InstallPhotos({ tasks }: { tasks?: TaskSummary[] }) {
  const { orgId } = useOrg();
  const approved = (tasks ?? []).filter((t) => t.status === 'approved').slice(0, PHOTO_TASKS);
  const details = useQueries({
    queries: approved.map((t) => ({
      queryKey: ['org', orgId, 'task', t.id],
      refetchInterval: FILE_LINKS_MS,
      queryFn: ({ signal }: { signal: AbortSignal }) =>
        unwrap(
          api.GET('/orgs/{org_id}/admin/tasks/{task_id}', {
            params: { path: { org_id: orgId, task_id: t.id } },
            signal,
          }),
        ),
    })),
  });
  const photos = details
    .flatMap(({ data }) =>
      (data?.photos ?? []).flatMap((slot) =>
        slot.photo ? [{ key: `${data?.id}-${slot.id}`, label: slot.label, photo: slot.photo }] : [],
      ),
    )
    .slice(0, PHOTOS_SHOWN);
  return (
    <Section title="Installation photos">
      {photos.length === 0 ? (
        <p className="cell-sub">Photos appear here once work is approved.</p>
      ) : (
        <ul className="wall">
          {photos.map(({ key, label, photo }) => (
            <li key={key}>
              <FileView file={photo} name={label} />
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}

function Documents({ customer: c }: { customer: Customer }) {
  const canReturn = c.kyc_status === 'in_review' || c.kyc_status === 'needs_fix';
  const good = c.documents.filter((d) => d.status !== 'needs_fix').length;
  return (
    <Section
      title="Documents"
      aside={
        c.documents.length > 0 && (
          <span className={good === c.documents.length ? 'good' : undefined}>
            {good} of {c.documents.length}
          </span>
        )
      }
    >
      {c.documents.length === 0 ? (
        <p className="empty">
          {c.handed_over_on
            ? 'No documents here. KYC is deleted a year after handover, as the Privacy Policy says.'
            : 'No documents were sent.'}
        </p>
      ) : (
        <ul className="tiles tiles-docs">
          {c.documents.map((d) => (
            <li key={d.kind} className="tile">
              <ul className="doc-files">
                {d.files.map(({ file, side }, i) => {
                  const part = side ? SIDE[side] : d.files.length > 1 ? `File ${i + 1}` : '';
                  return (
                    // By position: a fresh link is the same file.
                    <li key={i}>
                      <FileView file={file} name={part ? `${d.title}, ${part}` : d.title} />
                      {part && <span className="cell-sub">{part}</span>}
                    </li>
                  );
                })}
              </ul>
              <div className="tile-text">
                <span className="tile-line">
                  <span className="tile-title">{d.title}</span>
                  {d.status === 'verified' ? (
                    <span className="good" role="img" aria-label="Verified">
                      <Icon name="check" size={15} />
                    </span>
                  ) : (
                    <StatusPill {...DOCUMENT[d.status]} />
                  )}
                </span>
                {d.note && <p className="cell-sub">{d.note}</p>}
              </div>
              {canReturn && d.status === 'in_review' && (
                <DialogButton
                  label="Send back"
                  icon="back"
                  variant="ghost"
                  compact
                  dialog={(close) => (
                    <ReturnDocumentDialog customer={c} document={d} onClose={close} />
                  )}
                />
              )}
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}

function Details({ customer: c }: { customer: Customer }) {
  return (
    <Section title="Customer">
      <Facts
        items={[
          ['Name', c.name],
          ['Mobile', c.phone && <a href={`tel:+91${c.phone}`}>{c.phone}</a>],
          ['Email', c.email],
          [
            'System',
            [c.system_kw && `${c.system_kw} kW`, c.roof && ROOF[c.roof]]
              .filter(Boolean)
              .join(' · '),
          ],
          ['DISCOM', [c.discom, c.consumer_number].filter(Boolean).join(' · ')],
          [
            'Subsidy',
            c.subsidy_requested === undefined
              ? undefined
              : c.subsidy_requested
                ? 'PM Surya Ghar'
                : 'Not asked for',
          ],
          ['Address', [c.address, c.city, c.pin_code].filter(Boolean).join(', ')],
          ['Site', c.lat === undefined ? undefined : <MapLink lat={c.lat} lng={c.lng} />],
        ]}
      />
      <details className="more-details">
        <summary>All details</summary>
        <Facts
          items={[
            ['Reference', c.reference],
            ['State', c.state],
            ['Sanctioned load', c.sanctioned_load_kw ? `${c.sanctioned_load_kw} kW` : undefined],
            ['Connection', c.connection_type && CONNECTION[c.connection_type]],
            ['Agent', c.agent_name],
            ['Registered', formatDateTime(c.created_at)],
            ['Customer agreed', c.consent_at && formatDateTime(c.consent_at)],
          ]}
        />
      </details>
    </Section>
  );
}

function Install({ customer: c }: { customer: Customer }) {
  const { orgId } = useOrg();
  const settings = useSettings(orgId);
  const { stage, price } = c;
  if (!stage) return null;
  const handedOver = c.handed_over_on !== undefined;

  return (
    <Section
      title={
        handedOver ? 'Install finished' : `Stage ${stage.index} of ${stage.count} · ${stage.name}`
      }
      aside={
        handedOver && (
          <StatusPill tone="success" label={`Handed over ${formatDay(c.handed_over_on!)}`} />
        )
      }
      actions={
        !handedOver && (
          <>
            <DialogButton
              key="move"
              label="Move stage"
              compact
              dialog={(close) => <StageDialog customer={c} onClose={close} />}
            />
            {price && (
              <DialogButton
                key="handover"
                label="Hand over"
                compact
                variant={stage.index === stage.count ? 'primary' : undefined}
                dialog={(close) => <HandoverDialog customer={c} onClose={close} />}
              />
            )}
          </>
        )
      }
    >
      <StageBar index={stage.index} count={stage.count} finished={handedOver} />
      {settings.data && (
        <ol className="stage-names">
          {settings.data.stages.map((name, i) => (
            <li
              key={name}
              className={i + 1 === stage.index && !handedOver ? 'stage-name-now' : undefined}
              aria-current={i + 1 === stage.index && !handedOver ? 'step' : undefined}
            >
              {name}
            </li>
          ))}
        </ol>
      )}
      <Facts
        items={[
          ['Customer', [c.name, c.system_kw && `${c.system_kw} kW`].filter(Boolean).join(' · ')],
          ['Address', c.address],
          ['Sold by', c.agent_name ?? 'No agent'],
        ]}
      />
    </Section>
  );
}

function Money({ customer: c }: { customer: Customer }) {
  const { price, payments } = c;
  const advance = payments[0];
  return (
    <Section title="Payments" aside={advance && <StatusPill {...ADVANCE[advance.status]} />}>
      {price ? (
        <>
          <Facts
            items={[
              ['Total', <Amount key="total" paise={price.total} />],
              ['Subsidy', <Amount key="subsidy" paise={price.subsidy} />],
            ]}
          />
          <ul className="pay-list">
            {payments.map((p) => (
              <li key={p.id} className="pay">
                <span className="pay-line">
                  <span className="row-title">{p.label}</span>
                  <Amount paise={p.amount} />
                </span>
                <span className="pay-line">
                  <span className="cell-sub">
                    <PaymentWhen payment={p} />
                  </span>
                  <StatusPill {...PAYMENT[p.status]} />
                </span>
                {p.status !== 'paid' && <PaymentActions payment={p} />}
              </li>
            ))}
          </ul>
          {price.editable ? (
            <div className="actions">
              <DialogButton
                label="Change price"
                compact
                dialog={(close) => <PriceDialog customer={c} onClose={close} />}
              />
            </div>
          ) : (
            <p className="cell-sub">A payment is paid, so the price is fixed.</p>
          )}
        </>
      ) : (
        <p className="cell-sub">No price was set for this customer.</p>
      )}
    </Section>
  );
}
