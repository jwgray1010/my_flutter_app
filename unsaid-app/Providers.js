import React from 'react';
import { MessageSettingsProvider } from './context/MessageSettingsContext';

export default function Providers({ children }) {
  return (
    <MessageSettingsProvider>
      {children}
    </MessageSettingsProvider>
  );
}