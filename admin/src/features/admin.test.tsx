import { QueryClientProvider } from '@tanstack/react-query';
import { cleanup as cleanupRender, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { api } from '../api/client';
import { createQueryClient } from '../app/queryClient';
import { routes } from '../router';
import type { Me } from './auth/session';

// All data here is illustrative.

const ORG = 'o1';
const A = `/orgs/{org_id}/admin`;

const answer = (status: number, body?: unknown) =>
  ({
    data: status < 300 ? body : undefined,
    error: status >= 300 ? body : undefined,
    response: new Response(null, { status }),
  }) as never;

const problem = (status: number, code: string, title: string, errors?: unknown) =>
  answer(status, { type: 'about:blank', status, code, title, errors });

const page = (items: unknown[], next: string | null = null) => ({
  items,
  page: { next_cursor: next },
});

const membership = (
  id: string,
  status: Me['memberships'][number]['org']['status'] = 'active',
  role: Me['memberships'][number]['role'] = 'org_admin',
): Me['memberships'][number] => ({ org: { id, name: `Solar ${id}`, status }, role });

const admin = (...memberships: Me['memberships']): Me => ({
  id: 'u1',
  name: 'Dev Admin',
  email: 'dev@example.com',
  email_verified: true,
  is_platform_admin: false,
  terms: { accepted_version: 1, current_version: 1 },
  memberships,
});

const at = '2026-11-22T06:00:00Z';
const stage = { index: 2, count: 7, name: 'Structure' };

const payment = (id: string, status: string) => ({
  id,
  customer_id: 'c1',
  customer_name: 'Asha',
  customer_reference: 'SC-0001',
  label: `Payment ${id}`,
  amount: 455,
  status,
});

const commission = (status: string) => ({
  customer_id: 'c1',
  customer_name: 'Asha',
  customer_reference: 'SC-0001',
  agent_name: 'Meena',
  amount: 400_000,
  status,
  advance_paid: false,
  payout_last4: '4321',
});

const customer = (over: object = {}) => ({
  id: 'c1',
  reference: 'SC-0001',
  name: 'Asha',
  place: 'Mohali',
  address: 'House 12',
  kyc_status: 'in_review',
  created_at: at,
  subsidy_requested: true,
  suggested_subsidy: 7_800_000,
  documents: [
    {
      kind: 'aadhaar',
      title: 'Aadhaar',
      status: 'in_review',
      updated_at: at,
      files: [
        {
          file: {
            url: 'https://files.invalid/a',
            content_type: 'application/pdf',
            size_bytes: 52_428_800,
          },
        },
      ],
    },
    {
      kind: 'pan',
      title: 'PAN',
      status: 'in_review',
      updated_at: at,
      files: [
        { file: { url: 'https://files.invalid/p', content_type: 'image/jpeg', size_bytes: 2048 } },
      ],
    },
  ],
  payments: [],
  ...over,
});

const verified = (over: object = {}) =>
  customer({
    kyc_status: 'approved',
    stage,
    price: { total: 20_000_000, subsidy: 0, editable: true },
    payments: [payment('p1', 'claimed'), payment('p2', 'later')],
    ...over,
  });

const task = (over: object = {}) => ({
  id: 't1',
  reference: 'TSK-0001',
  title: 'Structure',
  status: 'submitted',
  due_at: '2026-11-22T20:00:00Z',
  status_at: at,
  stage,
  customer_id: 'c1',
  customer_name: 'Asha',
  assignee_id: 'w1',
  assignee_name: 'Ravi',
  assignee_active: true,
  has_problem: false,
  address: 'House 12',
  photos: [
    {
      id: 'roof',
      label: 'Roof',
      retake: false,
      photo: { url: 'https://files.invalid/r', taken_at: at, lat: 30.7, lng: 76.7, accuracy_m: 8 },
    },
  ],
  checklist: [{ id: 'c', text: 'Bolts tight', done: true }],
  events: [{ kind: 'message', actor_name: 'Ravi', at, detail: 'Gate is locked' }],
  ...over,
});

const expense = (status: string) => ({
  id: 'e1',
  reference: 'EXP-0001',
  owner_name: 'Ravi',
  amount: 455,
  category: 'fuel',
  note: 'Diesel',
  spent_on: '2026-11-21',
  status,
  has_receipt: false,
  created_at: at,
  status_at: at,
});

const installer = {
  user_id: 'w1',
  name: 'Ravi',
  email: 'ravi@example.com',
  role: 'worker',
  status: 'active',
  added_at: at,
  open_tasks: 2,
};

const STAGES = [
  'Site survey',
  'Structure',
  'Panel installation',
  'Wiring and inverter',
  'Earthing',
  'Net meter',
  'Handover',
];

// The stages with their templates (F19); Structure has one.
const TEMPLATES = STAGES.map((name, i) => ({
  index: i + 1,
  name,
  checklist: name === 'Structure' ? ['Rails level'] : [],
  photos: name === 'Structure' ? ['Rails', 'Clamps'] : [],
}));

const agent = {
  user_id: 'a1',
  name: 'Meena Agent',
  email: 'meena@example.com',
  role: 'agent',
  pay_type: 'commission',
  status: 'active',
  added_at: at,
};

const lead = (over: object = {}) => ({
  id: 'l1',
  name: 'Asha Lead',
  phone: '9814022671',
  city: 'Mohali',
  source: 'Meta ad',
  status: 'new',
  received_at: at,
  ...over,
});

const queue = (over: object = {}) => ({
  tasks: [],
  expenses: [],
  registrations: [],
  commissions: [],
  payments: [],
  leads: [],
  ...over,
});

const waiting = (id: string, status: string, amount?: number) => ({
  id,
  reference: `REF-${id}`,
  title: `Waiting ${id}`,
  person: 'Ravi',
  status,
  at,
  amount,
});

const OVERVIEW = {
  today: '2026-11-22',
  installs_running: 3,
  by_stage: [1, 2, 0, 0, 0, 0, 0],
  collected_this_month: 12_000_000,
  to_collect: 455,
  finished_by_week: ['2026-10-26', '2026-11-02', '2026-11-09', '2026-11-16'].map((from) => ({
    from,
    count: 1,
  })),
  commissions: { in_review: 400_000, waiting: 0, payable: 0, paid_this_month: 0 },
};

interface Sent {
  method: string;
  path: string;
  body?: unknown;
  header?: Record<string, string>;
}

let me: Me | null;
let reads: Record<string, (query: Record<string, unknown>) => unknown>;
let sent: Sent[];
let queries: { path: string; query: Record<string, unknown> }[];
let write: (call: Sent) => unknown;

beforeEach(() => {
  me = admin(membership(ORG));
  sent = [];
  queries = [];
  write = () => answer(200, { id: 't9' });
  reads = {
    '/orgs/{org_id}/review': () => answer(200, queue()),
    [`${A}/overview`]: () => answer(200, OVERVIEW),
    '/orgs/{org_id}/notifications': () => answer(200, { ...page([]), unread_count: 0 }),
    [`${A}/settings`]: () => answer(200, { stages: STAGES }),
    '/orgs/{org_id}/stages': () => answer(200, { stages: TEMPLATES }),
    '/orgs/{org_id}/leads': () => answer(200, page([lead()])),
    '/orgs/{org_id}/leads/{lead_id}': () => answer(200, { ...lead(), extra: {}, updated_at: at }),
    [`${A}/lead-key`]: () => answer(200, { set: false }),
    '/orgs/{org_id}/members': () => answer(200, page([installer])),
    [`${A}/customers`]: () => answer(200, page([customer()])),
    [`${A}/customers/{customer_id}`]: () => answer(200, customer()),
    [`${A}/tasks`]: () => answer(200, page([task()])),
    [`${A}/tasks/{task_id}`]: () => answer(200, task()),
    [`${A}/expenses`]: () => answer(200, page([expense('in_review')])),
    [`${A}/expenses/{expense_id}`]: () => answer(200, expense('in_review')),
    [`${A}/commissions`]: () => answer(200, page([commission('in_review')])),
    [`${A}/payments`]: () => answer(200, page([payment('p1', 'claimed')])),
  };
  vi.spyOn(api, 'GET').mockImplementation((async (
    path: string,
    init?: { params?: { query?: Record<string, unknown> } },
  ) => {
    if (path === '/me') return me ? answer(200, me) : answer(401, {});
    const query = init?.params?.query ?? {};
    queries.push({ path, query });
    return reads[path](query);
  }) as never);
  for (const method of ['POST', 'PUT', 'PATCH', 'DELETE'] as const) {
    vi.spyOn(api, method).mockImplementation((async (
      path: string,
      init?: { body?: unknown; params?: { header?: Record<string, string> } },
    ) => {
      const call = { method, path, body: init?.body, header: init?.params?.header };
      sent.push(call);
      return write(call);
    }) as never);
  }
});

afterEach(() => vi.restoreAllMocks());

function open(path: string, client = createQueryClient()) {
  const router = createMemoryRouter(routes, { initialEntries: [path] });
  render(
    <QueryClientProvider client={client}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  );
  return router;
}

const click = async (name: string | RegExp) =>
  userEvent.click(await screen.findByRole('button', { name }));

const inDialog = async () => within(await screen.findByRole('dialog'));

async function confirm(name: string) {
  const dialog = await inDialog();
  await userEvent.click(dialog.getByRole('button', { name }));
}

async function fill(label: string, value: string) {
  const field = await screen.findByLabelText(label);
  await userEvent.clear(field);
  await userEvent.type(field, value);
}

describe('companies', () => {
  it('one active company opens on its overview', async () => {
    const router = open('/');
    expect(await screen.findByRole('heading', { name: /^Good / })).toBeInTheDocument();
    expect(router.state.location.pathname).toBe(`/c/${ORG}/overview`);
  });

  it('several give a choice, and only those they manage', async () => {
    me = admin(membership('a'), membership('b'), membership('c', 'active', 'worker'));
    open('/');
    expect(await screen.findByText('Solar a')).toBeInTheDocument();
    expect(screen.getByText('Solar b')).toBeInTheDocument();
    expect(screen.queryByText('Solar c')).not.toBeInTheDocument();
  });

  it('the switch goes to the other company', async () => {
    me = admin(membership('a'), membership('b'));
    const router = open('/c/a/tasks');
    await userEvent.selectOptions(await screen.findByLabelText('Company'), 'b');
    await screen.findByRole('heading', { name: /^Good / });
    expect(router.state.location.pathname).toBe('/c/b/overview');
  });

  it.each([
    ['pending', 'Waiting for MarkCliq to approve'],
    ['suspended', 'This company is suspended'],
    ['rejected', "This company's registration wasn't approved"],
  ] as const)('a %s company shows why, and reads nothing', async (status, title) => {
    me = admin(membership(ORG, status));
    open(`/c/${ORG}/customers`);
    expect(await screen.findByText(title)).toBeInTheDocument();
    expect(screen.queryByRole('navigation', { name: 'Main' })).not.toBeInTheDocument();
    expect(queries).toEqual([]);
  });

  it("someone else's company isn't shown", async () => {
    open('/c/other/customers');
    expect(await screen.findByText("That company isn't one you manage")).toBeInTheDocument();
    expect(queries).toEqual([]);
  });

  it('an installer has no company here', async () => {
    me = admin(membership(ORG, 'active', 'worker'));
    open('/');
    expect(await screen.findByText('This website is for solar vendors')).toBeInTheDocument();
  });

  it('a login that ended goes to log in', async () => {
    reads[`${A}/customers`] = () => {
      me = null;
      return answer(401, {});
    };
    open(`/c/${ORG}/customers`);
    expect(await screen.findByRole('heading', { name: 'Admin log in' })).toBeInTheDocument();
  });
});

const LISTS = [
  ['customers?status=all', 'customers', 'No customers yet.'],
  ['tasks?view=problem', 'tasks', 'No problems reported.'],
  ['expenses', 'expenses', 'No expenses to approve.'],
  ['commissions?status=in_review', 'commissions', 'No commissions to approve.'],
  ['payments', 'payments', 'No payments to confirm.'],
] as const;

describe.each(LISTS)('the %s list', (route, endpoint, empty) => {
  it('says when it is empty', async () => {
    reads[`${A}/${endpoint}`] = () => answer(200, page([]));
    open(`/c/${ORG}/${route}`);
    expect(await screen.findByText(new RegExp(empty))).toBeInTheDocument();
  });

  it('says when it is loading', async () => {
    reads[`${A}/${endpoint}`] = () => new Promise(() => {});
    open(`/c/${ORG}/${route}`);
    expect(await screen.findByText('Loading')).toBeInTheDocument();
  });

  it('says when it failed, and tries again', async () => {
    let fail = true;
    reads[`${A}/${endpoint}`] = () => (fail ? problem(403, 'x', 'Refused') : answer(200, page([])));
    open(`/c/${ORG}/${route}`);
    expect(await screen.findByRole('alert')).toHaveTextContent("Couldn't load this");
    fail = false;
    await click('Try again');
    expect(await screen.findByText(new RegExp(empty))).toBeInTheDocument();
  });
});

describe.each([
  ['customers/c1', `${A}/customers/{customer_id}`],
  ['tasks/t1', `${A}/tasks/{task_id}`],
  ['expenses/e1', `${A}/expenses/{expense_id}`],
])('%s', (route, endpoint) => {
  it('another company\'s is "Not found"', async () => {
    reads[endpoint] = () => problem(404, 'common.not_found', 'Not found');
    open(`/c/${ORG}/${route}`);
    expect(await screen.findByRole('alert')).toHaveTextContent('Not found');
  });
});

describe('lists', () => {
  it('the board asks for each column, and Problems for its own', async () => {
    open(`/c/${ORG}/tasks`);
    await screen.findAllByRole('link', { name: /Structure/ });
    const views = () => queries.filter((q) => q.path === `${A}/tasks`).map((q) => q.query.view);
    expect(views()).toEqual(['assigned', 'submitted', 'returned', 'done']);
    await userEvent.click(screen.getByRole('link', { name: 'Problems' }));
    await vi.waitFor(() => expect(views().at(-1)).toBe('problem'));
  });

  it('show more follows the cursor', async () => {
    reads[`${A}/customers`] = (q) =>
      answer(
        200,
        q.cursor === 'next'
          ? page([customer({ id: 'c2', name: 'Bal' })])
          : page([customer()], 'next'),
      );
    open(`/c/${ORG}/customers`);
    await click('Show more');
    expect(await screen.findByText('Bal')).toBeInTheDocument();
    expect(screen.getByText('Asha')).toBeInTheDocument();
  });

  it('search keeps the keyboard in its box', async () => {
    open(`/c/${ORG}/customers`);
    await fill('Search', 'Asha');
    await userEvent.keyboard('{Enter}');
    await vi.waitFor(() =>
      expect(queries.filter((q) => q.path === `${A}/customers`).at(-1)?.query.q).toBe('Asha'),
    );
    expect(screen.getByLabelText('Search')).toHaveFocus();
  });

  it('search sends what was typed', async () => {
    open(`/c/${ORG}/customers`);
    await fill('Search', ' 98140 ');
    await click('Search');
    await vi.waitFor(() =>
      expect(queries.filter((q) => q.path === `${A}/customers`).at(-1)?.query.q).toBe('98140'),
    );
  });
});

describe('team', () => {
  it('adds an agent with how they are paid', async () => {
    open(`/c/${ORG}/team/add`);
    await screen.findByRole('heading', { name: 'Add team member' });
    await fill('Name', 'Meena');
    await fill('Email', 'meena@example.com');
    await userEvent.click(screen.getByRole('radio', { name: 'Sales Agent' }));
    await click('Send invite');
    expect(screen.getByText('Choose how this agent is paid.')).toBeInTheDocument();
    expect(sent).toEqual([]);
    await userEvent.selectOptions(screen.getByLabelText('Paid by'), 'salary');
    await click('Send invite');
    expect(await screen.findByText('Added. We emailed them how to get started.')).toBeVisible();
    expect(sent[0].body).toEqual({
      name: 'Meena',
      email: 'meena@example.com',
      role: 'agent',
      pay_type: 'salary',
    });
  });

  it('an installer is sent with no pay type', async () => {
    open(`/c/${ORG}/team/add`);
    await screen.findByRole('heading', { name: 'Add team member' });
    await fill('Name', 'Aman');
    await fill('Email', 'aman@example.com');
    await userEvent.click(screen.getByRole('radio', { name: 'EPC Installer' }));
    await click('Send invite');
    await vi.waitFor(() => expect(sent).toHaveLength(1));
    expect(sent[0].body).toEqual({ name: 'Aman', email: 'aman@example.com', role: 'worker' });
  });

  it('removing warns about open tasks first', async () => {
    open(`/c/${ORG}/team/w1`);
    await click('Remove');
    expect((await inDialog()).getByText('2 open tasks')).toBeInTheDocument();
    await confirm('Remove');
    expect(sent[0]).toMatchObject({ method: 'DELETE', path: '/orgs/{org_id}/members/{user_id}' });
  });
});

describe('a customer', () => {
  it('shows each file: a PDF to open, a picture to see', async () => {
    open(`/c/${ORG}/customers/c1`);
    const pdf = await screen.findByRole('link', { name: 'Open Aadhaar in a new tab' });
    expect(pdf).toHaveTextContent('PDF');
    expect(pdf).toHaveTextContent('50.0 MB');
    expect(pdf).toHaveAttribute('rel', 'noopener noreferrer');
    const image = screen
      .getByRole('link', { name: 'Open PAN in a new tab' })
      .querySelector('img') as HTMLImageElement;
    image.dispatchEvent(new Event('error'));
    expect(await screen.findByText("Can't preview. Open it.")).toBeInTheDocument();
  });

  it('shows every file of a document, with its side', async () => {
    const c = customer();
    const second = { file: { ...c.documents[0].files[0].file }, side: 'back' };
    c.documents[0].files = [c.documents[0].files[0], second] as never;
    reads[`${A}/customers/{customer_id}`] = () => answer(200, c);
    open(`/c/${ORG}/customers/c1`);
    expect(await screen.findByText('File 1')).toBeInTheDocument();
    expect(screen.getAllByText('Back').some((e) => e.matches('.cell-sub'))).toBe(true);
  });

  it('a fresh link gets its own try at a preview', async () => {
    const client = createQueryClient();
    open(`/c/${ORG}/customers/c1`, client);
    const link = await screen.findByRole('link', { name: 'Open PAN in a new tab' });
    link.querySelector('img')?.dispatchEvent(new Event('error'));
    await screen.findByText("Can't preview. Open it.");
    const fresh = customer();
    fresh.documents[1].files[0].file.url = 'https://files.invalid/p-again';
    reads[`${A}/customers/{customer_id}`] = () => answer(200, fresh);
    await client.invalidateQueries({ queryKey: ['org'] });
    await vi.waitFor(() => expect(link.querySelector('img')).not.toBeNull());
  });

  it('verifies in exact paise, with the suggested subsidy', async () => {
    open(`/c/${ORG}/customers/c1`);
    await click('Verify');
    await confirm('Verify');
    expect(screen.getByText('Enter ₹10 up to ₹10 crore.')).toBeInTheDocument();
    expect(sent).toEqual([]);
    await fill('System price, ₹', '2,85,000.50');
    await confirm('Verify');
    expect(sent[0].body).toEqual({ total: 28_500_050, subsidy: 7_800_000 });
  });

  it("can't be verified while a document is with the agent", async () => {
    reads[`${A}/customers/{customer_id}`] = () =>
      answer(200, customer({ kyc_status: 'needs_fix' }));
    open(`/c/${ORG}/customers/c1`);
    expect(await screen.findByRole('button', { name: 'Verify' })).toBeDisabled();
  });

  it('sends a document back only with a reason', async () => {
    open(`/c/${ORG}/customers/c1`);
    await userEvent.click((await screen.findAllByRole('button', { name: 'Send back' }))[0]);
    await confirm('Send back');
    expect(sent).toEqual([]);
    await fill("What's wrong", 'Blurred');
    await confirm('Send back');
    expect(sent[0].body).toEqual({ note: 'Blurred' });
  });

  it('moves the stage', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    open(`/c/${ORG}/customers/c1`);
    await click('Move stage');
    await userEvent.selectOptions((await inDialog()).getByLabelText('Stage'), '4');
    await confirm('Move');
    expect(sent[0]).toMatchObject({ method: 'PUT', body: { stage_index: 4 } });
  });

  it('a price change warns about a claimed payment', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    open(`/c/${ORG}/customers/c1`);
    await click('Change price');
    expect((await inDialog()).getByText(/says they paid ₹4.55/)).toBeInTheDocument();
    await fill('System price, ₹', '150000');
    await confirm('Change price');
    expect(sent[0].body).toEqual({ total: 15_000_000, subsidy: 0 });
  });

  it('the price is fixed once a payment is paid', async () => {
    reads[`${A}/customers/{customer_id}`] = () =>
      answer(200, verified({ price: { total: 100_000, subsidy: 0, editable: false } }));
    open(`/c/${ORG}/customers/c1`);
    expect(await screen.findByText(/the price is fixed/)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Change price' })).not.toBeInTheDocument();
  });

  it('handing over warns about what is unpaid', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    open(`/c/${ORG}/customers/c1`);
    await click('Hand over');
    expect((await inDialog()).getByText(/2 payments aren't paid yet/)).toBeInTheDocument();
  });

  it("a server's field error shows under its field", async () => {
    write = () =>
      problem(422, 'validation.failed', 'Check the highlighted fields', [
        { field: 'total', message: 'Server says no.' },
      ]);
    open(`/c/${ORG}/customers/c1`);
    await click('Verify');
    await fill('System price, ₹', '200000');
    await confirm('Verify');
    const field = await screen.findByLabelText('System price, ₹');
    await vi.waitFor(() => expect(field).toHaveAccessibleDescription('Server says no.'));
  });

  it('someone got there first: closes, says so, and reloads', async () => {
    write = () => {
      reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
      return problem(409, 'registration.locked', "This customer can't be changed that way now");
    };
    open(`/c/${ORG}/customers/c1`);
    await click('Verify');
    await fill('System price, ₹', '200000');
    await confirm('Verify');
    expect(
      await screen.findByText(/can't be changed that way now. The page now shows how it stands./),
    ).toBeVisible();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(await screen.findByRole('button', { name: 'Move stage' })).toBeInTheDocument();
  });

  it('a decision is sent once, however often it is clicked', async () => {
    write = () => new Promise(() => {});
    open(`/c/${ORG}/customers/c1`);
    await click('Verify');
    await fill('System price, ₹', '200000');
    const button = (await inDialog()).getByRole('button', { name: 'Verify' });
    await userEvent.dblClick(button);
    expect(sent).toHaveLength(1);
  });
});

describe('tasks', () => {
  it('reopened, a task shows what changed meanwhile', async () => {
    reads[`${A}/tasks/{task_id}`] = () => answer(200, task({ status: 'assigned' }));
    const router = open(`/c/${ORG}/tasks/t1`);
    await screen.findByRole('button', { name: 'Reschedule or reassign' });
    await router.navigate(`/c/${ORG}/tasks`);
    await screen.findByRole('heading', { name: 'Tasks' });
    // The installer submits while the admin is on the list.
    reads[`${A}/tasks/{task_id}`] = () => answer(200, task());
    await router.navigate(`/c/${ORG}/tasks/t1`);
    expect(await screen.findByRole('button', { name: 'Approve' })).toBeInTheDocument();
  });

  it('shows proof, where it was taken, and replies', async () => {
    open(`/c/${ORG}/tasks/t1`);
    expect(await screen.findByText('Gate is locked')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: '30.70000, 76.70000' })).toHaveAttribute(
      'href',
      expect.stringContaining('query=30.7,76.7'),
    );
    expect(screen.getByText(/±8 m/)).toBeInTheDocument();
  });

  it('approves', async () => {
    open(`/c/${ORG}/tasks/t1`);
    await click('Approve');
    await confirm('Approve');
    expect(sent[0].path).toBe('/orgs/{org_id}/tasks/{task_id}/approve');
  });

  it('sends back with the photos to take again', async () => {
    open(`/c/${ORG}/tasks/t1`);
    await click('Send back');
    await fill('What needs doing', 'Too dark');
    await userEvent.click(screen.getByLabelText('Roof', { selector: 'input' }));
    await confirm('Send back');
    expect(sent[0].body).toEqual({ note: 'Too dark', retake: ['roof'] });
  });

  it("a removed installer's task needs someone chosen", async () => {
    reads[`${A}/tasks/{task_id}`] = () =>
      answer(200, task({ status: 'assigned', assignee_id: 'gone', assignee_active: false }));
    open(`/c/${ORG}/tasks/t1`);
    expect(await screen.findByText('Ravi is no longer in the company')).toBeInTheDocument();
    await click('Reschedule or reassign');
    await confirm('Save');
    expect(screen.getByText('Choose an installer.')).toBeInTheDocument();
    const dialog = await inDialog();
    await dialog.findByRole('option', { name: 'Ravi' });
    await userEvent.selectOptions(dialog.getByLabelText('Installer'), 'w1');
    await confirm('Save');
    // 01:30 on the 23rd in India is 20:00 UTC on the 22nd.
    expect(sent[0].body).toEqual({ due_at: '2026-11-22T20:00:00.000Z', assignee_id: 'w1' });
  });

  it('creates one, in Indian time, and a retry keeps its key', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    let fail = true;
    write = () => (fail ? problem(503, 'x', 'Down') : answer(201, { id: 't9' }));
    const router = open(`/c/${ORG}/tasks/new?customer=c1`);
    await screen.findByRole('option', { name: 'Ravi' });
    await vi.waitFor(() => expect(screen.getByLabelText('Title')).toHaveValue('Structure'));
    await userEvent.selectOptions(screen.getByLabelText('Installer'), 'w1');
    await fill('Due (India time)', '2026-11-25T10:30');
    await fill('Photo 1', 'Clamp close-up');
    await click('Assign task');
    expect(await screen.findByRole('alert')).toHaveTextContent('Something went wrong');
    fail = false;
    await click('Assign task');
    await vi.waitFor(() => expect(router.state.location.pathname).toBe(`/c/${ORG}/tasks/t9`));
    expect(sent[1].body).toEqual({
      customer_id: 'c1',
      title: 'Structure',
      stage_index: 2,
      assignee_id: 'w1',
      due_at: '2026-11-25T05:00:00.000Z',
      photos: [
        { id: 'photo-1', label: 'Clamp close-up' },
        { id: 'photo-2', label: 'Clamps' },
      ],
      checklist: [{ id: 'check-1', text: 'Rails level' }],
    });
    const key = sent[0].header?.['Idempotency-Key'];
    expect(key).toMatch(/^[0-9a-f-]{36}$/);
    expect(sent[1].header?.['Idempotency-Key']).toBe(key);
  });

  it('only a verified customer gets one', async () => {
    open(`/c/${ORG}/tasks/new?customer=c1`);
    expect(await screen.findByText("Asha isn't verified")).toBeInTheDocument();
  });
});

