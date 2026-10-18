/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// In development, /api/v1 goes to the Prism mock (`make mock`), or to a local
// backend when MOCK_API is set to its URL.
const apiTarget = process.env.MOCK_API ?? 'http://localhost:4010';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api/v1': {
        target: apiTarget,
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
