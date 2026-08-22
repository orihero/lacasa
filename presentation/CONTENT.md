# La Casa — pitch deck content (single source of truth)

One narrative, three visual treatments. Every deck in this folder renders **this**
content; only the design language changes.

## Structure

The slide order follows the Sequoia 10-section framework (purpose → problem →
solution → why now → market → competition → product → model → traction → team →
ask), with two additions that a marketplace deck needs and Sequoia's generic
template leaves implicit: a **distribution** slide (the crossposting pipeline is
the wedge, so it earns its own frame) and a **go-to-market** slide. Guy Kawasaki's
10/20/30 discipline sets the ceiling on words per slide.

13 slides. Nothing that isn't answering an investor question.

## Mock data policy

This repo contains a product, not a data room. Every number that isn't derivable
from the codebase is invented and **marked in the deck itself** with a `mock`
chip. Two figures are real and cited: global proptech market size/CAGR, and the
platform's own shipped state (surfaces, stack, migration status), which comes
from `docs/05-migration-plan.md`.

Before this goes in front of anyone, replace every `mock` chip with a real number
or delete the claim.

---

## 1 — Cover

**La Casa** — The operating system for Uzbekistan's real-estate agents.
Seed round · August 2026

## 2 — Problem

> A listing lives in nine places and belongs to none of them.

- One property is retyped into OLX, three or four Telegram channels, Instagram
  and a paper notebook — **40+ minutes per listing** `mock`
- Buyers scroll duplicates of the same flat; **a third are already sold** `mock`
- Leads arrive as Telegram DMs. No pipeline, no history, no handover
- Agency owners can't see what their agents did this week

## 3 — Solution

**List once. Publish everywhere. Work the lead.**

| | |
|---|---|
| Publish | One form pushes to Telegram, Instagram, OLX and the marketplace |
| Work | Leads land in a kanban pipeline with owners, stages and history |
| Prove | Per-agent analytics the agency owner actually trusts |

## 4 — Why now

- **The platform is real.** Firebase MVP → Express + PostgreSQL + MinIO, server-held
  tokens, server-side validation. Migration complete August 2026 (`docs/05`)
- **The channels opened.** Meta Graph API and OLX now allow programmatic posting
  from a reviewed app — the manual re-typing is newly automatable
- **The market moved.** Uzbekistan mortgage issuance up **23% YoY** `mock`; new-build
  supply at a record `mock`
- **Telegram is the distribution layer, not the competitor.** We publish into it

## 5 — Product

Four surfaces, one backend.

- **Marketplace** (React) — search, map, agent profiles, saved listings
- **Agent console** (React 19) — listings, leads kanban, coworkers, analytics
- **Mobile** (Flutter) — role-aware: buyers browse, agents work, one binary
- **Crosspost extension** (Chrome) — drives OLX and Instagram from the agent's session

Underneath: Express + Prisma + PostgreSQL 16, MinIO presigned uploads, JWT auth,
CI with integration tests against a real database.

## 6 — Distribution (the wedge)

One listing → five destinations, one click, with per-channel publish status
(`AdPublication`: queued / published / failed) so an agent can see where their
property actually landed.

Marketplace · Telegram channel · Instagram carousel · OLX · YouTube tour

## 7 — Market

| | | |
|---|---|---|
| **TAM** | Uzbekistan residential transactions | **$6.4B / yr** `mock` |
| **SAM** | Agent-mediated deals · 14,000 licensed agents | **$180M** `mock` |
| **SOM** | 1,200 paying seats by year 3 | **$4.1M ARR** `mock` |

Reference point: global proptech is **$50.1B in 2026 → $115B by 2033, 12.6% CAGR**
(Coherent Market Insights). Residential is 56% of it.

## 8 — Business model

- **Agent seat** — $19/mo solo, $15/seat for agencies of 5+ `mock`
- **Featured placement** — $4 per listing per 7 days `mock`
- **Crosspost credits** — beyond the free monthly tier `mock`
- **Developer inventory** — 0.5% on new-build units sold through the platform `mock`

ARPA $27/mo · CAC $38 · payback 1.4 months · gross margin 82% `mock`

## 9 — Traction

`mock` — all of it.

- 480 agents onboarded · 11,300 live listings · 62,000 monthly buyers
- $19,400 MRR, 3.1× YoY
- 94% logo retention · 41% of listings crossposted within 24h of creation

## 10 — Competition

| | Reach | Agent tools | Local channels |
|---|---|---|---|
| OLX.uz | High | None | — |
| uybor.uz | Medium | Listing only | — |
| Telegram channels | High | None | Native |
| International CRMs | — | Strong | None |
| **La Casa** | **Growing** | **Full CRM** | **Native + automated** |

Nobody else spans distribution *and* the pipeline in this market.

## 11 — Go to market

1. **Wedge** — free crossposting extension; agents install it for the time saved
2. **Land** — Tashkent agencies of 5–20 seats, owner-led sale
3. **Flywheel** — agent supply fills the marketplace; buyer demand pulls the next agency
4. **Expand** — developer new-build inventory (yr 2), Almaty & Bishkek (yr 3)

## 12 — Team

`mock` placeholders — replace with the real roster.

- Founder / CEO — 9 yrs Tashkent residential brokerage
- Founder / CTO — built the platform; ex-fintech backend
- Head of Growth — ex-OLX Uzbekistan
- 3 engineers · 1 designer

## 13 — Ask

**$1.2M seed** `mock` · 18 months runway

45% engineering · 30% go-to-market · 15% ops & compliance · 10% infrastructure

Milestones: 1,200 paying seats · $4.1M ARR run-rate · developer channel live `mock`
