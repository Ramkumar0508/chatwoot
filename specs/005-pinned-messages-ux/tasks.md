---

description: "Task list for Pinned messages UX improvements (005)"
---

# Tasks: Pinned messages UX improvements

**Input**: Design documents from `/specs/005-pinned-messages-ux/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/messages-around-anchor.md](./contracts/messages-around-anchor.md), [quickstart.md](./quickstart.md)

**Tests**: Omitted per project guidelines (spec does not mandate new automated tests; add RSpec only if a regression contract is needed for `around_message_id`).

**Organization**: **Phase 2** is backend foundation for **User Story 2** (anchor window). **User Story 1** (sticky strip) can proceed in parallel once layout is understood; full pin-open flow needs Phase 2 complete.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependency)
- **[Story]**: `[US1]` = sticky / collapsed / preview + full list; `[US2]` = load around anchor, scroll, error, focus

## Path conventions (this repo)

Rails: `app/`, `config/`  
Dashboard: `app/javascript/dashboard/`

---

## Phase 1: Setup

**Purpose**: Toolchain and docs ready.

- [ ] T001 Verify Ruby (`rbenv`, `.ruby-version`), run `bundle install` and `pnpm install` at repo root per `AGENTS.md`
- [ ] T002 [P] Skim [spec.md](./spec.md) clarifications, [contracts/messages-around-anchor.md](./contracts/messages-around-anchor.md), and [quickstart.md](./quickstart.md) before coding

---

## Phase 2: Foundational (blocking for US2 anchor loads)

**Purpose**: `GET .../conversations/:id/messages` supports **`around_message_id`** per [contracts/messages-around-anchor.md](./contracts/messages-around-anchor.md). **No “open pin in context” slice should merge until this works.**

**⚠️ CRITICAL**: User Story 2 implementation (Phase 4) depends on this phase.

- [x] T003 Implement `messages_around` (or equivalent) in `app/finders/message_finder.rb`: bounded `before_limit` / `after_limit` (defaults + server-side caps), include anchor message once, same includes as other finder paths, return chronological order
- [x] T004 Wire query params in `app/controllers/api/v1/accounts/conversations/messages_controller.rb` (strong params / permitted params for `around_message_id`, limits) and pass into `MessageFinder`; return 422/404 for invalid anchor per contract
- [x] T005 [P] Confirm JSON shape for messages index unchanged aside from new query behavior (`app/views/api/v1/accounts/conversations/messages/index.json.jbuilder` or equivalent — adjust only if meta must expose anchor hints)

**Checkpoint**: Manual request: `GET .../messages?around_message_id=<valid_msg_id>` returns a window; invalid id returns documented error. See [quickstart.md](./quickstart.md).

---

## Phase 3: User Story 1 — Sticky, collapsed-by-default pinned area (Priority: P1) — MVP slice

**Goal**: **FR-001, FR-002, FR-007, FR-009** — pinned strip stays accessible without scrolling the backlog; **collapsed by default**; **preview + full list** when pins overflow.

**Independent Test**: Long conversation + many pins — strip remains at top while scrolling messages; default collapsed; overflow shows preview + control to open full list ([spec.md](./spec.md) US1, [quickstart.md](./quickstart.md) steps 1–2).

### Implementation

- [x] T006 [US1] Restructure `app/javascript/dashboard/components/widgets/conversation/MessagesView.vue` so `PinnedMessagesPanel` is **outside** the scrollable `.conversation-panel` (flex column: strip fixed height / shrink-0, panel scrolls) — matches [research.md](./research.md) Decision 1
- [x] T007 [US1] Update `app/javascript/dashboard/components/widgets/conversation/PinnedMessagesPanel.vue`: **default collapsed** on conversation open (desktop + mobile per [spec.md](./spec.md) clarifications); keep clear expand affordance (`aria-expanded`, button labels)
- [x] T008 [US1] Implement **limited preview** + **“view all”** (modal, drawer, or existing dashboard modal pattern) listing every pin when count exceeds preview; show total count / “+N” so overflow is never silent (**FR-009**)
- [x] T009 [P] [US1] Add English strings in `app/javascript/dashboard/i18n/locale/en/conversation.json` for collapse/expand, view-all, preview overflow; no bare strings in templates

**Checkpoint**: Pin UX matches US1 without requiring anchor loading yet (pin row can still call existing jump behavior until Phase 4).

---

## Phase 4: User Story 2 — Contextual loading around a pin (Priority: P2)

**Goal**: **FR-003–FR-006, FR-008, FR-010** — opening a pin loads a **window** around the message; scroll loads older/newer; **inline error + Retry**; **keyboard focus** on anchor.

**Independent Test**: Pin in middle of long thread → open from pinned UI → anchor + neighbors without loading full history → scroll up/down → incremental loads → simulate failure → Retry → focus lands on anchor ([quickstart.md](./quickstart.md) steps 3–6).

### Implementation

- [x] T010 [US2] Extend `app/javascript/dashboard/api/inbox/message.js` with `getMessagesAround` (or extend `getPreviousMessages`) passing `around_message_id` (+ optional limits) per [contracts/messages-around-anchor.md](./contracts/messages-around-anchor.md)
- [x] T011 [US2] Add Vuex action(s) in `app/javascript/dashboard/store/modules/conversations/actions.js` (and mutations in `app/javascript/dashboard/store/modules/conversations/index.js` / `mutation-types.js` as needed) to **replace** `currentChat.messages` with around-window payload, set metadata / `dataFetched` so scroll-up uses `before: firstMessageId` and scroll-down uses `after: lastMessageId` per [data-model.md](./data-model.md); store **`anchorLoadError`** + retry payload for failed fetches (**FR-008**)
- [x] T012 [US2] Update `PinnedMessagesPanel.vue`: on pin select, **dispatch anchor load** (not only `emitter` scroll-to-message) when the message is not in the loaded window or always use around-load for consistency — pick one behavior and document in commit; update route `messageId` query if still used in `ConversationView.vue`
- [x] T013 [US2] Update `MessagesView.vue`: remove/replace `onScrollToMessage` path that **falls back to `scrollToBottom`** when `#message{id}` is missing — coordinate with store-driven load; render **inline** error UI (e.g. `Banner` or compact block) with **Retry** dispatching the same action (**FR-008**)
- [x] T014 [P] [US2] After around load + `nextTick`, **focus** anchor message node (`#message{id}` or focusable wrapper on `components-next` bubble) per **FR-010**; verify tab order is not trapped in preview modal

