# Contract: Messages index — load around anchor

**Date**: 2026-03-31  
**Feature**: [../spec.md](../spec.md)  
**Related**: [../004-pin-multiple-messages/contracts/pinned-messages-api.md](../004-pin-multiple-messages/contracts/pinned-messages-api.md)

## Purpose

Support **FR-003–FR-005** by returning a **contiguous** slice of messages around a focal message in one request, instead of relying on repeated “scroll to top” loads.

## Endpoint

**Method**: GET  
**Path**: `/api/v1/accounts/:account_id/conversations/:conversation_id/messages`

## Query parameters

| Name | Required | Description |
|------|----------|-------------|
| `around_message_id` | No | When set, response is a window around this message id (must belong to the conversation). |
| `before_limit` | No | With `around_message_id`, max older messages to include (strictly before anchor). Server applies a cap. |
| `after_limit` | No | With `around_message_id`, max newer messages to include (strictly after anchor). Server applies a cap. |

**Precedence** (recommended):

- If `around_message_id` is present, it **takes precedence** over `before` / `after` pair loading modes for that request.

**Existing parameters** (`before`, `after`, `filter_internal_messages`) remain unchanged when `around_message_id` is absent.

## Response

**200**: Same JSON structure as the current messages index (payload array + meta).

**Payload ordering**: Messages sorted ascending by `created_at` (consistent with existing index behavior).

**Anchor inclusion**: The message with `id == around_message_id` MUST appear exactly once in `payload` when it exists and passes the same visibility filters as other messages in `MessageFinder`.

## Errors

| Code | When |
|------|------|
| 401/403 | Unauthorized / cannot view conversation |
| 404 | Conversation not found |
| 422 | `around_message_id` missing message, wrong conversation, or invalid |

## Notes

- Limits MUST be bounded server-side to avoid unbounded responses (performance constitution).
- Widget/mobile clients may ignore `around_message_id` until needed; dashboard UX is the primary consumer.
