/**
 * PropertyDetailsPanel — mockups/f/PLAN.md §3.3's left "Property details"
 * panel, f-console.src.html's `.fgrid` (Title, City, District, Type,
 * Category, Price, Currency, Rooms, Area, Storey, Floors, Repairment,
 * Furniture, Description, Hashtags).
 *
 * City/District read `@lacasa/domain/data/regions` (14 regions, 203
 * districts) the same way apps/web/src/components/adsAdd/AdsAdd.tsx does —
 * `Ad.city`/`.district` are free text server-side (no enum validation), but
 * this vocabulary is the real one every other ad-entry surface in the
 * product already uses, not an invented list.
 */
import regionData from "@lacasa/domain/data/regions";
import { AD_CATEGORY_LABEL, AD_TYPE_LABEL, FURNITURE_LABEL, REPAIRMENT_LABEL } from "@/lib/labels";
import { Field, PillInput, PillSelect, PillTextarea } from "@/ui/Field";
import { Panel, PanelHead } from "@/ui/Panel";
import {
  AD_CATEGORY_KEYS,
  AD_TYPE_KEYS,
  CURRENCY_CODE_KEYS,
  FURNITURE_KEYS,
  REPAIRMENT_KEYS,
  type AdFormState,
  type FormErrors,
} from "./adFormFields";

function ErrorHint({ message }: { message?: string }) {
  if (!message) return null;
  return <span className="text-err">{message}</span>;
}

export function PropertyDetailsPanel({
  form,
  errors,
  onChange,
}: {
  form: AdFormState;
  errors: FormErrors;
  onChange: (patch: Partial<AdFormState>) => void;
}) {
  const districtsForCity = form.city
    ? regionData.districts.filter((district) => {
        const region = regionData.regions.find((candidate) => candidate.name === form.city);
        return region ? district.region_id === region.id : false;
      })
    : [];

  function handleCityChange(nextCity: string) {
    // Changing city invalidates whatever district was picked under the old
    // one — mirrors AdsAdd.tsx's own setRegionId-driven reset.
    onChange({ city: nextCity, district: "" });
  }

  return (
    <Panel>
      <PanelHead title="Property details" sub="Fields mirror the Ad model" />
      <div className="grid grid-cols-2 gap-x-3.5 gap-y-4">
        <Field label="Title" full hint={<ErrorHint message={errors.title} />}>
          <PillInput
            value={form.title}
            onChange={(event) => onChange({ title: event.target.value })}
            placeholder="Bright 3-room apartment in Chilonzor"
            maxLength={300}
          />
        </Field>

        <Field label="City" hint={<ErrorHint message={errors.city} />}>
          <PillSelect value={form.city} onChange={(event) => handleCityChange(event.target.value)}>
            <option value="">Select…</option>
            {regionData.regions.map((region) => (
              <option key={region.id} value={region.name}>
                {region.name}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="District" hint={<ErrorHint message={errors.district} />}>
          <PillSelect
            value={form.district}
            onChange={(event) => onChange({ district: event.target.value })}
            disabled={!form.city}
          >
            <option value="">Select…</option>
            {districtsForCity.map((district) => (
              <option key={district.id} value={district.name}>
                {district.name}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="Type" hint={<ErrorHint message={errors.type} />}>
          <PillSelect value={form.type} onChange={(event) => onChange({ type: event.target.value as AdFormState["type"] })}>
            <option value="">Select…</option>
            {AD_TYPE_KEYS.map((key) => (
              <option key={key} value={key}>
                {AD_TYPE_LABEL[key]}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="Category" hint={<ErrorHint message={errors.category} />}>
          <PillSelect
            value={form.category}
            onChange={(event) => onChange({ category: event.target.value as AdFormState["category"] })}
          >
            <option value="">Select…</option>
            {AD_CATEGORY_KEYS.map((key) => (
              <option key={key} value={key}>
                {AD_CATEGORY_LABEL[key]}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="Price" hint={<ErrorHint message={errors.price} />}>
          <PillInput
            type="number"
            min="0"
            value={form.price}
            onChange={(event) => onChange({ price: event.target.value })}
            placeholder="78000"
          />
        </Field>

        <Field label="Currency">
          <PillSelect
            value={form.priceType}
            onChange={(event) => onChange({ priceType: event.target.value as AdFormState["priceType"] })}
          >
            {CURRENCY_CODE_KEYS.map((key) => (
              <option key={key} value={key}>
                {key.toUpperCase()}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="Rooms">
          <PillInput
            type="number"
            min="0"
            value={form.rooms}
            onChange={(event) => onChange({ rooms: event.target.value })}
            placeholder="3"
          />
        </Field>

        <Field label="Area, m²">
          <PillInput
            type="number"
            min="0"
            value={form.area}
            onChange={(event) => onChange({ area: event.target.value })}
            placeholder="65"
          />
        </Field>

        <Field label="Storey">
          <PillInput
            type="number"
            min="0"
            value={form.storey}
            onChange={(event) => onChange({ storey: event.target.value })}
            placeholder="4"
          />
        </Field>

        <Field label="Floors">
          <PillInput
            type="number"
            min="0"
            value={form.floors}
            onChange={(event) => onChange({ floors: event.target.value })}
            placeholder="9"
          />
        </Field>

        <Field label="Repairment">
          <PillSelect
            value={form.repairment}
            onChange={(event) => onChange({ repairment: event.target.value as AdFormState["repairment"] })}
          >
            <option value="">Not set</option>
            {REPAIRMENT_KEYS.map((key) => (
              <option key={key} value={key}>
                {REPAIRMENT_LABEL[key]}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="Furniture">
          <PillSelect
            value={form.furniture}
            onChange={(event) => onChange({ furniture: event.target.value as AdFormState["furniture"] })}
          >
            <option value="">Not set</option>
            {FURNITURE_KEYS.map((key) => (
              <option key={key} value={key}>
                {FURNITURE_LABEL[key]}
              </option>
            ))}
          </PillSelect>
        </Field>

        <Field label="Description" full hint={<ErrorHint message={errors.description} />}>
          <PillTextarea
            value={form.description}
            onChange={(event) => onChange({ description: event.target.value })}
            placeholder="A bright corner apartment on the fourth floor…"
            maxLength={5000}
          />
        </Field>

        <Field label="Hashtags" full hint={<ErrorHint message={errors.hashtags} />}>
          <PillInput
            value={form.hashtags}
            onChange={(event) => onChange({ hashtags: event.target.value })}
            placeholder="#chilonzor #3xona #tashkent"
            maxLength={500}
          />
        </Field>
      </div>
    </Panel>
  );
}
