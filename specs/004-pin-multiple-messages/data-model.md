# Data Model: Pin Multiple Messages

**Date**: 2026-03-30  
**Feature**: [spec.md](./spec.md)

## Entities

### ConversationPinnedMessage

**Purpose**: Represents a pinned message within a conversation (unique per conversation+message).

**Fields**:

- **id**: Unique identifier
- **account_id**: Owning account (derived from conversation; stored for scoping and indexing)
- **conversation_id**: Conversation where the pin applies
- **message_id**: The pinned message (must belong to the same conversation)
- **pinned_by_id**: Staff user who pinned the message (optional but recommended for auditing)
- **created_at / updated_at**: Timestamps

**Relationships**:

- Conversation has many ConversationPinnedMessages
- Message has many ConversationPinnedMessages (in practice: a message belongs to one conversation, but pin association is still explicit)

**Validation rules**:

- `conversation_id`, `message_id`, `account_id` must be present
- Uniqueness: `(conversation_id, message_id)` must be unique
- Integrity: `message.conversation_id` must equal `conversation_id`
- Limit: max 20 pinned messages per conversation (enforced at the service layer)

**Indexes**:

- Unique index on `(conversation_id, message_id)` to prevent duplicates
- Index on `(conversation_id, created_at)` to list pins efficiently
- Index on `(account_id, conversation_id)` to keep account scoping fast

## State / Lifecycle Notes

- Pinning adds an association; unpinning removes it.
- If a message is “deleted” (soft-delete behavior via content attributes), list endpoints omit it from results and provide an “unavailable pinned messages” indicator.

