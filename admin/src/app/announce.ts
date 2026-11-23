import { createContext, useContext } from 'react';

export const AnnounceContext = createContext<(message: string) => void>(() => {});

/** Says, on screen and to screen readers, that something worked. */
export const useAnnounce = () => useContext(AnnounceContext);
