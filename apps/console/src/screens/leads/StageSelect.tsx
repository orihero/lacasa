/**
 * StageSelect — the Leads table's stage cell. The screen brief asks for the
 * stage to be genuinely editable "from the table (a select or a small
 * menu)"; rather than pair a read-only Tag with a separate edit control (two
 * elements saying the same thing), this is a native `<select>` styled with
 * the exact tone classes Tag.tsx uses for the same LeadStatusKey, so it reads
 * as a status pill at rest and *is* the edit affordance — no second, mute
 * "click to change" control bolted on next to it.
 *
 * Tag.tsx's TONE_CLASS map isn't exported (it's a private const), so this
 * duplicates the five class strings rather than reach into a sibling
 * component's internals; both are sourced from the same theme tokens
 * (ok/warn/err/info/mute + their -soft backgrounds), so they cannot drift in
 * a way that would leave the two controls looking like different systems.
 */
import clsx from 'clsx';
import type { LeadStatusKey } from '@lacasa/domain';
import { LEAD_STATUS_LABEL, LEAD_STATUS_ORDER } from '@/lib/labels';
import type { Tone } from '@/ui/Tag';

const TONE_CLASS: Record<Tone, string> = {
  ok: 'bg-ok-soft text-ok',
  warn: 'bg-warn-soft text-warn',
  err: 'bg-err-soft text-err',
  info: 'bg-info-soft text-info',
  mute: 'bg-mute-soft text-mute',
  accent: 'bg-accent-tint text-accent-text',
};

export function StageSelect({
  value,
  tone,
  label,
  disabled,
  onChange,
}: {
  value: LeadStatusKey;
  tone: Tone;
  label: string;
  disabled?: boolean;
  onChange: (next: LeadStatusKey) => void;
}) {
  return (
    <select
      aria-label={label}
      value={value}
      disabled={disabled}
      onChange={(event) => onChange(event.target.value as LeadStatusKey)}
      className={clsx(
        'whitespace-nowrap rounded-chip border-0 px-[9px] py-[3.5px] text-caption font-semibold',
        'cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-dark',
        'disabled:cursor-wait disabled:opacity-60',
        TONE_CLASS[tone],
      )}
    >
      {LEAD_STATUS_ORDER.map((key) => (
        <option key={key} value={key}>
          {LEAD_STATUS_LABEL[key]}
        </option>
      ))}
    </select>
  );
}
