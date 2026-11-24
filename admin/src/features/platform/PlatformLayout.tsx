import { Outlet } from 'react-router';
import icon from '../../assets/solacliq-icon.svg';
import { Shell } from '../../app/Shell';
import { NotFoundPage } from '../../pages/NotFoundPage';
import { adminCompanies } from '../../app/org';
import { useMe } from '../auth/session';
import { useWaiting } from './queries';

/*
  MarkCliq's screens (F22), for platform admins only
  ----------------------------------------------------------------------
  - anyone else gets "not found": the pages don't exist for them, and the
    API refuses them anyway (403 platform.not_admin)
  - a platform admin who also runs a company goes back to it from Home
*/
export function PlatformLayout() {
  const { data: me } = useMe();
  const allowed = !!me?.is_platform_admin;
  const waiting = useWaiting(allowed);
  if (!me) return null;
  if (!allowed) return <NotFoundPage />;
  const count = Number(waiting.data?.replace('+', '') ?? 0);
  return (
    <Shell
      me={me}
      mark={icon}
      who={<p className="side-name">MarkCliq</p>}
      nav={[
        { to: '/platform/companies', label: 'Companies', icon: 'projects', count },
        ...(adminCompanies(me).length > 0
          ? [{ to: '/', label: 'Your companies', icon: 'back' as const }]
          : []),
      ]}
      role="MarkCliq"
    >
      <Outlet />
    </Shell>
  );
}
