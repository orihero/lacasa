import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

// Placeholder — proves the vitest + jsdom + @testing-library wiring works
// end to end for this workspace. Replace/extend with real component
// tests as they land.
function Smoke() {
  return <p>ok</p>;
}

describe('apps/web test wiring', () => {
  it('renders with @testing-library/react under jsdom', () => {
    render(<Smoke />);
    expect(screen.getByText('ok')).toBeInTheDocument();
  });
});
