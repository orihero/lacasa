/**
 * src/screens/myAds/SortSelect — a real, wired sort control for the toolbar's
 * "Newest first" chip. The prototype's version is an inert `.filt` span; this
 * one is a native `<select>` over `AdSort`'s three real values, dressed as a
 * filter-pill (`rounded-full`, F's *navigational* radius) rather than
 * `PillSelect` from @/ui/Field (`rounded-input`, F's *editable-field*
 * radius) — a sort control isn't a form field, so it doesn't borrow that
 * radius. Local to this screen because nothing else needs an AdSort picker
 * yet.
 */
import type { AdSort } from '@lacasa/api-client';
import { CaretUpDownIcon } from '@/ui/icons';

const SORT_LABEL: Record<AdSort, string> = {
  newest: 'Newest first',
  highestPrice: 'Highest price',
  lowestPrice: 'Lowest price',
};

const AD_SORT_VALUES: readonly AdSort[] = ['newest', 'highestPrice', 'lowestPrice'];

function isAdSort(value: string): value is AdSort {
  return (AD_SORT_VALUES as readonly string[]).includes(value);
}

export function SortSelect({ value, onChange }: { value: AdSort; onChange: (value: AdSort) => void }) {
  return (
    <label className="inline-flex items-center gap-[7px] whitespace-nowrap rounded-full border border-hairline bg-pill px-[15px] py-[9px] text-label text-ink">
      <CaretUpDownIcon size={13} className="shrink-0 text-ink-2" />
      <span className="sr-only">Sort ads</span>
      <select
        value={value}
        onChange={(event) => {
          if (isAdSort(event.target.value)) onChange(event.target.value);
        }}
        className="appearance-none bg-transparent text-label text-ink outline-none"
      >
        {AD_SORT_VALUES.map((sortValue) => (
          <option key={sortValue} value={sortValue}>
            {SORT_LABEL[sortValue]}
          </option>
        ))}
      </select>
    </label>
  );
}