**Checkpoint**: End-to-end matches [spec.md](./spec.md) User Story 2 acceptance scenarios.

---

## Phase 5: Polish & cross-cutting

**Purpose**: Lint, sanity-check Enterprise, manual QA.

- [ ] T015 [P] Run `bundle exec rubocop -a` on touched Ruby files and `pnpm eslint` on touched JS/Vue files
- [ ] T016 [P] Re-check `enterprise/` for overrides of `MessageFinder` or `messages_controller` (expect none); mirror only if Enterprise duplicates these paths
- [ ] T017 Walk through [quickstart.md](./quickstart.md) and tick scenarios; fix gaps

---

## Dependencies & execution order

| Phase | Depends on | Notes |
|-------|------------|--------|
| Phase 1 | — | Start anytime |
| Phase 2 | Phase 1 (tooling) | Blocks Phase 4 |
| Phase 3 | Phase 1 | Can run **parallel** with Phase 2 (different layers) |
| Phase 4 | Phase 2 + Phase 3 recommended | UI entry points from T007–T008 should exist before polishing pin-open |
| Phase 5 | Phase 4 | — |

### User story dependencies

- **US1**: Does not require Phase 2 for layout/collapse/preview-only.
- **US2**: **Requires Phase 2** (T003–T005) before T010–T014.

### Parallel opportunities

- T002, T005, T009, T014, T015, T016 marked **[P]** can run in parallel with other work when not blocked by merge conflicts.

---

## Implementation strategy

### MVP (US1 first)

1. Complete Phase 1 + Phase 3 (T006–T009) → sticky/collapsed/preview UX without backend changes.
2. Validate independently.

### Full feature

1. Complete Phase 2 → Phase 4 → Phase 5.
2. Deliver incremental loading + error + focus per spec.

---

## Notes

- Do not add a “jump to latest” button (explicitly out of spec).
- Return to latest is **scroll-only** per clarifications.
- If `setActiveChat` / initial fetch conflicts with around-window state, resolve in T011 with minimal state machine (document in PR).
