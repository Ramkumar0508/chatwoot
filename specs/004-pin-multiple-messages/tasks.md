---

description: "Task list for Pin Multiple Messages (dashboard + API)"
---

# Tasks: Pin Multiple Messages

**Input**: Design documents from `/specs/004-pin-multiple-messages/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [data-model.md](./data-model.md), [contracts/pinned-messages-api.md](./contracts/pinned-messages-api.md), [research.md](./research.md), [quickstart.md](./quickstart.md)

**Tests**: Omitted per project guidelines (spec does not mandate automated tests for this feature).

**Organization**: Phases follow **priority order** from [spec.md](./spec.md): **P1 → P2 (US2) → P2 (US4) → P3**.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependency on incomplete tasks in the same phase)
- **[Story]**: `[US1]` … `[US4]` for user-story phases only

## Path Conventions (this repo)

Rails app root: `app/`, `config/`, `db/`  
Dashboard: `app/javascript/dashboard/`

---

## Phase 1: Setup (shared infrastructure)

**Purpose**: Ensure local toolchain and feature docs are ready before implementation.

- [x] T001 Verify Ruby version matches `.ruby-version`, run `bundle install`, and run `pnpm install` at repository root per [plan.md](./plan.md) and `AGENTS.md`
- [x] T002 [P] Confirm feature documentation set is present: [spec.md](./spec.md), [plan.md](./plan.md), [data-model.md](./data-model.md), [contracts/pinned-messages-api.md](./contracts/pinned-messages-api.md)

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: Persisted model, service layer, and conversation-scoped API matching [contracts/pinned-messages-api.md](./contracts/pinned-messages-api.md). **No user story UI work should ship before list/pin/unpin can return consistent JSON.**

**⚠️ CRITICAL**: User story phases assume this phase is complete.

- [x] T003 Add migration `db/migrate/*_create_conversation_pinned_messages.rb` with indexes and uniqueness per [data-model.md](./data-model.md) (`conversation_id`, `message_id`, `account_id`, timestamps, `pinned_by_id` as applicable)
- [x] T004 Implement `app/models/conversation_pinned_message.rb` and wire associations on `app/models/conversation.rb` and `app/models/message.rb` per [data-model.md](./data-model.md)
- [x] T005 Implement `app/services/conversations/pinned_messages_service.rb` enforcing max 20 pins per conversation, idempotent pin, conversation/message integrity, and omitting unavailable messages with `has_unavailable_pins` semantics per [research.md](./research.md) Decision 4
- [x] T006 Register nested routes in `config/routes.rb` for `pinned_messages` under `accounts` → `conversations` per [contracts/pinned-messages-api.md](./contracts/pinned-messages-api.md)
- [x] T007 Implement `app/controllers/api/v1/accounts/conversations/pinned_messages_controller.rb` (index/create/destroy) with authorization aligned to conversation access and JSON error codes per contract
- [x] T008 [P] Add JSON templates or serializers under `app/views/api/v1/accounts/conversations/pinned_messages/` (or equivalent) so list responses include `pinned_messages`, `has_unavailable_pins`, and embedded `message` payload fields needed for UI previews per [contracts/pinned-messages-api.md](./contracts/pinned-messages-api.md)

**Checkpoint**: `GET/POST/DELETE` pinned messages return correct shapes for a seeded conversation (manual `rails runner` or HTTP client).

---

## Phase 3: User Story 1 — Pin multiple messages (Priority: P1) — MVP

**Goal**: Agents can pin multiple messages; pinned list appears in conversation; selecting an item jumps to the message; pins persist on revisit (**FR-001–FR-005**).

**Independent Test**: Pin two different messages; pinned area lists both without duplicates; click each to jump; refresh conversation — pins still listed (see [quickstart.md](./quickstart.md) steps 1–4, 6 partial).

### Implementation

- [x] T009 [P] [US1] Add dashboard API helpers for pinned messages in `app/javascript/dashboard/api/conversations.js` (or colocated client) for GET list, POST pin, DELETE unpin matching [contracts/pinned-messages-api.md](./contracts/pinned-messages-api.md)
- [x] T010 [US1] Implement Vuex module `app/javascript/dashboard/store/modules/pinnedMessages.js`, wire mutations/actions in `app/javascript/dashboard/store/mutation-types.js` and `app/javascript/dashboard/store/index.js`, and sync list after conversation selection
- [x] T011 [US1] Integrate `app/javascript/dashboard/components/widgets/conversation/PinnedMessagesPanel.vue` into `app/javascript/dashboard/components/widgets/conversation/MessagesView.vue` (placement in conversation layout) and implement fetch-on-open + display of pinned rows + jump via `emitter` / `BUS_EVENTS.SCROLL_TO_MESSAGE` per existing patterns
- [x] T012 [P] [US1] Add “Pin” entry to `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue` and dispatch pin through `app/javascript/dashboard/store/modules/conversations/actions.js` (or pinned store) with optimistic/error handling
- [x] T013 [P] [US1] Add English strings for pinned UI in `app/javascript/dashboard/i18n/locale/en/conversation.json` and server-side messages in `config/locales/en.yml` as needed

**Checkpoint**: MVP — pinning and jump-to-message work end-to-end for authorized agents.

---

## Phase 4: User Story 2 — Unpin and manage pins (Priority: P2)

**Goal**: Unpin updates list immediately; max 20 enforced with clear messaging; unavailable pinned messages omitted with non-blocking notice (**FR-006, FR-007, FR-009**).

**Independent Test**: Unpin removes item; 21st pin blocked with instruction; deleted message disappears from list with notice ([quickstart.md](./quickstart.md) steps 5–7).

### Implementation

- [x] T014 [US2] Surface 422 from `POST` when limit reached in UI (toast or inline) using copy from `app/javascript/dashboard/i18n/locale/en/conversation.json`
- [x] T015 [US2] Implement unpin from message context menu and/or pinned panel, calling DELETE per contract and updating `pinnedMessages` store
- [x] T016 [US2] Show `has_unavailable_pins` notice in `app/javascript/dashboard/components/widgets/conversation/PinnedMessagesPanel.vue` per spec edge cases

**Checkpoint**: Limit + unavailable notice + unpin behave per [spec.md](./spec.md) User Story 2.

---

## Phase 5: User Story 4 — Pinned area UI (compact, integrated) (Priority: P2)

**Goal**: Meet **FR-011–FR-018**: collapsible compact region, sender + snippet + timestamp, smooth jump, overflow handling, subtle unpin, visual hierarchy, responsiveness, Chatwoot-aligned density.

**Independent Test**: Several pins — collapse/expand, overflow scroll or carousel, hover/focus unpin, narrow viewport usability ([spec.md](./spec.md) User Story 4 acceptance scenarios).

### Implementation

- [x] T017 [US4] Refactor `app/javascript/dashboard/components/widgets/conversation/PinnedMessagesPanel.vue` to a **compact, collapsible** strip (top or side per `MessagesView.vue` layout) with **pinned icon** and **soft accent** — avoid heavy bordered cards (**FR-011, FR-016**)
- [x] T018 [US4] Render each row with **sender name**, **truncated snippet**, and **timestamp** (reuse dashboard time formatting used in thread) from embedded `message` payload (**FR-012**)
- [x] T019 [US4] Ensure activation uses **smooth** scroll to target message: adjust scroll helper / `BUS_EVENTS.SCROLL_TO_MESSAGE` handling in `MessagesView.vue` or `app/javascript/dashboard/components/widgets/conversation/helpers/` as needed (**FR-013**)
- [x] T020 [US4] Add **max-height** scrollable list **or** carousel for many pins; pick one pattern and apply consistently (**FR-014**); if carousel, support keyboard focus order without traps (spec edge cases)
- [x] T021 [US4] Add **unpin** affordance on row **hover/focus** or compact icon button with accessible hit area — not a full button row per item (**FR-015**)
- [x] T022 [US4] Responsive behavior: default collapse or tighter layout on small breakpoints; ensure composer and transcript remain usable (**FR-017, FR-018**)
- [x] T023 [P] [US4] When collapsed, show **pin count** or icon so agents know pins exist (spec edge case “collapsed state”)

**Checkpoint**: Visual/UX acceptance matches **FR-011–FR-018** and User Story 4 scenarios.

---

## Phase 6: User Story 3 — Permissions and pinned visibility (Priority: P3)

**Goal**: Only authorized users see pin/unpin controls; unauthorized users cannot modify pins; cross-session consistency for authorized staff (**FR-008, FR-010**).

**Independent Test**: Role without permission — no pin controls; authorized — full access; two sessions see same list ([quickstart.md](./quickstart.md) step 8).

### Implementation

- [x] T024 [US3] Enforce authorization in `app/controllers/api/v1/accounts/conversations/pinned_messages_controller.rb` via `ConversationPolicy` (or dedicated policy) consistent with conversation access and pin permission flags
- [x] T025 [US3] Hide pin/unpin actions in `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue` when user lacks permission; hide or read-only `PinnedMessagesPanel.vue` interactions per store getters (e.g. `isPinnedAccessDenied`)

**Checkpoint**: Permission matrix from [spec.md](./spec.md) User Story 3 holds in UI and API.

---

## Phase 7: Polish & cross-cutting concerns

**Purpose**: Validation, lint, and optional collaboration hardening.

- [x] T026 Run manual validation following `specs/004-pin-multiple-messages/quickstart.md` and update steps if UX changed materially
- [x] T027 [P] Run `pnpm eslint` on touched `app/javascript/dashboard/` files and `bundle exec rubocop -a` on touched Ruby files per `AGENTS.md`
- [x] T028 [P] Confirm no `enterprise/` override is required for new routes/controllers (grep `pinned_messages` / `ConversationPinnedMessage` under `enterprise/`); add extension only if product requires Enterprise-only behavior

---

## Dependencies & execution order

### Phase dependencies

| Phase | Depends on |
|-------|------------|
| Phase 1 Setup | — |
| Phase 2 Foundational | Phase 1 |
| Phase 3 US1 (P1) | Phase 2 |
| Phase 4 US2 (P2) | Phase 3 (uses list + pin flow) |
| Phase 5 US4 (P2) | Phase 3–4 recommended (panel content + unpin affordances) |
| Phase 6 US3 (P3) | Phase 2+ (API must enforce); UI gating can follow US1 |
| Phase 7 Polish | Phases 3–6 as applicable |

### User story dependency graph

```text
Foundational → US1 (P1) → US2 (P2) ─┬→ US4 (P2) UI polish
                                  └→ US3 (P3) permissions (can overlap with US4 after API auth exists)
```

**Suggested MVP**: Complete through **Phase 3 (US1)** and validate with [quickstart.md](./quickstart.md) partial flow.

### Parallel opportunities

- **Phase 1**: T001 and T002 in parallel
- **Phase 2**: T008 can proceed in parallel with T003–T007 once shapes are agreed (coordinate on JSON keys)
- **Phase 3**: T009, T012, T013 in parallel after T010–T011 scaffolding exists (T010 blocks full integration testing)
- **Phase 5**: T023 in parallel with T017–T022 after panel structure exists
- **Phase 7**: T027 and T028 in parallel

### Parallel example: User Story 1

```bash
# After T010/T011 skeleton exists, parallelize:
# - T009 API client
# - T012 context menu pin action
# - T013 i18n strings
```

---

## Implementation strategy

### MVP first (User Story 1 only)

1. Phase 1 → Phase 2 → Phase 3  
2. Stop and run [quickstart.md](./quickstart.md) steps 1–4  
3. Demo or deploy when stable  

### Incremental delivery

1. **US1**: Pin + list + jump + persist  
2. **US2**: Unpin + limit + unavailable notice  
3. **US4**: FR-011–FR-018 UI pass  
4. **US3**: Final permission UX + policy hardening  
5. **Polish**: Lint + manual regression  

### Notes

- [P] tasks touch different files or are independent once prerequisites exist  
- **[USn]** maps each task to [spec.md](./spec.md) user stories for traceability  
- Revisit **research.md** Decision 5 if product requires realtime pinned sync across agents (optional follow-up, not in default task list)

---

## Format validation

- All tasks use `- [x]` checkboxes when completed  
- All tasks include sequential IDs `T001`–`T028`  
- User-story phases include `[US1]`–`[US4]` labels  
- `[P]` only where parallel-safe  
- Descriptions include concrete file paths under `app/`, `config/`, `db/`, or `app/javascript/dashboard/`  