describe('money', () => {
  it('an approved expense can be marked paid', async () => {
    reads[`${A}/expenses/{expense_id}`] = () => answer(200, expense('approved'));
    open(`/c/${ORG}/expenses/e1`);
    expect(await screen.findByText('₹4.55')).toBeInTheDocument();
    await click('Mark paid');
    await confirm('Yes, paid');
    expect(sent[0].path).toBe('/orgs/{org_id}/expenses/{expense_id}/paid');
  });

  it('an expense in review is approved', async () => {
    open(`/c/${ORG}/expenses/e1`);
    await click('Approve ₹4.55');
    await confirm('Approve');
    expect(sent[0].path).toBe('/orgs/{org_id}/expenses/{expense_id}/approve');
  });

  it('a commission unchanged sends no amount', async () => {
    open(`/c/${ORG}/commissions`);
    await click('Review');
    await confirm('Approve');
    expect(sent[0].body).toEqual({});
  });

  it('a commission changed sends the new paise', async () => {
    open(`/c/${ORG}/commissions`);
    await click('Review');
    await fill('Amount, ₹', '3500.25');
    await confirm('Approve');
    expect(sent[0].body).toEqual({ amount: 350_025 });
  });

  it('confirms a claimed payment', async () => {
    open(`/c/${ORG}/payments`);
    await click('Confirm received');
    await confirm('Yes, received');
    expect(sent[0].path).toBe('/orgs/{org_id}/payments/{payment_id}/confirm');
  });

  it('asks for the next payment', async () => {
    reads[`${A}/payments`] = () => answer(200, page([payment('p2', 'later')]));
    open(`/c/${ORG}/payments?status=later`);
    await click('Ask for it');
    await fill('Due on', '2099-01-02');
    await confirm('Ask');
    expect(sent[0].body).toEqual({ due_on: '2099-01-02' });
  });

  it.each([
    ['payments?status=all', 'payments', payment('p1', 'later'), payment('p1', 'due'), 'Ask for it'],
    [
      'payments?status=all',
      'payments',
      payment('p1', 'claimed'),
      { ...payment('p1', 'claimed'), amount: 999 },
      'Confirm received',
    ],
    [
      'commissions?status=all',
      'commissions',
      commission('in_review'),
      commission('payable'),
      'Review',
    ],
  ])(
    'an open dialog never turns into another (%s)',
    async (route, endpoint, before, after, button) => {
      reads[`${A}/${endpoint}`] = () => answer(200, page([before]));
      const client = createQueryClient();
      open(`/c/${ORG}/${route}`, client);
      await click(button as string);
      await screen.findByRole('dialog');
      // Another tab decides, and this one refreshes.
      reads[`${A}/${endpoint}`] = () => answer(200, page([after]));
      await client.invalidateQueries({ queryKey: ['org'] });
      await vi.waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
      expect(await screen.findByText(/changed meanwhile/)).toBeVisible();
      expect(sent).toEqual([]);
    },
  );

  it('sets and checks the UPI ID', async () => {
    open(`/c/${ORG}/settings`);
    await click('Add UPI ID');
    await fill('UPI ID', 'nobank');
    await confirm('Save');
    expect(screen.getByText('Enter a UPI id like name@bank.')).toBeInTheDocument();
    await fill('UPI ID', 'examplesolar@okhdfc');
    await confirm('Save');
    expect(sent[0].body).toEqual({ upi_id: 'examplesolar@okhdfc' });
  });
});

