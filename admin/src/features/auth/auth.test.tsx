import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryRouter, RouterProvider } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { api } from '../../api/client';
import { routes } from '../../router';
import { canUseAdmin, fetchMe, type Me } from './session';
import { safeNextPath, validateCode, validateEmail, validateNewPassword } from './validators';

// The shape openapi-fetch resolves with; cast because its generic types
// can't be named for one path.
const answer = (status: number, body?: unknown) =>
  ({
    data: status < 300 ? body : undefined,
    error: status >= 300 ? body : undefined,
    response: new Response(null, { status }),
  }) as never;

const problem = (status: number, code: string) => ({
  type: 'about:blank',
  title: code,
  status,
  code,
});

const orgAdmin: Me = {
  id: 'u1',
  name: 'Ravi Admin',
  email: 'ravi@example.com',
  email_verified: true,
  is_platform_admin: false,
  memberships: [
    {
      org: { id: 'o1', name: 'Example Solar (illustrative)', status: 'pending' },
      role: 'org_admin',
    },
  ],
};

const customer: Me = { ...orgAdmin, name: 'Asha Customer', memberships: [] };

let signedIn: Me | null;
let getMock: ReturnType<typeof vi.spyOn>;
let postMock: ReturnType<typeof vi.spyOn>;
let postHandler: (path: string, body: unknown) => unknown;

beforeEach(() => {
  signedIn = null;
  postHandler = () => answer(204);
  getMock = vi.spyOn(api, 'GET').mockImplementation((async (path: string) => {
    if (path === '/me')
      return signedIn ? answer(200, signedIn) : answer(401, problem(401, 'auth.session_expired'));
    return answer(200, { status: 'ok', version: '0.1.0', database: 'ok' });
  }) as never);
  postMock = vi
    .spyOn(api, 'POST')
    .mockImplementation((async (path: string, init?: { body?: unknown }) =>
      postHandler(path, init?.body)) as never);
});

afterEach(() => vi.restoreAllMocks());

function renderAt(path: string) {
  const router = createMemoryRouter(routes, { initialEntries: [path] });
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  );
  return router;
}

async function logIn(email: string, password: string) {
  await userEvent.type(screen.getByLabelText('Email'), email);
  await userEvent.type(screen.getByLabelText('Password'), password);
  await userEvent.click(screen.getByRole('button', { name: 'Log in' }));
}

describe('validators', () => {
  it('checks email, new password and code', () => {
    expect(validateEmail('')).toBe('Enter Email.');
    expect(validateEmail('nope')).toMatch(/name@example.com/);
    expect(validateEmail(' a@b.co ')).toBeUndefined();
    expect(validateNewPassword('short')).toBe('Use at least 8 characters.');
    expect(validateNewPassword('long enough')).toBeUndefined();
    expect(validateCode('12345')).toBeDefined();
    expect(validateCode('123456')).toBeUndefined();
  });

  it('only follows next paths on this site', () => {
    expect(safeNextPath('/orgs?x=1')).toBe('/orgs?x=1');
    expect(safeNextPath(null)).toBe('/');
    expect(safeNextPath('https://evil.example')).toBe('/');
    expect(safeNextPath('//evil.example')).toBe('/');
    expect(safeNextPath('/\\evil.example')).toBe('/');
  });
});

describe('fetchMe', () => {
  it('is the person on 200 and null on 401', async () => {
    signedIn = orgAdmin;
    await expect(fetchMe()).resolves.toEqual(orgAdmin);
    signedIn = null;
    await expect(fetchMe()).resolves.toBeNull();
  });

  it('throws on server and network failures instead of signing out', async () => {
    getMock.mockResolvedValueOnce(answer(500, {}));
    await expect(fetchMe()).rejects.toMatchObject({ code: 'unknown' });
    getMock.mockRejectedValueOnce(new TypeError('offline'));
    await expect(fetchMe()).rejects.toMatchObject({ code: 'network' });
  });

  it('only admins may use the website', () => {
    expect(canUseAdmin(orgAdmin)).toBe(true);
    expect(canUseAdmin(customer)).toBe(false);
    expect(canUseAdmin({ ...customer, is_platform_admin: true })).toBe(true);
    expect(
      canUseAdmin({
        ...customer,
        memberships: [{ ...orgAdmin.memberships[0], role: 'worker' }],
      }),
    ).toBe(false);
  });
});

