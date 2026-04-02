# Design: Multiple pinned messages per conversation (dashboard agents)

**Date:** 2026-04-02  
**Status:** Approved (brainstorming)  
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
- **Associations:** `Conversation` has_many pins; `Message` has_one or has_many pins per conversation (enforced by uniqueness); `User` as `pinned_by`.
- **List ordering:** By `pinned_at` **descending** (newest pin first) unless product later prefers another order.

## API

All under existing **account-scoped** conversation routes (match Chatwoot API conventions).

| Action | Suggested shape |
|--------|------------------|
| Index | `GET .../accounts/:account_id/conversations/:id/pins` (or `pinned_messages`) |
| Create | `POST .../conversations/:id/pins` with body `{ message_id }` |
| Destroy | `DELETE .../conversations/:id/pins/:pin_id` |

**Validation (create):**

- Message belongs to the conversation (and account).
- Message type is pin-eligible (not activity/system).
- Enforce **soft max** pins per conversation (e.g. **50**, constant in service layer) with a clear error response.

**Authorization:** Pundit (or equivalent) aligned with **acting on the conversation**—same as requirement A.

**Payload:** Compact pin objects: id, message_id, pinned_at, pinned_by (minimal user fields), and a **text preview** suitable for the strip without loading the entire message thread.

## Realtime

- On create and destroy, **broadcast** on the existing **conversation ActionCable channel** (same family as message updates) so other agents with the conversation open see the strip update without a full reload.
- Payload: minimal ids + pin attributes, or event type + ids for client-side merge.

## Deleted messages

- When a message is **deleted**, **remove** associated pin rows (association `dependent: :destroy` on `Message`, or equivalent service hook). No ghost entries in the strip.

## Frontend

- **Component:** New strip component (e.g. `PinnedMessagesStrip.vue`), placed **above** the scrollable message list in the conversation view hierarchy.
- **State:** Per active conversation: list of pins; **fetch on conversation change** via dedicated index endpoint (initial iteration); merge **Cable** events.
- **Context menu:** On eligible messages in **components-next** bubbles, add **Pin** / **Unpin** (or toggle) alongside existing actions.
- **Jump-to:** Reuse existing scroll-to-message patterns; apply a **brief Tailwind highlight** on the target bubble, then clear.
- **i18n:** Add strings to **`en.json`** (and **`en.yml`** only if server-rendered messages need them).

## Enterprise

- Search **`enterprise/`** for conversation/message API overrides; keep contracts and policy behavior compatible (mirror routes or use extension points—no silent drift).

## Testing (suggested)

- **Request specs:** index/create/destroy—success, unauthorized, ineligible message type, duplicate pin, cap exceeded.
- **Optional:** model uniqueness.
- **Frontend:** Only where similar UI already has tests; otherwise document **How to test** in the PR (two agents, pin/unpin, jump, delete message clears pin).

## Out of scope (v1)

- Contact-visible pins.
- Manual reorder of pins (order is `pinned_at` desc unless changed later).
- Pin icon on every bubble outside the context menu.
