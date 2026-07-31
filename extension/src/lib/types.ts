export type Channel = "olx" | "instagram";

// Ads still live in Firestore, so the web app sends the full listing payload
// with the trigger message instead of the extension fetching it by id.
export interface CrosspostJob {
  channel: Channel;
  adId: string;
  ad: Record<string, unknown>;
  photoUrls: string[];
  token: string;
  apiBase: string;
  createdAt: number;
}

export interface FieldAction {
  ref: string;
  action: "set-value" | "select-option" | "click-radio";
  value: string;
  confidence: number;
}

export interface UnresolvedField {
  ref: string;
  reason: string;
  suggestedAdField?: string | null;
}

export interface MapFieldsResponse {
  categoryClick: { ref: string; label: string } | null;
  fields: FieldAction[];
  unresolved: UnresolvedField[];
  confidence: number;
}

export interface FieldNode {
  ref: string;
  tag: string;
  role?: string;
  type?: string;
  name?: string;
  id?: string;
  label?: string;
  placeholder?: string;
  value?: string;
  options?: string[];
  required?: boolean;
  path: number[];
}

export interface CategoryStepNode {
  ref: string;
  kind: "category-step";
  level: number;
  options: { ref: string; label: string }[];
}

export type SnapshotNode = FieldNode | CategoryStepNode;

export interface PhotoPayload {
  b64: string;
  mime: string;
  filename: string;
}

export type ConfirmEvent = "drafted" | "published" | "failed" | "aborted" | "dom-drift";
