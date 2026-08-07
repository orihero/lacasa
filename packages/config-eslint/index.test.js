import { createRequire } from 'node:module';
import { describe, expect, it } from 'vitest';

const require = createRequire(import.meta.url);

describe('@lacasa/config-eslint', () => {
  it('index.cjs is a loadable base config with a TypeScript override', () => {
    const base = require('./index.cjs');
    expect(base.extends).toContain('eslint:recommended');
    const tsOverride = base.overrides.find((o) =>
      o.files.includes('**/*.ts'),
    );
    expect(tsOverride.parser).toBe('@typescript-eslint/parser');
  });

  it('react.cjs extends the base config and reproduces the pre-migration web rules', () => {
    const react = require('./react.cjs');
    expect(react.rules['react/prop-types']).toBe('off');
    expect(react.settings.react.version).toBe('18.2');
  });

  it('node.cjs extends the base config and adds a node env', () => {
    const node = require('./node.cjs');
    expect(node.env.node).toBe(true);
  });

  it('boundaries.cjs defines no-restricted-paths zones and scoped globals/syntax bans', () => {
    const boundaries = require('./boundaries.cjs');
    expect(boundaries.rules['import/no-restricted-paths']).toBeDefined();
    const scoped = boundaries.overrides[0];
    expect(scoped.rules['no-restricted-globals']).toContain('window');
    expect(scoped.rules['no-restricted-syntax'][1].selector).toBe(
      'MetaProperty',
    );
  });
});
