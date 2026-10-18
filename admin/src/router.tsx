import { createBrowserRouter } from 'react-router';
import { SHOW_DEV_TOOLS } from './config';
import { GalleryPage } from './pages/GalleryPage';
import { HomePage } from './pages/HomePage';

/** Routes. The gallery exists only in development builds. */
export const router = createBrowserRouter([
  { path: '/', element: <HomePage /> },
  ...(SHOW_DEV_TOOLS ? [{ path: '/gallery', element: <GalleryPage /> }] : []),
]);
