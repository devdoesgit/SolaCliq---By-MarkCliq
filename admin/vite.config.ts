/// <reference types="vitest/config" />
import { readFile } from 'node:fs/promises';
import react from '@vitejs/plugin-react';
import { marked } from 'marked';
import { defineConfig, type Plugin } from 'vite';

/*
  The legal documents (F16): `import html from '../../legal/x.md?html'`
  gives the file as HTML, made when the site is built, so the pages need
  no Markdown code in the browser. Links between the documents
  (`privacy-policy.md`) become the site's paths (`/privacy`).
*/
const LEGAL_PATHS: Record<string, string> = {
  'terms-of-use.md': '/terms',
  'privacy-policy.md': '/privacy',
  'company-terms.md': '/company-terms',
};

function legalMarkdown(): Plugin {
  return {
    name: 'legal-markdown',
    async load(id) {
      if (!id.endsWith('.md?html')) return null;
      const file = id.slice(0, -'?html'.length);
      this.addWatchFile(file);
      const markdown = (await readFile(file, 'utf8')).replace(
        /\]\(([a-z-]+\.md)\)/g,
        (link, name: string) => (LEGAL_PATHS[name] ? `](${LEGAL_PATHS[name]})` : link),
      );
      // A wide table scrolls by itself, so the keyboard must be able to reach it.
      const html = (await marked.parse(markdown)).replaceAll('<table>', '<table tabindex="0">');
      return `export default ${JSON.stringify(html)};`;
    },
  };
}

// In development, /api/v1 goes to the Prism mock (`make mock`), which serves
// the spec's paths without the prefix. Set BACKEND_URL (for example
// http://localhost:8080) to use a local backend instead; it gets the full
// /api/v1/... path, as in production.
const backend = process.env.BACKEND_URL;

export default defineConfig({
  plugins: [react(), legalMarkdown()],
  server: {
    // The legal documents live at the repo root (`legal/`).
    fs: { allow: ['.', '../legal'] },
    proxy: {
      '/api/v1': backend
        ? { target: backend, changeOrigin: true }
        : {
            target: 'http://localhost:4010',
            changeOrigin: true,
            rewrite: (path) => path.replace(/^\/api\/v1/, ''),
          },
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
  },
});
