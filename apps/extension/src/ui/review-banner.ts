// Shadow-DOM-isolated banner (docs/07 §7) — the human anchor point. Autofill
// only ever starts from its "Start autofill" button, and the terminal
// "published/abort" self-reports come from it too.

export interface BannerAction {
  label: string;
  primary?: boolean;
  onClick: () => void;
}

export class ReviewBanner {
  private host: HTMLDivElement;
  private body!: HTMLDivElement;
  private actionsEl!: HTMLDivElement;

  constructor(title: string) {
    this.host = document.createElement("div");
    const shadow = this.host.attachShadow({ mode: "closed" });

    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = chrome.runtime.getURL("review-banner.css");
    shadow.appendChild(link);

    const banner = document.createElement("div");
    banner.className = "lacasa-banner";

    const header = document.createElement("div");
    header.className = "lacasa-banner__header";
    const titleEl = document.createElement("span");
    titleEl.textContent = title;
    const close = document.createElement("button");
    close.className = "lacasa-banner__close";
    close.textContent = "✕";
    close.addEventListener("click", () => this.remove());
    header.append(titleEl, close);

    this.body = document.createElement("div");
    this.body.className = "lacasa-banner__body";

    this.actionsEl = document.createElement("div");
    this.actionsEl.className = "lacasa-banner__actions";

    banner.append(header, this.body, this.actionsEl);
    shadow.appendChild(banner);
    document.documentElement.appendChild(this.host);
  }

  setMessage(text: string): void {
    this.body.textContent = text;
  }

  setActions(actions: BannerAction[]): void {
    this.actionsEl.replaceChildren();
    for (const action of actions) {
      const btn = document.createElement("button");
      btn.className = "lacasa-banner__btn" + (action.primary ? " lacasa-banner__btn--primary" : "");
      btn.textContent = action.label;
      btn.addEventListener("click", action.onClick);
      this.actionsEl.appendChild(btn);
    }
  }

  remove(): void {
    this.host.remove();
  }
}
