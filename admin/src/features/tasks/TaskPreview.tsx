import { Avatar, Icon, StageBar } from '../../components';
import { formatWhen } from '../../lib/format';

/*
  What the installer will see, as it's typed
  ----------------------------------------------------------------------
  - a picture of the app's task screen, not a working one: hidden from
    screen readers, who hear the form itself
*/
export function TaskPreview({
  installer,
  title,
  stage,
  stages,
  due,
  customer,
  place,
  note,
  from,
  photos,
  checks,
}: {
  installer?: string;
  title: string;
  stage: number;
  stages: number;
  /** An ISO instant, once chosen. */
  due?: string;
  customer: string;
  place?: string;
  note: string;
  from: string;
  photos: string[];
  checks: string[];
}) {
  return (
    <aside className="preview" aria-hidden="true">
      <p className="eyebrow preview-title">
        What {installer ? installer.split(/\s+/)[0] : 'the installer'} sees
      </p>
      <div className="phone">
        <div className="phone-island" />
        <div className="phone-bar">
          <span className="phone-round">
            <Icon name="back" size={14} />
          </span>
          <span>Task</span>
        </div>
        <div className="phone-card">
          <div className="phone-line">
            <span className="eyebrow">
              Stage {stage} of {stages}
            </span>
            <span className="sc-pill sc-tone-accent">Assigned</span>
          </div>
          <p className="phone-task">{title || 'Task title'}</p>
          <p className="phone-sub">{due ? `Due ${formatWhen(due)}` : 'Due: not chosen yet'}</p>
          <StageBar index={stage} count={stages} />
          <div className="phone-customer">
            <Avatar name={customer} size="sm" />
            <span className="cell-main">
              <span className="phone-name">{customer}</span>
              {place && <span className="phone-sub">{place}</span>}
            </span>
            <span className="phone-round phone-go">
              <Icon name="navigate" size={13} />
            </span>
          </div>
        </div>
        {note && (
          <div className="phone-note">
            <span className="phone-note-title">Note from admin</span>
            <p>{note}</p>
            <span className="phone-sub">{from} · Admin</span>
          </div>
        )}
        {checks.length > 0 && (
          <>
            <p className="phone-heading">Checklist</p>
            <ul className="phone-card phone-checks">
              {checks.map((check, i) => (
                <li key={i}>
                  <span className="tick" />
                  {check}
                </li>
              ))}
            </ul>
          </>
        )}
        <span className="phone-action">
          <Icon name="camera" size={14} />
          {photos.length === 0
            ? 'Submit'
            : `Add ${photos.length} ${photos.length === 1 ? 'photo' : 'photos'}`}
        </span>
      </div>
    </aside>
  );
}