describe('inbox', () => {
  it('shows what waits, with amounts, and counts it', async () => {
    reads['/orgs/{org_id}/review'] = () =>
      answer(
        200,
        queue({
          tasks: [waiting('t1', 'reply')],
          expenses: [waiting('e1', 'approved', 455)],
          payments: [waiting('p1', 'claimed', 6_000_000)],
        }),
      );
    open(`/c/${ORG}/overview`);
    expect(await screen.findByText('Replied')).toBeInTheDocument();
    expect(screen.getByText('To pay')).toBeInTheDocument();
    expect(screen.getByText('Expense ₹4.55')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Waiting t1/ })).toHaveAttribute(
      'href',
      `/c/${ORG}/tasks/t1`,
    );
    expect(await screen.findByRole('link', { name: 'Tasks 1' })).toBeInTheDocument();
  });

  it('says when nothing waits', async () => {
    open(`/c/${ORG}/overview`);
    expect(await screen.findByText('Nothing is waiting for you.')).toBeInTheDocument();
  });

  it('notifications open their record and are marked read', async () => {
    const note = {
      id: 'n1',
      kind: 'task_message',
      title: 'Installer replied',
      body: 'Gate is locked',
      at,
      read: false,
      task_id: 't1',
    };
    let unread = 1;
    reads['/orgs/{org_id}/notifications'] = () =>
      answer(200, { ...page([{ ...note, read: unread === 0 }]), unread_count: unread });
    write = () => {
      unread = 0;
      return answer(204);
    };
    open(`/c/${ORG}/notifications`);
    expect(await screen.findByRole('link', { name: /Installer replied/ })).toHaveAttribute(
      'href',
      `/c/${ORG}/tasks/t1`,
    );
    await click('Mark all read');
    await vi.waitFor(() =>
      expect(screen.queryByRole('button', { name: 'Mark all read' })).not.toBeInTheDocument(),
    );
    expect(sent[0].path).toBe('/orgs/{org_id}/notifications/read');
  });

  it("a claimed payment that didn't arrive needs a reason", async () => {
    open(`/c/${ORG}/payments`);
    await click('Not received');
    await confirm('Not received');
    expect(sent).toEqual([]);
    await fill('What you checked', 'Nothing in the account');
    await confirm('Not received');
    expect(sent[0]).toMatchObject({
      path: '/orgs/{org_id}/payments/{payment_id}/not-received',
      body: { note: 'Nothing in the account' },
    });
  });

  it('an expense can be refused, with the reason', async () => {
    open(`/c/${ORG}/expenses/e1`);
    await click("Don't accept");
    await fill('Reason', 'Not a company cost');
    await confirm("Don't accept");
    expect(sent[0]).toMatchObject({
      path: '/orgs/{org_id}/expenses/{expense_id}/reject',
      body: { note: 'Not a company cost' },
    });
  });
});

