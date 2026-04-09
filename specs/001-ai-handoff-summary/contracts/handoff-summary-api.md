# API Contract: Handoff Summary

**Feature**: 001-ai-handoff-summary  
**Date**: 2026-03-14

## 1. Preview Handoff Summary (New)

Generate a structured handoff summary for a conversation. Does not persist; used to show the agent a preview before confirming transfer.

### Request

- **Method**: POST  
- **Path**: ` /api/v1/accounts/:account_id/conversations/:conversation_id/handoff_summary`  
  (Alternative: under Captain tasks, e.g. `POST .../captain/tasks/handoff_summary` with body `{ conversation_display_id }`.)

- **Headers**: Same as existing API (Authorization, etc.).  
- **Body**: Optional empty `{}` or `{ conversation_display_id: <id> }` if path does not include conversation id.

### Response (Success)

- **Status**: 200  
- **Body**:
  - `summary` (string): Structured text with sections (customer intent, sentiment, key issues, suggested next steps). Empty string if generation failed but request was valid.
  - `error` (string, optional): Present when summary could not be generated (e.g. LLM unavailable). Frontend may still allow transfer without summary.

Example:

```json
{
  "summary": "**Customer intent:** ...\n**Sentiment:** ...\n**Key issues:** ...\n**Suggested next steps:** ..."
}
```

Or on failure:

```json
{
  "summary": null,
  "error": "Summary could not be generated. You can still transfer without a summary."
}
```

### Response (Error)

- **Status**: 404 if conversation not found or not in account.  
- **Status**: 403 if Captain/LLM not enabled (optional; can return 200 with null summary instead).  
- **Status**: 422 if conversation_display_id invalid.

### Side effects

None. No message is created; no assignment is changed.

---

## 2. Create Assignment (Extended)

Existing endpoint; extended to accept an optional handoff summary that is stored as a private note before or after the assignment is updated.

### Request

- **Method**: POST  
- **Path**: ` /api/v1/accounts/:account_id/conversations/:conversation_id/assignments`  
- **Body** (existing): `assignee_id` (optional), `team_id` (optional), `assignee_type` (optional).  
- **Body** (new, optional): `handoff_summary` (string). If present and non-empty, backend creates a private note with this content (and content_attributes marking it as AI-generated) then performs the assignment as today.

### Behavior

1. If `handoff_summary` is present and non-empty: create a Message on the conversation with `content: handoff_summary`, `private: true`, `content_attributes: { handoff_summary: true }` (or equivalent), sender Current.user.
2. Then perform assignment as today (set assignee_id and/or team_id per request).
3. Response unchanged: same as current assignments endpoint (assignee or team payload).

### Response

Unchanged from current API: 200 with assignee or team JSON; 4xx on validation/authorization errors.

### Backward compatibility

- If `handoff_summary` is omitted or blank, behavior is identical to current implementation (no note created).
