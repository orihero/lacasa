import { describe, expect, it } from 'vitest';
import { baseNodeConfig, nodePreset } from './node.js';
import { baseReactConfig, reactPreset } from './react.js';

describe('@lacasa/config-vitest', () => {
  it('node preset targets the node environment with 80% thresholds', () => {
    expect(baseNodeConfig.test.environment).toBe('node');
    expect(baseNodeConfig.test.coverage.thresholds.lines).toBe(80);
  });

  it('react preset targets jsdom, wires the shared setup file, and starts at 40%', () => {
    expect(baseReactConfig.test.environment).toBe('jsdom');
    expect(baseReactConfig.test.setupFiles[0]).toMatch(/react\.setup\.js$/);
    expect(baseReactConfig.test.coverage.thresholds.lines).toBe(40);
  });

  it('factories merge overrides on top of the base preset', () => {
    const merged = nodePreset({ test: { coverage: { thresholds: { lines: 95 } } } });
    expect(merged.test.coverage.thresholds.lines).toBe(95);
    expect(merged.test.environment).toBe('node');

    const mergedReact = reactPreset({ test: { environment: 'jsdom' } });
    expect(mergedReact.test.setupFiles[0]).toMatch(/react\.setup\.js$/);
  });
});
