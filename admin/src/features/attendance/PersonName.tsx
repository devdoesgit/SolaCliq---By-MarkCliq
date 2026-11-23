import { Person } from '../../components';
import type { AttendancePerson } from '../../api/types';

const ROLE: Partial<Record<AttendancePerson['role'], string>> = {
  worker: 'Installer',
  agent: 'Sales',
};

export function PersonName({ person: p }: { person: AttendancePerson }) {
  const sub = [ROLE[p.role], p.removed && 'removed'].filter(Boolean).join(', ');
  return <Person name={p.name} sub={sub || undefined} />;
}