describe('attendance', () => {
  const ravi = { user_id: 'w1', name: 'Ravi', role: 'worker', removed: false };
  const worked = {
    date: '2026-11-03',
    status: 'ended',
    start: { at: '2026-11-03T03:42:00Z', sent_late: true },
    end: { at: '2026-11-03T13:10:00Z', sent_late: false },
    minutes: 568,
  };

  it('shows the day in Indian time, with late taps marked', async () => {
    reads['/orgs/{org_id}/attendance/day'] = () =>
      answer(200, { date: '2026-11-03', people: [{ person: ravi, day: worked }] });
    open(`/c/${ORG}/attendance`);
    expect(await screen.findByText('09:12')).toBeInTheDocument();
    expect(screen.getByText('18:40')).toBeInTheDocument();
    expect(screen.getByText('sent late')).toBeInTheDocument();
    expect(screen.getByText('9 h 28 m')).toBeInTheDocument();
  });

  it('shows the month and downloads its CSV', async () => {
    reads['/orgs/{org_id}/attendance/month'] = () =>
      answer(200, {
        month: '2026-11',
        people: [{ person: ravi, days: [worked], days_worked: 1, minutes: 568 }],
      });
    reads['/orgs/{org_id}/attendance/month.csv'] = () => answer(200, 'name,role\n');
    const made = vi.fn(() => 'blob:csv');
    vi.stubGlobal('URL', Object.assign(URL, { createObjectURL: made, revokeObjectURL: vi.fn() }));
    const saved = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});
    open(`/c/${ORG}/attendance?view=month`);
    expect(await screen.findByText(/09:12 to 18:40, sent late/)).toBeInTheDocument();
    await click('Download CSV');
    await vi.waitFor(() => expect(saved).toHaveBeenCalled());
    vi.unstubAllGlobals();
  });
});

