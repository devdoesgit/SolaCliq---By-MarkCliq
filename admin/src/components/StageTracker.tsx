import { formatDate } from '../lib/format';

export type StageState = 'done' | 'current' | 'upcoming';

export interface Stage {
  name: string;
  state: StageState;
  date?: Date;
}

const STATE_WORD: Record<StageState, string> = {
  done: 'done',
  current: 'current',
  upcoming: 'not started',
};

/** The numbered list of install stages, with the current one highlighted. */
export function StageTracker({ stages }: { stages: Stage[] }) {
  return (
    <ol className="sc-stages">
      {stages.map((stage, i) => (
        <li
          key={stage.name}
          className={`sc-stage sc-stage-${stage.state}`}
          aria-current={stage.state === 'current' ? 'step' : undefined}
        >
          <span className="sc-stage-n t-label" aria-hidden="true">
            {String(i + 1).padStart(2, '0')}
          </span>
          <span>
            {stage.name}
            <span className="visually-hidden">, {STATE_WORD[stage.state]}</span>
          </span>
          {stage.date && (
            <time className="sc-stage-date t-label" dateTime={stage.date.toISOString()}>
              {formatDate(stage.date)}
            </time>
          )}
        </li>
      ))}
    </ol>
  );
}
