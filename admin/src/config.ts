/**
 * App-wide settings. The product name is a working name that may change;
 * this is the only place the admin website holds it.
 */
export const APP_NAME = 'SolaCliq';

/**
 * Base URL of the API, including `/api/v1`. Same origin in production
 * (solacliq.markcliq.com/api/v1); in development Vite proxies it to the
 * Prism mock (see vite.config.ts).
 */
export const API_BASE_URL: string = import.meta.env.VITE_API_BASE_URL ?? '/api/v1';

/** Development-only tools, such as the component gallery. */
export const SHOW_DEV_TOOLS = import.meta.env.DEV;
