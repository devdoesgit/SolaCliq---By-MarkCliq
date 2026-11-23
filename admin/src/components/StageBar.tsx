/** The install's stages as segments: done, this one, still to come. */
export function StageBar({
  index,
  count,
  finished = false,
}: {
  index: number;
  count: number;
  finished?: boolean;
}) {
  return (
    <span
      className="stage-bar"
      role="img"
      aria-label={finished ? `All ${count} stages done` : `Stage ${index} of ${count}`}
    >
      {Array.from({ length: count }, (_, i) => (
        <span
          key={i}
          className={
            finished || i + 1 < index ? 'seg seg-done' : i + 1 === index ? 'seg seg-now' : 'seg'
          }
        />
      ))}
    </span>
  );
}
