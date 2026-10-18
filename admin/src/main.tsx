import '@fontsource-variable/space-grotesk';
import '@fontsource/space-mono/400.css';
import '@fontsource/space-mono/700.css';
import './styles/tokens.css';
import './styles/base.css';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { RouterProvider } from 'react-router';
import { APP_NAME } from './config';
import { router } from './router';

document.title = APP_NAME;

const queryClient = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false } },
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
);