describe('logo', () => {
  it('uploads straight to storage, then sets it', async () => {
    reads[`${A}/settings`] = () => answer(200, { stages: STAGES });
    write = ({ method }) =>
      method === 'POST'
        ? answer(201, {
            upload_id: 'up1',
            url: 'https://files.invalid/put',
            method: 'PUT',
            headers: { 'content-type': 'image/png', 'content-length': '3' },
          })
        : answer(204);
    const stored = vi.fn(async () => new Response(null, { status: 200 }));
    vi.stubGlobal('fetch', stored);
    open(`/c/${ORG}/settings`);
    await click('Add logo');
    await userEvent.upload(
      await screen.findByLabelText('Image'),
      new File(['png'], 'logo.png', { type: 'image/png' }),
    );
    await confirm('Save');
    await vi.waitFor(() => expect(sent).toHaveLength(2));
    expect(sent[0].body).toEqual({ content_type: 'image/png', size_bytes: 3, purpose: 'logo' });
    expect(stored).toHaveBeenCalledWith(
      'https://files.invalid/put',
      expect.objectContaining({ headers: { 'content-type': 'image/png' } }),
    );
    expect(sent[1]).toMatchObject({ path: '/orgs/{org_id}/logo', body: { upload_id: 'up1' } });
    vi.unstubAllGlobals();
  });

  it('a file too big never leaves the browser', async () => {
    open(`/c/${ORG}/settings`);
    await click('Add logo');
    await userEvent.upload(
      await screen.findByLabelText('Image'),
      new File([new Uint8Array(1024 * 1024 + 1)], 'big.png', { type: 'image/png' }),
    );
    await confirm('Save');
    expect(await screen.findByText('A logo is up to 1 MB.')).toBeInTheDocument();
    expect(sent).toEqual([]);
  });
});

