import { Link } from 'react-router';
import { Notice } from '../components';

export function NotFoundPage() {
  return (
    <div className="page stack-lg">
      <h1 className="t-display">Page not found</h1>
      <Notice title="There's nothing at this address" />
      <Link to="/">Go to the start</Link>
    </div>
  );
}
