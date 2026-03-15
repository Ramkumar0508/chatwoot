# Data Model: AI-Powered Conversation Handoff Summary

**Feature**: 001-ai-handoff-summary  
**Date**: 2026-03-14

## Scope

This feature does **not** introduce new database tables or new persistent entities. It reuses existing models and adds a single new service plus optional request/response payloads.

## Existing Entities Used

### Conversation

- **Role**: Represents the conversation being transferred. Provides message history and metadata for LLM input.
- **Relevant attributes**: `id`, `display_id`, `account_id`, `assignee_id`, `team_id`, `messages` (association).
- **Usage**: Loaded by conversation_display_id; passed to LlmFormatter and HandoffSummaryService; assignment updated via existing AssignmentService.

### Message

- **Role**: Private notes are Message records with `private: true`. The handoff summary is stored as one such message.
- **Relevant attributes**: `content`, `private`, `content_attributes`, `sender`, `message_type`, `conversation_id`, `account_id`, `inbox_id`.
- **Validation**: Same as existing private notes (content present, private true). Optional `content_attributes[:handoff_summary] = true` or `content_attributes[:ai_generated] = true` to mark as AI-generated (FR-009).
- **Creation**: `conversation.messages.create!(account: ..., inbox: ..., sender: Current.user, message_type: :outgoing, content: summary_text, private: true, content_attributes: { handoff_summary: true })`.

### User / Team

- **Role**: Target of assignment (assignee_id or team_id). No change to these models.
- **Usage**: Existing assignment flow; handoff summary is created before or after assignment update.

## Logical “Handoff Summary” Concept

- **Handoff summary**: A structured text block (customer intent, sentiment, key issues, suggested next steps) produced by the LLM and optionally stored as a private note. It is not a first-class entity; it is the content of a Message created at transfer time.
- **Lifecycle**: Generated on demand when preview is requested; persisted only when the user confirms transfer and the backend creates the private note with that content.

## State Transitions

- **Conversation assignment**: Unchanged. Still: conversation has assignee_id/team_id updated via Conversations::AssignmentService. The only addition is an optional step before or after: create one Message (private note) with the handoff summary content.
- **No new state machines**: Summary generation is stateless (request → response); the only persistent state is the new Message row when transfer is confirmed.

## Validation Rules (from spec)

- FR-002: Summary MUST be stored as a private note (Message with `private: true`).
- FR-009: Note MUST be clearly labeled as AI-generated (content_attributes or convention).
- FR-008: Summary MUST be derived from existing conversation message history (no new stored “summary” entity; history is read at generation time).
