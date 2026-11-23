import { useQueryClient } from '@tanstack/react-query';
import { useRef, useState, type FormEvent } from 'react';
import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { ApiProblem, unwrap } from '../../api/problem';
import type { Stage } from '../../api/types';
import { useAnnounce } from '../../app/announce';
import { useStages } from '../../app/data';
import { useOrg } from '../../app/org';
import { Button, Notice, PageHeader, QueryState, TextField, type Errors } from '../../components';
import { LineList } from '../tasks/LineList';

const FORM = 'stage-template';

/*
  F19: the company's 7 stages, one open at a time (the Settings artboard)
  ----------------------------------------------------------------------
  - the open stage is in the address (`?stage=3`), so Back works
  - saving replaces that stage's name, checklist and photos. Tasks
    already made keep theirs; new ones fill from it
*/
export function StagesPage() {
  const { orgId, to } = useOrg();
  const stages = useStages(orgId);
  const [params] = useSearchParams();
  const index = Math.min(7, Math.max(1, Number(params.get('stage')) || 1));

  return (
    <>
      <PageHeader
        title="Stage templates"
        meta={
          <>
            <Link to={to('settings')}>Settings</Link> · the 7 install stages
          </>
        }
        actions={
          <Button type="submit" form={FORM} variant="primary" compact icon="check">
            Save template
          </Button>
        }
      />
      <QueryState query={stages}>
        {(list) => (
          <div className="stages-edit">
            <nav className="card stages-card" aria-label="Stages">
              <h2 className="eyebrow">Stages</h2>
              <ol className="stage-list stage-pick">
                {list.map((s) => (
                  <li key={s.index}>
                    <Link
                      to={`${to('settings/stages')}?stage=${s.index}`}
                      aria-current={s.index === index ? 'true' : undefined}
                      replace
                    >
                      <span className="stage-number">{s.index}</span>
                      {s.name}
                    </Link>
                  </li>
                ))}
              </ol>
            </nav>
            {/* Keyed by the saved stage, so a save or another stage starts clean. */}
            <StageForm key={JSON.stringify(list[index - 1])} stage={list[index - 1]} />
          </div>
        )}
      </QueryState>
    </>
  );
}

function StageForm({ stage }: { stage: Stage }) {
  const { orgId } = useOrg();
  const client = useQueryClient();
  const announce = useAnnounce();
  const [name, setName] = useState(stage.name);
  const [checks, setChecks] = useState(stage.checklist);
  const [photos, setPhotos] = useState(stage.photos);
  const [errors, setErrors] = useState<Errors>({});
  const [problem, setProblem] = useState<ApiProblem | null>(null);
  const [busy, setBusy] = useState(false);
  const sending = useRef(false);

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (sending.current) return;
    const found: Errors = { name: name.trim() ? undefined : 'Give the stage a name.' };
    setErrors(found);
    setProblem(null);
    if (found.name) return;
    sending.current = true;
    setBusy(true);
    try {
      await unwrap(
        api.PUT('/orgs/{org_id}/admin/stages/{index}', {
          params: { path: { org_id: orgId, index: stage.index } },
          body: { name: name.trim(), checklist: checks, photos },
        }),
      );
      // Stage names show everywhere: every list reads them again.
      void client.invalidateQueries({ queryKey: ['org', orgId] });
      announce(`Stage ${stage.index} saved. New tasks at this stage use it.`);
    } catch (error) {
      const failed =
        error instanceof ApiProblem
          ? error
          : new ApiProblem(0, 'unknown', 'Something went wrong. Try again.');
      setProblem(failed);
      setErrors(failed.fields);
    } finally {
      sending.current = false;
      setBusy(false);
    }
  }

  return (
    <form
      id={FORM}
      className="card form stage-form"
      aria-label={`Stage ${stage.index}`}
      onSubmit={(event) => void save(event)}
      noValidate
    >
      <div className="card-head">
        <h2 className="card-title">
          Stage {stage.index} · {stage.name}
        </h2>
        <span className="cell-sub">Used when you create a task for this stage</span>
      </div>
      {problem && (
        <Notice
          tone="danger"
          announce
          title={problem.message}
          body={Object.values(problem.fields).join(' ')}
        />
      )}
      <TextField
        label="Name"
        required
        maxLength={40}
        value={name}
        error={errors.name}
        help="Shown to your team and customers wherever this stage is named."
        onChange={(e) => setName(e.target.value)}
      />
      <LineList
        title="Photos the installer must add"
        item="Photo"
        icon="camera"
        chips
        max={60}
        lines={photos}
        error={errors.photos}
        onChange={setPhotos}
      />
      <LineList
        title="Checklist"
        item="Item"
        icon="tasks"
        max={120}
        lines={checks}
        error={errors.checklist}
        onChange={setChecks}
      />
      {busy && (
        <p className="cell-sub" role="status">
          Saving…
        </p>
      )}
    </form>
  );
}
