# Design: Multiple pinned messages per conversation (dashboard agents)

**Date:** 2026-04-02  
**Status:** Ready for implementation  
**Goal:** Agents can pin multiple messages in a conversation; pinned items stay easy to reach without scrolling the full thread.

## Decisions (requirements)

| Topic | Decision |
|--------|----------|
| Visibility | **Agents only** (dashboard). Not shown to contacts in widget/channels. |
| Access pattern | **Collapsible strip above the message list** when there is at least one pin. Collapsed: short summary (e.g. count). Expanded: full list with jump-to and unpin. |
| Pin-eligible messages | **Incoming, outgoing, and private notes.** **Exclude** activity/system messages. |
| Permissions | Any agent who **can view and act on** the conversation may **pin and unpin** (same bar as normal conversation actions). |

## Architecture recommendation

Use a **join table** (normalized model), not JSON on `conversations` or nullable columns on `messages`.

- **Pros:** Referential integrity, unique constraint per (conversation, message), audit fields, straightforward listing and caps.
- **Cons:** One new migration and model.

## Data model

- **Model name (suggested):** `ConversationMessagePin` (adjust to project naming if needed).
- **Columns:** `account_id`, `conversation_id`, `message_id`, `pinned_by_id` (User), `pinned_at` (default from creation time).
- **Constraints:** Unique index on `(conversation_id, message_id)`.
- **Indexes:** `(conversation_id)` for listing pins for a conversation.
- **Associations:** `Conversation` `has_many :conversation_message_pins, dependent: :destroy`; `Message` `has_many :conversation_message_pins, dependent: :destroy` (at most one row per conversation per message is enforced by the DB unique index on `(conversation_id, message_id)`); `User` as `pinned_by`.
- **List ordering:** By `pinned_at` **descending** (newest pin first) unless product later prefers another order.

## API

All under existing **account-scoped** conversation routes (match Chatwoot `Api::V1::Accounts::...` style).

| Action | Path pattern |
|--------|----------------|
| Index | `GET /api/v1/accounts/:account_id/conversations/:conversation_id/pins` |
| Create | `POST /api/v1/accounts/:account_id/conversations/:conversation_id/pins` |
| Destroy | `DELETE /api/v1/accounts/:account_id/conversations/:conversation_id/pins/:pin_id` |

**Create body:** `{ message_id }`.

**Validation (create):**

- Message belongs to the conversation (and account).
- Message type is pin-eligible (not activity/system).
- Enforce **soft max** pins per conversation (e.g. **50**, constant in service layer) with a clear error response.

**Authorization:** Pundit (or equivalent) aligned with **acting on the conversation**—same as requirement A.

**Destroy / IDOR:** Load the pin only through `current_account` → `conversation` → `pins` (nested scope). Reject if `pin_id` does not belong to that conversation or account—never look up `pin_id` globally.

**Private-note previews:** Index payloads and strip copy must respect the **same rules as rendering that message in the thread**. If the current user must not see a private note, **omit that pin from the index**, or return a **redacted placeholder** without content—do not leak note body through `text_preview`.

**Payload:** Compact pin objects: `id`, `message_id`, `pinned_at`, `pinned_by` (minimal user fields), and `text_preview` (see below).

**`text_preview` contract:**

- **Format:** Plain text only; strip HTML/markdown to a safe one-line string server-side.
- **Max length:** **200 characters** (constant), with ellipsis truncation.
- **Source:** Derived from the same sanitized/plain path used elsewhere for message snippets, so behavior stays consistent with search and notifications where applicable.

## Realtime

- On create and destroy, **broadcast** on the existing **conversation ActionCable channel** (same family as message updates) so other agents with the conversation open see the strip update without a full reload.
- **Authorization:** Only clients **already authorized** to subscribe to that conversation channel receive events—reuse the same subscription and access checks as other conversation broadcasts; do not add a separate unauthenticated pin feed.
- Payload: minimal ids + pin attributes, or event type + ids for client-side merge. Apply the same **private-note / preview** rules as the index when building payload attributes.

## Lifecycle and cleanup

- **Message deleted:** Remove associated pin rows (`dependent: :destroy` on `Message` → pins, or equivalent). No ghost entries in the strip.
- **Conversation deleted:** Destroy pins with the conversation (`dependent: :destroy` on `Conversation` → pins) or DB `ON DELETE CASCADE` on `conversation_id`.
- **User (`pinned_by`) deleted:** Follow existing app conventions for `users` foreign keys (nullify `pinned_by_id` if the column is optional, restrict if hard-delete is disallowed, or retain id if users are soft-deleted—match `messages` / other audited tables).

## Frontend

- **Component:** New strip component (e.g. `PinnedMessagesStrip.vue`), placed **above** the scrollable message list in the conversation view hierarchy.
- **State:** Per active conversation: list of pins; **fetch on conversation change** via dedicated index endpoint (initial iteration); merge **Cable** events.
- **Context menu:** On eligible messages in **components-next** bubbles, add **Pin** / **Unpin** (or toggle) alongside existing actions.
- **Jump-to:** Reuse existing scroll-to-message patterns; apply a **brief Tailwind highlight** on the target bubble, then clear.
- **i18n:** Add strings to **`en.json`** (and **`en.yml`** only if server-rendered messages need them).

## Enterprise

- Search **`enterprise/`** for conversation/message API overrides; keep contracts and policy behavior compatible (mirror routes or use extension points—no silent drift).

## Testing (suggested)

- **Request specs:** index/create/destroy—success, unauthorized, ineligible message type, duplicate pin, cap exceeded, **destroy with pin_id for another conversation/account (404)**, **index omits or redacts private notes** the actor cannot see.
- **Optional:** model uniqueness.
- **Frontend:** Only where similar UI already has tests; otherwise document **How to test** in the PR (two agents, pin/unpin, jump, delete message clears pin).

## Out of scope (v1)

- Contact-visible pins.
- Manual reorder of pins (order is `pinned_at` desc unless changed later).
- Pin icon on every bubble outside the context menu.
