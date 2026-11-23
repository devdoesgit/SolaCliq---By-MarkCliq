import { useMutation, useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { AttendanceDay } from '../../api/types';
import { useOrg } from '../../app/org';
import { Button, Notice, QueryState, SelectField } from '../../components';
import { formatDay, formatMinutes, formatMonth, formatTime, indiaDay } from '../../lib/format';
import { ATTENDANCE } from '../../lib/labels';
import { PersonName } from './PersonName';

// A select, not type="month": Firefox has no picker for that, and a
// half-typed month can't be kept in any browser.
const MONTHS_BACK = 24;

/** This month and the ones before, newest first. */
function recentMonths(): string[] {
  const [year, number] = indiaDay().split('-').map(Number);
  return Array.from({ length: MONTHS_BACK }, (_, i) =>
    new Date(Date.UTC(year, number - 1 - i, 1)).toISOString().slice(0, 7),
  );
}

/** The month's dates: `2026-12-01` to `2026-12-31`. */
function datesOf(month: string): string[] {
  const [year, number] = month.split('-').map(Number);
  const last = new Date(Date.UTC(year, number, 0)).getUTCDate();
  return Array.from({ length: last }, (_, i) => `${month}-${String(i + 1).padStart(2, '0')}`);
}

function Cell({ date, day }: { date: string; day?: AttendanceDay }) {
  if (!day) return <td />;
  const mark = { ended: '✓', working: '•', no_check_out: '!' }[day.status];
  const late = day.start.sent_late || day.end?.sent_late;
  const said = [
    formatDay(date),
    ATTENDANCE[day.status].label,
    day.end
      ? `${formatTime(day.start.at)} to ${formatTime(day.end.at)}`
      : `from ${formatTime(day.start.at)}`,
    late && 'sent late',
  ]
    .filter(Boolean)
    .join(', ');
  return (
    <td className={`month-${day.status}`} title={said}>
      <span aria-hidden="true">{mark}</span>
      <span className="visually-hidden">{said}</span>
    </td>
  );
}

export function MonthView() {
  const { orgId } = useOrg();
  const [month, setMonth] = useState(() => indiaDay().slice(0, 7));
  const params = { path: { org_id: orgId }, query: { month } };
  const view = useQuery({
    queryKey: ['org', orgId, 'attendance', 'month', month],
    queryFn: ({ signal }) => unwrap(api.GET('/orgs/{org_id}/attendance/month', { params, signal })),
  });
  // Through the client, so an expired session refreshes instead of saving an error as a file.
  const csv = useMutation({
    mutationFn: async () => {
      const text = await unwrap(
        api.GET('/orgs/{org_id}/attendance/month.csv', { params, parseAs: 'text' }),
      );
      // The mark makes Excel read names in Indian scripts as UTF-8.
      const url = URL.createObjectURL(new Blob(['﻿', text], { type: 'text/csv' }));
      const link = document.createElement('a');
      link.href = url;
      link.download = `attendance-${month}.csv`;
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    },
  });
  const dates = datesOf(month);
  return (
    <>
      <div className="toolbar">
        <SelectField label="Month" value={month} onChange={(e) => setMonth(e.target.value)}>
          {recentMonths().map((value) => (
            <option key={value} value={value}>
              {formatMonth(value)}
            </option>
          ))}
        </SelectField>
        <Button disabled={csv.isPending} onClick={() => csv.mutate()}>
          Download CSV
        </Button>
      </div>
      {csv.error && <Notice tone="danger" announce title="Couldn't download it. Try again." />}
      <QueryState query={view}>
        {({ people }) =>
          people.length === 0 ? (
            <p className="empty">Nobody marks attendance yet.</p>
          ) : (
            <>
              {/* Focusable, so the keyboard can scroll it sideways. */}
              <div className="month-scroll" role="region" aria-label="The month" tabIndex={0}>
                <table className="month">
                  <caption className="visually-hidden">Attendance in the month</caption>
                  <thead>
                    <tr>
                      <th scope="col">Person</th>
                      {dates.map((date) => (
                        <th key={date} scope="col">
                          {Number(date.slice(-2))}
                        </th>
                      ))}
                      <th scope="col">Days</th>
                      <th scope="col">Hours</th>
                    </tr>
                  </thead>
                  <tbody>
                    {people.map(({ person, days, days_worked, minutes }) => (
                      <tr key={person.user_id}>
                        <th scope="row">
                          <PersonName person={person} />
                        </th>
                        {dates.map((date) => (
                          <Cell key={date} date={date} day={days.find((d) => d.date === date)} />
                        ))}
                        <td>{days_worked}</td>
                        <td>{formatMinutes(minutes)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <p className="t-body-sm muted">✓ worked · • working now · ! no check-out</p>
            </>
          )
        }
      </QueryState>
    </>
  );
}