describe('terms', () => {
  it('changed terms are agreed to before any screen', async () => {
    me = { ...admin(membership(ORG)), terms: { accepted_version: 1, current_version: 2 } };
    write = () => {
      me = { ...admin(membership(ORG)), terms: { accepted_version: 2, current_version: 2 } };
      return answer(204);
    };
    open(`/c/${ORG}/team`);
    expect(await screen.findByRole('heading', { name: 'Before you start' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Continue' })).toBeDisabled();
    await userEvent.click(screen.getByRole('checkbox'));
    await click('Continue');
    expect(await screen.findByRole('heading', { name: 'Team' })).toBeInTheDocument();
    expect(sent[0]).toMatchObject({ path: '/me/terms', body: { version: 2 } });
  });

  it('how to delete an account is public', async () => {
    me = null;
    open('/delete-account');
    expect(
      await screen.findByRole('heading', { name: 'Delete your SolaCliq account' }),
    ).toBeInTheDocument();
  });
});

describe('found running the real site', () => {
  async function signIn(next: string, as: Me) {
    me = null;
    write = ({ path }) => {
      if (path !== '/auth/login') return answer(204);
      me = as;
      return answer(200, { user: as });
    };
    const router = open(`/login?next=${encodeURIComponent(next)}`);
    await fill('Work email', 'dev@example.com');
    await fill('Password', 'sunlight12');
    await click('Log in');
    return router;
  }

  it('log in goes on to the page that was opened', async () => {
    const router = await signIn(`/c/${ORG}/team?role=worker`, admin(membership(ORG)));
    expect(await screen.findByRole('heading', { name: 'Team' })).toBeInTheDocument();
    expect(router.state.location.search).toBe('?role=worker');
  });

  it("the next person on a shared computer isn't sent into the last one's company", async () => {
    const router = await signIn('/c/someone-elses/team', admin(membership(ORG)));
    expect(await screen.findByRole('heading', { name: /^Good / })).toBeInTheDocument();
    expect(router.state.location.pathname).toBe(`/c/${ORG}/overview`);
  });

  it('a month is chosen, as Firefox has no month picker', async () => {
    reads['/orgs/{org_id}/attendance/month'] = () => answer(200, { month: '2026-11', people: [] });
    open(`/c/${ORG}/attendance?view=month`);
    const field = await screen.findByLabelText('Month');
    expect(field.tagName).toBe('SELECT');
    const earlier = within(field).getAllByRole('option')[1] as HTMLOptionElement;
    await userEvent.selectOptions(field, earlier.value);
    await vi.waitFor(() => expect(queries.at(-1)?.query).toMatchObject({ month: earlier.value }));
  });

  it('no documents before a handover is not blamed on retention', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified({ documents: [] }));
    open(`/c/${ORG}/customers/c1`);
    expect(await screen.findByText('No documents were sent.')).toBeInTheDocument();
  });
});

describe("the admin design's shapes", () => {
  it('a verified customer opens as their project', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    const router = open(`/c/${ORG}/customers/c1`);
    expect(await screen.findByRole('heading', { name: /^Stage 2 of 7/ })).toBeInTheDocument();
    expect(router.state.location.pathname).toBe(`/c/${ORG}/projects/c1`);
  });

  it('a new request stays a customer, with the decision beside the files', async () => {
    const router = open(`/c/${ORG}/projects/c1`);
    expect(await screen.findByRole('heading', { name: 'Documents decision' })).toBeInTheDocument();
    expect(router.state.location.pathname).toBe(`/c/${ORG}/customers/c1`);
  });

  it('the overview leads with the numbers', async () => {
    open(`/c/${ORG}/overview`);
    expect(await screen.findByText('₹1,20,000')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Projects by stage' })).toBeInTheDocument();
  });

  it('new task shows what the installer will see', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    open(`/c/${ORG}/tasks/new?customer=c1`);
    await fill('Note for the installer (optional)', 'Use batch B clamps');
    const phone = document.querySelector<HTMLElement>('.phone')!;
    expect(within(phone).getByText('Use batch B clamps')).toBeInTheDocument();
  });

  it('an expense arriving on top does not replace the one open', async () => {
    const client = createQueryClient();
    open(`/c/${ORG}/expenses`, client);
    await screen.findByRole('button', { name: 'Approve ₹4.55' });
    reads[`${A}/expenses`] = () =>
      answer(
        200,
        page([{ ...expense('in_review'), id: 'e0', note: 'Cable' }, expense('in_review')]),
      );
    await client.invalidateQueries({ queryKey: ['org'] });
    expect(await screen.findByText('Cable')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /^Diesel/ })).toHaveAttribute('aria-current', 'true');
  });
});

