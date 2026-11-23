/** A position, as sent, that opens on a map. Nothing is judged from it. */
export function MapLink({ lat, lng }: { lat?: number; lng?: number }) {
  if (lat === undefined || lng === undefined) return null;
  return (
    <a
      href={`https://www.google.com/maps/search/?api=1&query=${lat},${lng}`}
      target="_blank"
      rel="noopener noreferrer"
    >
      {lat.toFixed(5)}, {lng.toFixed(5)}
    </a>
  );
}
