# Contract: Pinned Messages API

**Date**: 2026-03-30  
**Feature**: [../spec.md](../spec.md)

## Authorization

All endpoints require the requester to be authorized to view the conversation (same authorization boundary as other conversation-scoped endpoints).

## Endpoints

### List pinned messages

**Method**: GET  
**Path**: `/api/v1/accounts/:account_id/conversations/:conversation_id/pinned_messages`

**Response (200)**:

- `pinned_messages`: array of pinned message objects
- `has_unavailable_pins`: boolean (true if some pinned associations exist but are omitted due to message unavailability)

**Pinned message object**:

- `id`: pinned association id
- `message_id`: pinned message id
- `conversation_id`: conversation display id (consistent with existing conversation-scoped APIs)
- `created_at`: unix timestamp (seconds)
- `pinned_by_id`: user id (if available)
- `message`: message payload sufficient to render a compact pinned item and support jump-to-message (id, created_at, content preview, sender summary, attachments summary, deleted flag)

**Errors**:

- 401/403: unauthorized
- 404: conversation not found

### Pin a message

**Method**: POST  
**Path**: `/api/v1/accounts/:account_id/conversations/:conversation_id/pinned_messages`

**Body**:

- `message_id` (required)

**Response**:

- 200 with the pinned association (id + message_id) when already pinned (idempotent)
- 201 with the new pinned association when newly created

**Errors**:

- 422: message does not belong to conversation, or limit reached (20)

### Unpin a message

**Method**: DELETE  
**Path**: `/api/v1/accounts/:account_id/conversations/:conversation_id/pinned_messages/:message_id`

**Response**:

- 200 with `{ success: true }` (idempotent even if not pinned)

**Errors**:

- 401/403: unauthorized
- 404: conversation not found

## Notes

- The contract assumes message deletion is represented as “deleted” in message attributes (soft deletion) and should not be included in `pinned_messages`.

