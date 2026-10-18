import { createBrowserRouter } from 'react-router';
import { SHOW_DEV_TOOLS } from './config';
import { PublicOnly, RequireSession } from './features/auth/guards';
import { AccountPage } from './pages/AccountPage';
import { ForgotPasswordPage } from './pages/ForgotPasswordPage';
import { GalleryPage } from './pages/GalleryPage';
import { LoginPage } from './pages/LoginPage';
import { ResetPasswordPage } from './pages/ResetPasswordPage';

/** Routes. The gallery exists only in development builds. */
export const routes = [
  {
    element: <RequireSession />,
    children: [{ path: '/', element: <AccountPage /> }],
  },
  {
    element: <PublicOnly />,
    children: [
      { path: '/login', element: <LoginPage /> },
      { path: '/forgot', element: <ForgotPasswordPage /> },
      { path: '/reset', element: <ResetPasswordPage /> },
    ],
  },
  ...(SHOW_DEV_TOOLS ? [{ path: '/gallery', element: <GalleryPage /> }] : []),
];

export const router = createBrowserRouter(routes);
