import { useState } from 'react';
import type { ApiFile } from '../api/types';

function size(bytes: number): string {
  return bytes >= 1024 * 1024
    ? `${(bytes / (1024 * 1024)).toFixed(1)} MB`
    : `${Math.max(1, Math.round(bytes / 1024))} KB`;
}

/*
  A file someone sent, to open in a new tab
  ----------------------------------------------------------------------
  - any file is taken and the admin judges it, so what can't be drawn
    (a PDF, a damaged photo, something renamed) shows as a file, never
    as a broken image
  - the link works for 15 minutes; screens fetch it again before that,
    and each new link is tried afresh
*/
export function FileView({
  file,
  name,
}: {
  file: Pick<ApiFile, 'url'> & Partial<ApiFile>;
  name: string;
}) {
  // Of this link: a fresh one, or a replaced file, gets its own try.
  const [failed, setFailed] = useState('');
  const unreadable = failed === file.url;
  const pdf = file.content_type === 'application/pdf';
  return (
    <a
      className="file"
      href={file.url}
      target="_blank"
      rel="noopener noreferrer"
      aria-label={`Open ${name} in a new tab`}
    >
      {pdf || unreadable ? (
        <span className="file-plain">
          <span className="card-title">{pdf ? 'PDF' : 'File'}</span>
          <span className="t-body-sm">{pdf ? 'Open to read' : "Can't preview. Open it."}</span>
        </span>
      ) : (
        <img
          src={file.url}
          alt=""
          loading="lazy"
          referrerPolicy="no-referrer"
          onError={() => setFailed(file.url)}
        />
      )}
      <span className="file-foot t-body-sm">
        Open{file.size_bytes !== undefined && ` · ${size(file.size_bytes)}`}
      </span>
    </a>
  );
}
