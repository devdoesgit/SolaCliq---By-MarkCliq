import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { AttendanceTap } from '../../api/types';
import { useOrg } from '../../app/org';
import { DataTable, QueryState, Stat, StatusPill, TextField } from '../../components';
import { formatMinutes, formatTime, indiaDay } from '../../lib/format';
import { ATTENDANCE, NOT_STARTED } from '../../lib/labels';
import { PersonName } from './PersonName';

// People start and end while the admin watches.
const FOLLOW_MS = 60 * 1000;

function Tap({ tap }: { tap?: AttendanceTap }) {
  if (!tap) return '–';
  return (
    <span className="cell-main">
      <span className="t-num">{formatTime(tap.at)}</span>
      {tap.sent_late && <span className="cell-sub">sent late</span>}
    </span>
  );
}

export function DayView() {
  const { orgId } = useOrg();
  const [date, setDate] = useState(() => indiaDay());
  const day = useQuery({
    queryKey: ['org', orgId, 'attendance', 'day', date],
    refetchInterval: FOLLOW_MS,
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/attendance/day', {
          params: { path: { org_id: orgId }, query: { date } },
          signal,
        }),
      ),
  });
  return (
    <>
      <div className="toolbar">
        <TextField
          label="Date"
          type="date"
          max={indiaDay()}
          value={date}
          onChange={(e) => e.target.value && setDate(e.target.value)}
        />
      </div>
      {day.data && day.data.people.length > 0 && (
        <div className="stats stats-short">
          <Stat
            dot="sun"
            label="Working"
            value={day.data.people.filter((row) => row.day?.status === 'working').length}
          />
          <Stat
            dot="success"
            label="Day ended"
            value={day.data.people.filter((row) => row.day?.status === 'ended').length}
          />
          <Stat
            dot="quiet"
            label="Not started"
            value={day.data.people.filter((row) => !row.day).length}
          />
        </div>
      )}
      <QueryState query={day}>
        {({ people }) =>
          people.length === 0 ? (
            <p className="empty">Nobody marks attendance yet.</p>
          ) : (
            <DataTable
              caption="Attendance on the day"
              rows={people}
              rowKey={(row) => row.person.user_id}
              columns={[
                { label: 'Person', render: (row) => <PersonName person={row.person} /> },
                {
                  label: 'Status',
                  render: (row) => (
                    <StatusPill {...(row.day ? ATTENDANCE[row.day.status] : NOT_STARTED)} />
                  ),
                },
                { label: 'Start', render: (row) => <Tap tap={row.day?.start} /> },
                { label: 'End', render: (row) => <Tap tap={row.day?.end} /> },
                {
                  label: 'Worked',
                  end: true,
                  render: (row) =>
                    row.day?.minutes == null ? '–' : formatMinutes(row.day.minutes),
                },
              ]}
            />
          )
        }
      </QueryState>
    </>
  );
}
