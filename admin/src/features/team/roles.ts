import type { Member } from '../../api/types';
import type { IconName } from '../../components';

/** The two roles an admin adds, as the app names them. */
export const ROLE: Record<'worker' | 'agent', { name: string; does: string; icon: IconName }> = {
  worker: {
    name: 'EPC Installer',
    does: 'Gets tasks, uploads proof photos and expenses',
    icon: 'camera',
  },
  agent: {
    name: 'Sales Agent',
    does: 'Adds customers and uploads their documents',
    icon: 'customers',
  },
};

export function roleText(member: Member): string {
  if (member.role === 'org_admin') return 'Admin';
  if (member.role === 'worker') return ROLE.worker.name;
  return member.pay_type === 'salary' ? 'Sales Agent, salary' : 'Sales Agent, commission';
}
