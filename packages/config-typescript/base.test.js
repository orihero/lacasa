import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

function readJson(relPath) {
  const abs = fileURLToPath(new URL(relPath, import.meta.url));
  return JSON.parse(readFileSync(abs, 'utf8'));
}

describe('@lacasa/config-typescript', () => {
  it('base.json is strict and emits declarations/sourcemaps', () => {
    const base = readJson('./base.json');
    expect(base.compilerOptions.strict).toBe(true);
    expect(base.compilerOptions.declaration).toBe(true);
    expect(base.compilerOptions.declarationMap).toBe(true);
    expect(base.compilerOptions.sourceMap).toBe(true);
  });

  it('node-library.json excludes DOM libs', () => {
    const node = readJson('./node-library.json');
    expect(node.extends).toBe('./base.json');
    expect(node.compilerOptions.lib).toEqual(['ES2022']);
  });

  it('react-library.json includes DOM libs', () => {
    const react = readJson('./react-library.json');
    expect(react.extends).toBe('./base.json');
    expect(react.compilerOptions.lib).toContain('DOM');
    expect(react.compilerOptions.lib).toContain('DOM.Iterable');
  });
});
