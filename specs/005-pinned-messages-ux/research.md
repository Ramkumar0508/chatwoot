# Research: Pinned messages UX improvements

**Feature**: [spec.md](./spec.md)  
**Date**: 2026-03-31

## 1. Sticky pinned strip + default collapsed

**Decision**: Keep `PinnedMessagesPanel` (or successor) as a **sibling above** the scrollable message list in `MessagesView.vue`, using flex layout so the **conversation panel scroll** does not move the pinned strip. Default **collapsed** on conversation open (desktop and mobile aligned with spec); optional `matchMedia` may remain only for density hints, not inverted defaults.

**Rationale**: Spec requires always-visible access without scrolling the backlog; pinning the strip outside `.conversation-panel` avoids “scroll away” behavior. Collapsed-by-default matches `/speckit.clarify` and reduces vertical chrome.

**Alternatives considered**:

- Sticky `position` inside the scroll container — rejected: pinned UI scrolls away with content, contradicting FR-001.
- Remembering expanded state per user — rejected per spec (explicitly out of scope unless added later).

## 2. “Many pins” preview + full list

**Decision**: Render a **limited preview** (e.g. first N pin chips or rows) in the sticky header, plus a **single control** (“View all” / count) that opens a **modal or slide-over** listing all pins (reuse patterns from other dashboard lists). Ensure the control exposes **total count** so overflow is never silent (FR-009).

**Rationale**: Matches clarification; scales to max pin count without unbounded vertical growth.

**Alternatives considered**:

- Horizontal-only scroll — rejected: can hide total count and hurts discoverability.
- Vertical scroll inside sticky strip only — rejected as primary: still works as secondary fallback inside “full list” if needed.

## 3. Loading context around a pinned message (anchor)

**Decision**: **Extend** `MessageFinder` (and `GET .../conversations/:id/messages` index) with an optional **`around_message_id`** (or `focus_message_id`) query parameter. When present, the finder returns a **single ordered array**: up to `before_limit` messages older than the anchor, the **anchor message** (if visible and in scope), and up to `after_limit` newer messages, with sensible defaults (e.g. 20 + 20) aligned with existing `messages_before` / `messages_after` limits. **Permit** new params in the controller for strong-params hygiene.

**Rationale**: Today `onScrollToMessage` only scrolls if the DOM node exists; otherwise it falls back to `scrollToBottom()` — it does **not** load around the anchor. A dedicated finder mode avoids many sequential `fetchPreviousMessages` loops and matches FR-003–FR-005. `MessageFinder` already implements `before` / `after` / `between`; `around` composes the same query patterns in one response.

**Alternatives considered**:

- **Client-only**: two parallel `GET` calls (`before` + `after`) and merge in Vuex — viable MVP but two round trips, trickier meta/`dataFetched` handling, and higher risk of inconsistent `message` ordering at boundaries.
- **Only `after`/`before` without including anchor** — rejected: extra round trip to fetch the anchor row.

## 4. Vuex / UI state after anchor load

**Decision**: Introduce a small **conversation sub-state** (or `pinnedMessages` module) flag such as `anchorMessageId` / `anchorLoadMode` and `anchorLoadError`. When `around_message_id` is used, **replace** `currentChat.messages` with the returned window (or merge deterministically per product rule) and set `dataFetched` / meta so **up** scroll loads older via `fetchPreviousMessages` with `before: firstMessageId`, and **down** loads newer via the same action with **`after: lastMessageId`** and **no** `before` (matches `MessageFinder#messages_after` and existing `MessageApi.getPreviousMessages` usage in `syncActiveConversationMessages`).

**Rationale**: Spec requires incremental scroll without full-thread load; state must know “we are in anchor context” vs “latest tail”. The store already calls `getPreviousMessages({ conversationId, after })` for newer tail sync.

**Alternatives considered**:

- Ephemeral state only in component — rejected: scroll handlers and `MessageList` need shared truth.

## 5. Inline error + Retry (incremental load failure)

**Decision**: When `fetchPreviousMessages` / anchor-adjacent fetch fails, set `anchorLoadError` + last failed params; render a **Banner** or inline **inline** block (Tailwind) **inside** the conversation panel above the list with **Retry** dispatching the same request. **No toast-only** path for this failure (per FR-008).

**Rationale**: Matches clarification; keeps recovery in context.

**Alternatives considered**:

- Toast-only — rejected by spec.

## 6. Keyboard focus (FR-010)

**Decision**: After messages load and DOM updates, move focus to the **anchor message element** (`#message{id}` or `tabindex` wrapper on `components-next` bubble). Use `nextTick` + `focus()` on a focusable wrapper if the bubble is not natively focusable.

**Rationale**: Aligns with clarification and constitution accessibility principle.

**Alternatives considered**:

- Focus stay on pinned list — rejected by spec.

## 7. Enterprise / OSS

**Decision**: No new persisted entities; **no Enterprise fork** expected unless a controller override is found for `MessagesController`. Grep `enterprise/` for `MessagesController` / `MessageFinder` before merge.

**Rationale**: Constitution Enterprise compatibility.