describe('stage templates (F19)', () => {
  it('a new task fills from its stage, and another stage brings its own', async () => {
    reads[`${A}/customers/{customer_id}`] = () => answer(200, verified());
    open(`/c/${ORG}/tasks/new?customer=c1`);
    expect(await screen.findByDisplayValue('Rails level')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Clamps')).toBeInTheDocument();
    expect(screen.getByText('Checklist · from the Structure template')).toBeInTheDocument();
    await userEvent.selectOptions(screen.getByLabelText('Stage'), '3');
    expect(screen.queryByDisplayValue('Rails level')).not.toBeInTheDocument();
    expect(screen.getByLabelText('Title')).toHaveValue('Panel installation');
  });

  it('the admin renames a stage and sets its template', async () => {
    write = () => answer(200, { stages: TEMPLATES });
    open(`/c/${ORG}/settings/stages?stage=2`);
    await fill('Name', 'Mounting');
    await click('Add item');
    await fill('Item 2', 'Torque checked');
    await click('Remove photo 1');
    await click('Save template');
    await vi.waitFor(() => expect(sent).toHaveLength(1));
    expect(sent[0]).toMatchObject({
      method: 'PUT',
      path: '/orgs/{org_id}/admin/stages/{index}',
      body: { name: 'Mounting', checklist: ['Rails level', 'Torque checked'], photos: ['Clamps'] },
    });
  });

  it('a stage needs a name', async () => {
    open(`/c/${ORG}/settings/stages?stage=1`);
    await fill('Name', ' ');
    await click('Save template');
    expect(await screen.findByText('Give the stage a name.')).toBeInTheDocument();
    expect(sent).toEqual([]);
  });
});

describe('leads (F20)', () => {
  it('new leads are listed, and one goes to an agent through a dialog', async () => {
    reads['/orgs/{org_id}/members'] = () => answer(200, page([agent]));
    open(`/c/${ORG}/leads`);
    expect(await screen.findByRole('link', { name: 'Asha Lead' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Call 9814022671/ })).toHaveAttribute(
      'href',
      'tel:+919814022671',
    );
    await click('Meena');
    await confirm('Give lead');
    expect(sent[0]).toMatchObject({
      method: 'PATCH',
      path: '/orgs/{org_id}/leads/{lead_id}',
      body: { agent_id: 'a1' },
    });
    expect(queries.find((q) => q.path === '/orgs/{org_id}/leads')?.query).toMatchObject({
      status: 'new',
    });
  });

  it('a lead is marked, noted and deleted from its page', async () => {
    const router = open(`/c/${ORG}/leads/l1`);
    await click('Mark contacted');
    await confirm('Mark contacted');
    expect(sent[0].body).toEqual({ status: 'contacted' });
    await click('Add note');
    await userEvent.type((await inDialog()).getByLabelText('Note'), 'Calls back Monday');
    await confirm('Save note');
    expect(sent[1].body).toEqual({ note: 'Calls back Monday' });
    await click('Delete lead');
    await confirm('Delete lead');
    await vi.waitFor(() => expect(router.state.location.pathname).toBe(`/c/${ORG}/leads`));
    expect(sent[2]).toMatchObject({ method: 'DELETE' });
  });

  it('settings make a lead key and show it once', async () => {
    write = () => answer(201, { key: 'lead_abc_123', made_at: at });
    open(`/c/${ORG}/settings`);
    await click('Make a key');
    await confirm('Make key');
    expect(await screen.findByText('lead_abc_123')).toBeInTheDocument();
    expect(sent[0]).toMatchObject({ method: 'POST', path: `${A}/lead-key` });
  });

  it('a new lead waits on the overview and in the sidebar', async () => {
    reads['/orgs/{org_id}/review'] = () =>
      answer(
        200,
        queue({
          leads: [
            { ...waiting('l1', 'new'), reference: '', title: 'Asha Lead', person: 'Meta ad' },
          ],
        }),
      );
    open(`/c/${ORG}/overview`);
    expect(await screen.findByText('Asha Lead · Meta ad')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /^Leads 1$/ })).toBeInTheDocument();
  });
});

