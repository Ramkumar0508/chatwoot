# Research: Pin Multiple Messages

**Date**: 2026-03-30  
**Feature**: [spec.md](./spec.md)

## Decisions

### Decision 1: Persist pins as a conversation↔message join table

**Decision**: Represent pinned messages as a dedicated entity that associates a `conversation_id` with a `message_id` (unique per pair).

**Rationale**:

- Pins must persist across visits and be shared across authorized staff (spec FR-004, FR-010).
- A join entity supports uniqueness, indexing, auditing fields (who pinned), and future extensions (ordering, notes).

**Alternatives considered**:

- Store pinned IDs in `conversations.additional_attributes`: simpler but less queryable/indexable and harder to enforce uniqueness/limits cleanly.
- Store a boolean flag on `messages`: incorrect because pinning is per-conversation and messages already belong to one conversation; it also complicates constraints and ordering.

### Decision 2: API endpoints are conversation-scoped

**Decision**: Add conversation-scoped endpoints under the existing `Api::V1::Accounts::Conversations::BaseController` authorization boundary.

**Rationale**:

- Existing controllers already authorize the conversation via `ConversationPolicy#show?`.
- Keeps routes consistent with existing message endpoints nested under conversations.

**Alternatives considered**:

- Account-level endpoints keyed by message ID: harder to authorize and less consistent with existing structure.

### Decision 3: Max pinned messages per conversation = 20

**Decision**: Enforce a hard max of 20 pinned messages per conversation.

**Rationale**:

- Keeps the pinned panel usable, keeps queries bounded, aligns with spec FR-007.

**Alternatives considered**:

- Unlimited: risk of UI clutter and performance regressions.
- Configurable limit: adds scope and product surface area without a stated need.

### Decision 4: “Unavailable pinned message” maps to “deleted message”

**Decision**: Treat messages marked as deleted (via message deletion flow) as unavailable in the pinned panel; the pinned association may remain for audit but is omitted from list results.

**Rationale**:

- Message deletion in Chatwoot updates content and sets a `deleted` flag in content attributes (message row remains).
- Spec expects pinned area to omit unavailable messages and show a non-blocking notice (FR-009 / User Story 2 scenario 3).

**Alternatives considered**:

- Auto-unpin on delete: cleaner list but loses audit trail and can surprise agents.
- Keep showing deleted messages in pinned list: does not satisfy “unavailable” intent.

### Decision 5: Initial delivery is request/response (no realtime broadcast requirement)

**Decision**: Pinned list updates are guaranteed on page refresh/revisit and after local pin/unpin actions; realtime syncing to other agents can be added using existing dispatch/broadcast mechanisms if needed.

**Rationale**:

- Spec requires shared visibility but does not require immediate realtime propagation.
- Minimizes scope; avoids introducing new websocket events unless product needs it.

**Alternatives considered**:

- Broadcast pinned-updated events: better collaboration but adds complexity and more moving parts across backend/frontend.

