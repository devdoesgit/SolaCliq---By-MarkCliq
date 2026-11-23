import { describe, expect, it, vi } from 'vitest';
import { withRefresh, type Tabs } from './refresh';

const BASE = 'http://api.test/api/v1';

/** A fake server: `/me` is 401 until a refresh has happened. */
function server({ refreshOk = true } = {}) {
  let refreshed = false;
  const calls: string[] = [];
  const fetch = vi.fn(async (req: Request) => {
    const path = new URL(req.url).pathname.replace('/api/v1', '');
    calls.push(`${req.method} ${path}`);
    if (path === '/auth/refresh') {
      refreshed = refreshOk;
      return new Response(null, { status: refreshOk ? 204 : 401 });
    }
    if (path === '/auth/login') return new Response(null, { status: 401 });
    return new Response(null, { status: refreshed ? 200 : 401 });
  });
  return { fetch, calls };
}

const get = (path: string) => new Request(`${BASE}${path}`);

describe('withRefresh', () => {
  it('refreshes on a 401 and retries the request once', async () => {
    const s = server();
    const res = await withRefresh(BASE, s.fetch)(get('/me'));
    expect(res.status).toBe(200);
    expect(s.calls).toEqual(['GET /me', 'POST /auth/refresh', 'GET /me']);
  });

  it('keeps the 401 when the refresh is refused', async () => {
    const s = server({ refreshOk: false });
    const res = await withRefresh(BASE, s.fetch)(get('/me'));
    expect(res.status).toBe(401);
    expect(s.calls).toEqual(['GET /me', 'POST /auth/refresh']);
  });

  it('runs one refresh for parallel 401s', async () => {
    const s = server();
    const send = withRefresh(BASE, s.fetch);
    const results = await Promise.all([send(get('/me')), send(get('/orgs')), send(get('/me'))]);
    expect(results.map((r) => r.status)).toEqual([200, 200, 200]);
    expect(s.calls.filter((c) => c === 'POST /auth/refresh')).toHaveLength(1);
  });

  it('never refreshes for log in or refresh themselves', async () => {
    const s = server();
    const login = new Request(`${BASE}/auth/login`, { method: 'POST', body: '{}' });
    expect((await withRefresh(BASE, s.fetch)(login)).status).toBe(401);
    expect(s.calls).toEqual(['POST /auth/login']);
  });

  it('resends the body on the retry', async () => {
    const bodies: string[] = [];
    let refreshed = false;
    const fetch = async (req: Request) => {
      if (req.url.endsWith('/auth/refresh')) {
        refreshed = true;
        return new Response(null, { status: 204 });
      }
      bodies.push(await req.text());
      return new Response(null, { status: refreshed ? 200 : 401 });
    };
    const req = new Request(`${BASE}/orgs`, { method: 'POST', body: '{"name":"x"}' });
    expect((await withRefresh(BASE, fetch)(req)).status).toBe(200);
    expect(bodies).toEqual(['{"name":"x"}', '{"name":"x"}']);
  });

  /*
    A9: a second refresh with the same cookie ends the session, so two
    tabs must send one
  */
  it('two tabs with a 401 at once send one refresh', async () => {
    let refreshes = 0;
    let fresh = false;
    const fetch = async (req: Request) => {
      if (req.url.endsWith('/auth/refresh')) {
        refreshes++;
        await new Promise((done) => setTimeout(done, 5));
        if (refreshes > 1) return new Response(null, { status: 401 });
        fresh = true;
        return new Response(null, { status: 204 });
      }
      return new Response(null, { status: fresh ? 200 : 401 });
    };
    let queue: Promise<unknown> = Promise.resolve();
    let stamp = 0;
    const tabs: Tabs = {
      exclusive(work) {
        const result = queue.then(work);
        queue = result;
        return result;
      },
      stamp: () => String(stamp),
      refreshed: () => {
        stamp++;
      },
    };
    const one = withRefresh(BASE, fetch, tabs);
    const two = withRefresh(BASE, fetch, tabs);
    const results = await Promise.all([one(get('/me')), two(get('/me'))]);
    expect(results.map((r) => r.status)).toEqual([200, 200]);
    expect(refreshes).toBe(1);
  });
});

describe('bodies nobody reads', () => {
  it("the refresh's and the retried 401's are closed, not left open", async () => {
    const closed: string[] = [];
    const body = (name: string) => new ReadableStream({ cancel: () => void closed.push(name) });
    let calls = 0;
    const send = withRefresh(
      'http://local/api/v1',
      async (input) => {
        calls++;
        if (input.url.endsWith('/auth/refresh'))
          return new Response(body('refresh'), { status: 200 });
        return calls === 1 ? new Response(body('first'), { status: 401 }) : new Response('ok');
      },
      { exclusive: (work) => work(), stamp: () => null, refreshed: () => {} },
    );
    expect((await send(new Request('http://local/api/v1/me'))).status).toBe(200);
    expect(closed).toEqual(['refresh', 'first']);
  });
});
