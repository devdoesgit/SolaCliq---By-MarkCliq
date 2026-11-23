import { useQueryClient } from '@tanstack/react-query';
import { useRef, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router';
import { api } from '../../api/client';
import { ApiProblem, unwrap } from '../../api/problem';
import { useAnnounce } from '../../app/announce';
import { useOrg } from '../../app/org';
import {
  Button,
  Icon,
  Notice,
  PageHeader,
  SelectField,
  TextField,
  type Errors,
} from '../../components';
import { validateEmail } from '../auth/validators';
import { ROLE } from './roles';

type Role = keyof typeof ROLE;
type PayType = 'commission' | 'salary';

const FORM = 'add-member';

/** W1 (F3): invite an installer or an agent. */
export function AddMemberPage() {
  const { orgId, to } = useOrg();
  const navigate = useNavigate();
  const announce = useAnnounce();
  const client = useQueryClient();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<Role | ''>('');
  const [pay, setPay] = useState<PayType | ''>('');
  const [errors, setErrors] = useState<Errors>({});
  const [problem, setProblem] = useState<ApiProblem | null>(null);
  const [busy, setBusy] = useState(false);
  const sending = useRef(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (sending.current) return;
    const found: Errors = {
      name: name.trim() ? undefined : 'Enter their name.',
      email: validateEmail(email),
      role: role ? undefined : 'Choose a role.',
      pay_type: role === 'agent' && !pay ? 'Choose how this agent is paid.' : undefined,
    };
    setErrors(found);
    setProblem(null);
    if (Object.values(found).some(Boolean)) return;
    sending.current = true;
    setBusy(true);
    try {
      await unwrap(
        api.POST('/orgs/{org_id}/members', {
          params: { path: { org_id: orgId } },
          body: {
            name: name.trim(),
            email: email.trim(),
            role: role as Role,
            pay_type: role === 'agent' ? (pay as PayType) : undefined,
          },
        }),
      );
      void client.invalidateQueries({ queryKey: ['org', orgId] });
      announce('Added. We emailed them how to get started.');
      void navigate(to('team'), { replace: true });
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
    <>
      <PageHeader
        title="Add team member"
        meta="Team / Add"
        actions={
          <>
            <Link className="sc-btn sc-btn-outline sc-btn-compact" to={to('team')}>
              <span>Cancel</span>
            </Link>
            <Button
              type="submit"
              form={FORM}
              variant="primary"
              compact
              icon="check"
              disabled={busy}
            >
              Send invite
            </Button>
          </>
        }
      />
      <form id={FORM} className="card form form-narrow" onSubmit={(e) => void submit(e)} noValidate>
        {problem && (
          <Notice
            tone="danger"
            announce
            title={problem.message}
            body={Object.values(problem.fields).join(' ')}
          />
        )}
        <div className="form-grid">
          <TextField
            label="Email"
            type="email"
            autoComplete="off"
            value={email}
            error={errors.email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextField
            label="Name"
            maxLength={100}
            value={name}
            error={errors.name}
            onChange={(e) => setName(e.target.value)}
          />
        </div>
        <fieldset className="lines">
          <legend className="field-label">Role</legend>
          <div className="form-grid">
            {(Object.keys(ROLE) as Role[]).map((value) => (
              <label key={value} className="role role-pick">
                <input
                  type="radio"
                  name="role"
                  className="visually-hidden"
                  aria-label={ROLE[value].name}
                  checked={role === value}
                  onChange={() => setRole(value)}
                />
                <span className="row-icon">
                  <Icon name={ROLE[value].icon} size={17} />
                </span>
                <span className="cell-main">
                  <span className="row-title">{ROLE[value].name}</span>
                  <span className="cell-sub">{ROLE[value].does}</span>
                </span>
              </label>
            ))}
          </div>
          {errors.role && (
            <p className="sc-field-error t-body-sm" role="alert">
              {errors.role}
            </p>
          )}
        </fieldset>
        {role === 'agent' && (
          <SelectField
            label="Paid by"
            value={pay}
            error={errors.pay_type}
            onChange={(e) => setPay(e.target.value as PayType | '')}
          >
            <option value="">Choose</option>
            <option value="commission">Commission</option>
            <option value="salary">Salary</option>
          </SelectField>
        )}
        <p className="info">
          <Icon name="info" size={15} />
          We email them how to set up the app. They set their own password with a code.
        </p>
      </form>
    </>
  );
}
