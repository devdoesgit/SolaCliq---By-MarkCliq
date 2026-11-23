import { useSearchParams } from 'react-router';
import { Filters, PageHeader, readFilter } from '../../components';
import { DayView } from './DayView';
import { MonthView } from './MonthView';

const VIEWS: { value: 'day' | 'month' | ''; label: string }[] = [
  { value: 'day', label: 'Today' },
  { value: 'month', label: 'Month' },
];

/** W6 (F17): who is working, and each month's days. Read only. */
export function AttendancePage() {
  const [params] = useSearchParams();
  const view = readFilter(params.get('view'), VIEWS, 'day');
  return (
    <>
      <PageHeader title="Attendance" meta="Installers and salaried sales mark their own day" />
      <Filters name="view" label="View" options={VIEWS} value={view} />
      {view === 'month' ? <MonthView /> : <DayView />}
    </>
  );
}