describe('log in', () => {
  it('signed out: the home page sends you to log in', async () => {
    renderAt('/');
    expect(await screen.findByRole('heading', { name: 'Log in' })).toBeInTheDocument();
  });

  it('checks fields before sending anything', async () => {
    renderAt('/login');
    await screen.findByRole('heading', { name: 'Log in' });
    await userEvent.click(screen.getByRole('button', { name: 'Log in' }));
    expect(screen.getByText('Enter Email.')).toBeInTheDocument();
    expect(screen.getByText('Enter Password.')).toBeInTheDocument();
    expect(postMock).not.toHaveBeenCalled();
  });

  it('wrong details show one message for both', async () => {
    postHandler = () => answer(401, problem(401, 'auth.invalid_credentials'));
    renderAt('/login');
    await screen.findByRole('heading', { name: 'Log in' });
    await logIn('ravi@example.com', 'wrong');
    expect(await screen.findByRole('alert')).toHaveTextContent('Email or password is wrong.');
  });

  it('logs in as web, then shows the account', async () => {
    postHandler = (path, body) => {
      expect(path).toBe('/auth/login');
      expect(body).toEqual({ email: 'ravi@example.com', password: 'secret', client: 'web' });
      signedIn = orgAdmin;
      return answer(200, { user: orgAdmin });
    };
    renderAt('/login');
    await screen.findByRole('heading', { name: 'Log in' });
    await logIn(' ravi@example.com ', 'secret');
    expect(await screen.findByRole('heading', { name: 'Hello, Ravi Admin' })).toBeInTheDocument();
    expect(screen.getByText('Example Solar (illustrative)')).toBeInTheDocument();
    expect(screen.getByText('Pending approval')).toBeInTheDocument();
  });

  it('returns to the page that asked for log in, never off-site', async () => {
    postHandler = () => {
      signedIn = orgAdmin;
      return answer(200, { user: orgAdmin });
    };
    const router = renderAt('/login?next=%2F%2Fevil.example');
    await screen.findByRole('heading', { name: 'Log in' });
    await logIn('ravi@example.com', 'secret');
    await screen.findByRole('heading', { name: 'Hello, Ravi Admin' });
    expect(router.state.location.pathname).toBe('/');
  });

  it('people without an admin role are pointed to the app', async () => {
    signedIn = customer;
    renderAt('/');
    expect(await screen.findByText('This website is for solar vendors')).toBeInTheDocument();
    expect(screen.queryByText('Your companies')).not.toBeInTheDocument();
  });

  it('signed in: the log in page sends you home', async () => {
    signedIn = orgAdmin;
    const router = renderAt('/login');
    await screen.findByRole('heading', { name: 'Hello, Ravi Admin' });
    expect(router.state.location.pathname).toBe('/');
  });

  it('log out returns to log in, even offline', async () => {
    signedIn = orgAdmin;
    postHandler = () => {
      signedIn = null;
      throw new TypeError('offline');
    };
    renderAt('/');
    await userEvent.click(await screen.findByRole('button', { name: 'Log out' }));
    expect(await screen.findByRole('heading', { name: 'Log in' })).toBeInTheDocument();
  });

  it('a server outage shows a retry, not the log in page', async () => {
    getMock.mockResolvedValue(answer(503, {}));
    renderAt('/');
    expect(await screen.findByRole('alert')).toHaveTextContent("Can't reach the server");
  });
});

describe('password reset', () => {
  it('forgot, then reset, then log in with a message', async () => {
    const calls: string[] = [];
    postHandler = (path, body) => {
      calls.push(path);
      if (path === '/auth/password/reset') {
        expect(body).toEqual({
          email: 'ravi@example.com',
          code: '482913',
          new_password: 'new password',
        });
      }
      return answer(path === '/auth/password/forgot' ? 202 : 204);
    };
    renderAt('/forgot?email=ravi%40example.com');
    await userEvent.click(await screen.findByRole('button', { name: 'Send code' }));
    await screen.findByRole('heading', { name: 'New password' });
    await userEvent.type(screen.getByLabelText('6-digit code'), '48a2913');
    await userEvent.type(screen.getByLabelText('New password'), 'new password');
    await userEvent.click(screen.getByRole('button', { name: 'Save password' }));
    expect(
      await screen.findByText('Password changed. Log in with your new password.'),
    ).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toHaveValue('ravi@example.com');
    expect(calls).toEqual(['/auth/password/forgot', '/auth/password/reset']);
  });

  it('a wrong code says so', async () => {
    postHandler = () => answer(400, problem(400, 'auth.code_invalid'));
    renderAt('/reset?email=ravi%40example.com');
    await userEvent.type(await screen.findByLabelText('6-digit code'), '111111');
    await userEvent.type(screen.getByLabelText('New password'), 'new password');
    await userEvent.click(screen.getByRole('button', { name: 'Save password' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('That code is wrong.');
  });

  it('the reset page needs an email', async () => {
    const router = renderAt('/reset');
    await screen.findByRole('heading', { name: 'Reset password' });
    expect(router.state.location.pathname).toBe('/forgot');
  });
});
