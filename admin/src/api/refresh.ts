/**
 * Keeps the admin signed in past the 15-minute access cookie (OAuth 2.1
 * refresh, decision 2026-11-11).
 *
 * On a 401 the browser's refresh cookie is traded for new cookies at
 * `/auth/refresh`, then the request is sent once more. The server treats a
 * second refresh with the same cookie as theft and ends the session, so
 * only one runs at a time: in this tab through one promise, across tabs
 * through a lock. A tab that got the lock after another refreshed sees the
 * shared stamp changed and only retries.
 * Auth endpoints (log in, refresh, codes) pass straight through, so a
 * refresh can never loop.
 */
export function withRefresh(
  baseUrl: string,
  baseFetch: (input: Request) => Promise<Response> = (input) => globalThis.fetch(input),
  tabs: Tabs = browserTabs,
): (input: Request) => Promise<Response> {
  let refreshing: Promise<boolean> | null = null;

  const refresh = (stampWhenSent: string | null): Promise<boolean> => {
    refreshing ??= tabs
      .exclusive(async () => {
        if (tabs.stamp() !== stampWhenSent) return true;
        const res = await baseFetch(
          new Request(`${baseUrl}/auth/refresh`, { method: 'POST', credentials: 'include' }),
        );
        // Unread, an uncached body keeps its request open in the browser.
        await res.body?.cancel();
        if (res.ok) tabs.refreshed();
        return res.ok;
      })
      .catch(() => false)
      .finally(() => {
        refreshing = null;
      });
    return refreshing;
  };

  return async (input) => {
    // Kept before sending: a request body can only be read once.
    const retry = input.clone();
    const sentAt = tabs.stamp();
    const response = await baseFetch(input);
    if (response.status !== 401 || isPublicAuthPath(input.url, baseUrl)) return response;
    // A failed refresh means the login is over: the 401 stands and the
    // page shows the login screen.
    if (!(await refresh(sentAt))) return response;
    await response.body?.cancel();
    return baseFetch(retry);
  };
}

/** What the open tabs share. */
export interface Tabs {
  /** Runs `work` while no other tab runs its own. */
  exclusive(work: () => Promise<boolean>): Promise<boolean>;
  /** Changes whenever any tab refreshed. */
  stamp(): string | null;
  refreshed(): void;
}

const NAME = 'solacliq-refresh';

const browserTabs: Tabs = {
  exclusive: async (work) =>
    globalThis.navigator?.locks ? await navigator.locks.request(NAME, () => work()) : await work(),
  stamp() {
    try {
      return localStorage.getItem(NAME);
    } catch {
      return null;
    }
  },
  refreshed() {
    try {
      // Only a random marker: the tokens stay in HttpOnly cookies.
      localStorage.setItem(NAME, `${Date.now()}-${Math.random()}`);
    } catch {
      // Storage is blocked: the lock alone still orders the tabs.
    }
  },
};

function isPublicAuthPath(url: string, baseUrl: string): boolean {
  const path = new URL(url, 'http://local').pathname;
  const base = new URL(baseUrl, 'http://local').pathname.replace(/\/$/, '');
  const rest = path.startsWith(base) ? path.slice(base.length) : path;
  return rest.startsWith('/auth/') && rest !== '/auth/logout';
}
