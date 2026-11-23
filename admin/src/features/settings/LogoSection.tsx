import { useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { api } from '../../api/client';
import { ApiProblem, unwrap } from '../../api/problem';
import { useOrg } from '../../app/org';
import { ActionDialog, DialogButton, Section, TextField } from '../../components';
import { meQueryKey, useMe } from '../auth/session';

// The server's limit (`uploads.rs`).
const MAX_BYTES = 1024 * 1024;

type LogoType = 'image/png' | 'image/jpeg';

/** W6 (F15): the logo the company's people see. */
export function LogoSection() {
  const { orgId, name } = useOrg();
  const { data: me } = useMe();
  const logo = me?.memberships.find((m) => m.org.id === orgId)?.org.logo_url;
  return (
    <Section
      title="Logo"
      actions={
        <>
          {logo && (
            <DialogButton
              key="remove-logo"
              label="Remove"
              compact
              dialog={(close) => <RemoveDialog onClose={close} />}
            />
          )}
          <DialogButton
            key={logo ? 'change-logo' : 'add-logo'}
            label={logo ? 'Change logo' : 'Add logo'}
            compact
            dialog={(close) => <UploadDialog onClose={close} />}
          />
        </>
      }
    >
      {logo ? (
        <img className="logo-preview" src={logo} alt={`${name}'s logo`} />
      ) : (
        <p className="empty">No logo. Your people see the company's initials.</p>
      )}
    </Section>
  );
}

function UploadDialog({ onClose }: { onClose: () => void }) {
  const { orgId } = useOrg();
  const client = useQueryClient();
  const [file, setFile] = useState<File>();

  /*
    Three steps
    --------------------------------------------------------------------
    - the API signs a link, the file goes straight to R2, then the
      company is pointed at it. A failure leaves the old logo in place
  */
  async function send() {
    if (!file) return;
    const path = { org_id: orgId };
    const upload = await unwrap(
      api.POST('/orgs/{org_id}/uploads', {
        params: { path },
        body: { content_type: file.type as LogoType, size_bytes: file.size, purpose: 'logo' },
      }),
    );
    // The browser sets Content-Length itself and refuses to be told it.
    const headers = Object.fromEntries(
      Object.entries(upload.headers).filter(([key]) => key.toLowerCase() !== 'content-length'),
    );
    let stored: Response;
    try {
      stored = await fetch(upload.url, { method: upload.method, headers, body: file });
    } catch {
      throw new ApiProblem(0, 'network', "The image didn't upload. Try again.");
    }
    if (!stored.ok) {
      throw new ApiProblem(stored.status, 'upload.failed', "The image didn't upload. Try again.");
    }
    await unwrap(
      api.PUT('/orgs/{org_id}/logo', { params: { path }, body: { upload_id: upload.upload_id } }),
    );
    await client.invalidateQueries({ queryKey: meQueryKey });
  }

  return (
    <ActionDialog
      title="Your company's logo"
      body="Your team and customers see it in the app. A square image reads best at small sizes."
      confirm="Save"
      done="Logo saved."
      onClose={onClose}
      validate={() => ({
        file: !file
          ? 'Choose an image.'
          : !['image/png', 'image/jpeg'].includes(file.type)
            ? 'A logo is a PNG or JPEG image.'
            : file.size > MAX_BYTES
              ? 'A logo is up to 1 MB.'
              : undefined,
      })}
      run={send}
    >
      {(errors) => (
        <TextField
          label="Image"
          type="file"
          accept="image/png,image/jpeg"
          error={errors.file}
          help="PNG or JPEG, up to 1 MB."
          onChange={(e) => setFile(e.target.files?.[0])}
        />
      )}
    </ActionDialog>
  );
}

function RemoveDialog({ onClose }: { onClose: () => void }) {
  const { orgId } = useOrg();
  const client = useQueryClient();
  return (
    <ActionDialog
      title="Remove the logo?"
      body="The app shows the company's initials instead."
      danger
      confirm="Remove"
      done="Logo removed."
      onClose={onClose}
      run={async () => {
        await unwrap(api.DELETE('/orgs/{org_id}/logo', { params: { path: { org_id: orgId } } }));
        await client.invalidateQueries({ queryKey: meQueryKey });
      }}
    />
  );
}