describe('editing a member (F21)', () => {
  it('saves a role change only after confirming what changes', async () => {
    open(`/c/${ORG}/team/w1`);
    const save = await screen.findByRole('button', { name: 'Save changes' });
    expect(save).toBeDisabled();
    await userEvent.click(screen.getByLabelText('Sales Agent'));
    // A Sales Agent needs a pay type first.
    expect(save).toBeDisabled();
    await userEvent.click(screen.getByLabelText('Salaried'));
    await userEvent.click(save);
    expect(
      await screen.findByRole('heading', { name: 'Make Ravi a Sales Agent?' }),
    ).toBeInTheDocument();
    await confirm('Save changes');
    expect(sent[0]).toMatchObject({
      method: 'PATCH',
      path: '/orgs/{org_id}/members/{user_id}',
      body: { role: 'agent', pay_type: 'salary' },
    });
  });

  it("changes an agent's pay from now on", async () => {
    reads['/orgs/{org_id}/members'] = () => answer(200, page([agent]));
    open(`/c/${ORG}/team/a1`);
    await userEvent.click(await screen.findByLabelText('Salaried'));
    await click('Save changes');
    await confirm('Save changes');
    expect(sent[0].body).toEqual({ pay_type: 'salary' });
  });

  it('sends an invite again while they are invited', async () => {
    reads['/orgs/{org_id}/members'] = () =>
      answer(200, page([{ ...installer, status: 'invited' }]));
    open(`/c/${ORG}/team/w1`);
    await click('Resend invite');
    await confirm('Send');
    expect(sent[0]).toMatchObject({
      method: 'POST',
      path: '/orgs/{org_id}/members/{user_id}/invite',
    });
  });
});

describe("MarkCliq's companies (F22)", () => {
  const company = (over: object = {}) => ({
    id: 'p1',
    name: 'Sun Power',
    legal_name: 'Sun Power Private Limited',
    business_type: 'private_limited',
    gstin: '03AAAAA0000A1Z5',
    pan: 'AAAAA0000A',
    address_line_1: 'Plot 4',
    city: 'Mohali',
    state: 'Punjab',
    pin_code: '160055',
    phone: '9814022671',
    status: 'pending',
    owner: { user_id: 'u9', name: 'Asha Owner', email: 'asha@example.com', phone: '9814022672' },
    created_at: at,
    ...over,
  });

  beforeEach(() => {
    me = { ...admin(), is_platform_admin: true };
    reads['/platform/orgs'] = (query) =>
      answer(200, page(query.status === 'pending' ? [company()] : []));
    reads['/platform/orgs/{org_id}'] = () => answer(200, company());
    write = () => answer(200, company({ status: 'active' }));
  });

  it('a platform admin lands on home with Companies and how many wait', async () => {
    me = { ...admin(membership(ORG)), is_platform_admin: true };
    const router = open('/');
    expect(await screen.findByText('1 waiting')).toBeInTheDocument();
    // No jump into their one company: MarkCliq's card would be hidden.
    expect(router.state.location.pathname).toBe('/');
    expect(screen.getByText(`Solar ${ORG}`)).toBeInTheDocument();
  });

  it('the list opens on those waiting, and other tabs say when they are empty', async () => {
    open('/platform/companies');
    expect(await screen.findByRole('link', { name: 'Review Sun Power' })).toBeInTheDocument();
    expect(queries.find((q) => q.path === '/platform/orgs')?.query).toMatchObject({
      status: 'pending',
    });
    await userEvent.click(screen.getByRole('link', { name: 'Suspended' }));
    expect(await screen.findByText('No suspended companies.')).toBeInTheDocument();
  });

  it('a waiting company is approved through a dialog', async () => {
    open('/platform/companies/p1');
    expect(await screen.findByText('03AAAAA0000A1Z5')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Call Asha' })).toHaveAttribute(
      'href',
      'tel:+919814022672',
    );
    expect(screen.queryByRole('button', { name: 'Suspend' })).not.toBeInTheDocument();
    await click('Approve');
    await confirm('Approve');
    expect(sent[0]).toMatchObject({
      method: 'POST',
      path: '/platform/orgs/{org_id}/status',
      body: { status: 'active' },
    });
  });

  it('rejecting needs a reason, which is sent', async () => {
    open('/platform/companies/p1');
    await click('Reject');
    await confirm('Reject');
    expect(await screen.findByText('Write a few words.')).toBeInTheDocument();
    expect(sent).toHaveLength(0);
    await userEvent.type((await inDialog()).getByLabelText('Reason'), 'GSTIN does not match');
    await confirm('Reject');
    expect(sent[0].body).toEqual({ status: 'rejected', note: 'GSTIN does not match' });
  });

  it('an active company can only be suspended, a suspended one only restored', async () => {
    reads['/platform/orgs/{org_id}'] = () => answer(200, company({ status: 'active' }));
    open('/platform/companies/p1');
    await click('Suspend');
    await confirm('Suspend');
    expect(sent[0].body).toEqual({ status: 'suspended' });
    expect(screen.queryByRole('button', { name: 'Approve' })).not.toBeInTheDocument();
    cleanupRender();
    reads['/platform/orgs/{org_id}'] = () => answer(200, company({ status: 'suspended' }));
    open('/platform/companies/p1');
    await click('Restore');
    await confirm('Restore');
    expect(sent[1].body).toEqual({ status: 'active' });
  });

  it('someone else deciding first closes the dialog and says so', async () => {
    write = () => problem(409, 'org.status_change_not_allowed', "That status change isn't allowed");
    open('/platform/companies/p1');
    await click('Approve');
    await confirm('Approve');
    expect(await screen.findByRole('status')).toHaveTextContent(/now shows how it stands/);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it("someone who isn't a platform admin finds nothing there", async () => {
    me = admin(membership(ORG));
    open('/platform/companies');
    expect(await screen.findByRole('heading', { name: 'Page not found' })).toBeInTheDocument();
    expect(queries.some((q) => q.path.startsWith('/platform'))).toBe(false);
  });
});
