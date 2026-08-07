/**
 * PublishPanel — mockups/f/PLAN.md §3.3's right-column "Publish" panel.
 *
 * There is no endpoint that takes an ad + a channel selection and fires all
 * of them at once (`apps/api/src/routes/publish.js` only has
 * `/instagram` (direct, single-channel), the extension-assisted `/:channel/
 * map-fields` + `/:channel/confirm` pair, and the two status reads — no
 * generic multi-channel dispatch). Rather than fake the mockup's "Publish to
 * 2 channels" button into calling something that doesn't exist, this keeps
 * it disabled with a `title` naming the gap and a `<Flag>`, mirroring the
 * exact precedent `publishStatus/helpers.ts`'s `RETRY_GAP_MESSAGE` /
 * PublishStatusScreen's disabled "Retry failed" button already set — see
 * this folder's report for why wiring it to `publishInstagram` instead was
 * rejected (that call needs a caption/image payload this screen has no
 * honest way to assemble without duplicating crosspost.ts's own logic).
 *
 * The checkboxes themselves stay real and interactive (not fake affordance):
 * checking/unchecking one only updates this panel's own local "which
 * channels would I publish to" selection, and the button's live count and
 * disabled state are the one thing downstream of it — nothing here promises
 * an action it can't perform. IG/Telegram default checked when a real
 * connection exists (`useInstagramAccounts`/`tgChatIds`); OLX stays the
 * mockup's own non-interactive, dimmed row (real browser-extension
 * dependency, no server-side signal at all).
 */
import { Panel, PanelHead } from "@/ui/Panel";
import { Button } from "@/ui/Button";
import { Checkbox } from "@/ui/Checkbox";
import { Flag } from "@/ui/Flag";
import { InstagramLogoIcon, PaperPlaneTiltIcon, StorefrontIcon, TelegramLogoIcon, YoutubeLogoIcon } from "@/ui/icons";

export const PUBLISH_GAP_MESSAGE =
  "No endpoint publishes to multiple channels at once yet — apps/api/src/routes/publish.js only has a direct single-channel Instagram publish plus the extension-assisted OLX/Instagram flow. Use Publish status after saving to see what each channel actually did.";

export interface PublishChannelState {
  instagram: boolean;
  telegram: boolean;
  youtube: boolean;
}

export function PublishPanel({
  channels,
  onChannelsChange,
  instagramStatus,
  telegramStatus,
}: {
  channels: PublishChannelState;
  onChannelsChange: (next: PublishChannelState) => void;
  instagramStatus: string;
  telegramStatus: string;
}) {
  const selectedCount = Number(channels.instagram) + Number(channels.telegram) + Number(channels.youtube);

  return (
    <Panel>
      <PanelHead title="Publish" sub="Select channels" />

      <div className="flex flex-col gap-2">
        <ChannelRow
          icon={<InstagramLogoIcon size={18} weight="fill" className="text-ink-2" />}
          name="Instagram"
          status={instagramStatus}
          checked={channels.instagram}
          onChange={(checked) => onChannelsChange({ ...channels, instagram: checked })}
        />
        <ChannelRow
          icon={<TelegramLogoIcon size={18} weight="fill" className="text-ink-2" />}
          name="Telegram"
          status={telegramStatus}
          checked={channels.telegram}
          onChange={(checked) => onChannelsChange({ ...channels, telegram: checked })}
        />
        <ChannelRow
          icon={<YoutubeLogoIcon size={18} weight="fill" className="text-ink-2" />}
          name="YouTube"
          status="Not connected"
          checked={channels.youtube}
          onChange={(checked) => onChannelsChange({ ...channels, youtube: checked })}
        />
        <div className="flex items-center gap-3 rounded-input border border-hairline bg-pill px-3.5 py-2.5 opacity-50">
          <StorefrontIcon size={18} weight="fill" className="text-ink-2" />
          <div className="min-w-0 flex-1">
            <b className="block text-body font-semibold text-ink">OLX</b>
            <span className="block text-caption text-ink-2">Requires the browser extension</span>
          </div>
          <Checkbox checked={false} disabled label="OLX (requires the browser extension)" />
        </div>
      </div>

      <Button
        variant="dark"
        icon={PaperPlaneTiltIcon}
        className="mt-3.5 w-full justify-center"
        disabled
        title={PUBLISH_GAP_MESSAGE}
      >
        Publish to {selectedCount} channel{selectedCount === 1 ? "" : "s"}
      </Button>

      <Flag className="mt-3.5">{PUBLISH_GAP_MESSAGE}</Flag>
    </Panel>
  );
}

function ChannelRow({
  icon,
  name,
  status,
  checked,
  onChange,
}: {
  icon: React.ReactNode;
  name: string;
  status: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <div className="flex items-center gap-3 rounded-input border border-hairline bg-pill px-3.5 py-2.5">
      {icon}
      <div className="min-w-0 flex-1">
        <b className="block text-body font-semibold text-ink">{name}</b>
        <span className="block text-caption text-ink-2">{status}</span>
      </div>
      <Checkbox checked={checked} onChange={onChange} label={`Include ${name} in this publish`} />
    </div>
  );
}
