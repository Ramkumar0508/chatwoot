# Data model: Pinned messages UX improvements

**Feature**: [spec.md](./spec.md)  
**Date**: 2026-03-31

## Persisted entities

No new database tables. This feature **reuses**:

- `ConversationPinnedMessage` (join) and `Message` (see [../004-pin-multiple-messages/data-model.md](../004-pin-multiple-messages/data-model.md)).

## API / request shape (messages index extension)

**Conceptual**: `GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages`

| Query param | Type | Notes |
|-------------|------|--------|
| `around_message_id` | integer | Message id **belonging to the conversation**; load a window around this message. Mutually exclusive with ad-hoc `before`/`after` **or** defined precedence must be documented in contract. |
| `before_limit` | integer (optional) | Max messages **strictly before** anchor (default TBD in implementation, e.g. 20). |
| `after_limit` | integer (optional) | Max messages **strictly after** anchor (default e.g. 20). |

**Response**: Same envelope as existing messages index (`payload` + `meta` as today); `payload` ordered by `created_at` ascending, **including** the anchor `Message` once.

**Validation**:

- `around_message_id` MUST resolve to a message in `@conversation.messages` (or same scope as `MessageFinder`); otherwise **404** or **422** with stable error body (match existing API error style).

## Client-side state (Vuex)

| State key | Purpose |
|-----------|---------|
| `anchorMessageId` / `anchorMode` | Conversation is showing a **focused window** around a pinned (or deep-linked) message. |
| `anchorLoadError` | `{ message, retryPayload }` or null — drives inline **Retry** (FR-008). |
| `pinnedStripExpanded` | UI-only; **default false** on conversation open (per spec). |

**Transitions**:

1. **Open conversation (has pins)** → `pinnedStripExpanded = false`, clear `anchor*` unless route has `messageId` query.
2. **User selects pin** → dispatch `fetchMessagesAround({ messageId })` → set `anchorMessageId`, replace/merge messages, scroll + focus.
3. **Scroll up** → existing “load older” path with `before: firstMessageId`.
4. **Scroll down** → load newer using `after` param (verify parity with existing actions).
5. **Retry** → re-run last failed fetch.

## Relationships

- `Pinned message reference` → `Message.id` used as `around_message_id`.
- Conversation `messages[]` in store remains the **source of truth** for `MessageList` rendering.
