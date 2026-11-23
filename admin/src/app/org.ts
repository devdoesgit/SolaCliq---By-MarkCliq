import { useOutletContext } from 'react-router';
import type { Me } from '../features/auth/session';

export type Membership = Me['memberships'][number];

export interface OrgScope {
  orgId: string;
  name: string;
  /** A path inside this company: `to('tasks')`. */
  to: (path: string) => string;
}

/** The company whose screens are showing (`CompanyLayout`). */
export const useOrg = () => useOutletContext<OrgScope>();

export const adminCompanies = (me: Me): Membership[] =>
  me.memberships.filter((m) => m.role === 'org_admin');
