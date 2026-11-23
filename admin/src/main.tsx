import '@fontsource-variable/inter';
import './styles/tokens.css';
import './styles/base.css';
import './styles/screens.css';

import { QueryClientProvider } from '@tanstack/react-query';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { RouterProvider } from 'react-router';
import { createQueryClient } from './app/queryClient';
import { APP_NAME } from './config';
import { router } from './router';

document.title = APP_NAME;

const queryClient = createQueryClient();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
);
