# Research: AI-Powered Conversation Handoff Summary

**Feature**: 001-ai-handoff-summary  
**Date**: 2026-03-14

## 1. Where to Hook Handoff Summary Generation

**Decision**: Generate summary when the agent initiates transfer; show preview in UI; on confirm, send summary with assignment request so backend creates private note then assigns.

**Rationale**:
- Assignments today: `POST /api/v1/accounts/:account_id/conversations/:conversation_id/assignments` with `assignee_id` or `team_id`. No existing "preview" step.
- Spec requires "display the generated summary to the transferring agent before the transfer is completed" (FR-004). So flow must be: (1) agent selects assignee/team and triggers "transfer", (2) backend or frontend fetches handoff summary, (3) UI shows summary, (4) agent confirms, (5) backend creates private note with summary and performs assignment.
- **Chosen approach**: New endpoint `POST .../conversations/:id/handoff_summary` (or under Captain tasks) returns `{ summary: "..." }` without persisting. Frontend calls it when user opens transfer flow or clicks "Transfer"; shows summary in a simple modal/panel; on "Confirm", frontend calls existing assignments API with new optional param `handoff_summary: summary_text`. Backend (AssignmentsController or AssignmentService) creates private note with that text (and content_attributes marking AI-generated) then performs assignment. This keeps assignment API backward-compatible and avoids two-phase assignment.

**Alternatives considered**:
- Generate summary inside AssignmentsController when a flag is set: would require first request to return summary and not assign, then second request to assign with stored summary—more state and race conditions.
- Background job to generate summary after assignment: would not satisfy "display before transfer is completed."

## 2. LLM Integration and Prompt Shape

**Decision**: Reuse Captain/BaseTaskService pattern; add a dedicated handoff-summary prompt that instructs the model to output structured sections (customer intent, sentiment, key issues, suggested next steps).

**Rationale**:
- `Captain::SummaryService` (lib/captain/summary_service.rb) already takes `conversation_display_id`, uses `conversation.to_llm_text`, and calls LLM with a prompt from file. Same pattern fits handoff: new service (e.g. `Captain::HandoffSummaryService` or `Conversations::HandoffSummaryService`) with handoff-specific prompt.
- `LlmFormatter::ConversationLlmFormatter` and `conversation.to_llm_text` (include_contact_details, include_private_messages) already format conversation for LLM. Use same input for handoff summary.
- Prompt file (e.g. handoff_summary) should require structured output: "Customer intent:", "Sentiment:", "Key issues discussed:", "Suggested next steps:" so the note is consistent and parseable. Plain text block is acceptable; no need for JSON for MVP.

**Alternatives considered**:
- Reusing generic "summary" prompt: would not guarantee intent/sentiment/next steps sections; handoff-specific prompt is minimal effort and matches spec.
- JSON schema for summary: adds parsing and validation; spec says "structured" but does not require machine-readable fields; free-form sections are sufficient.

## 3. Where to Create the Private Note (Backend)

**Decision**: When assignments API is called with `handoff_summary` present, create the private note in the same request (before or after updating assignee/team) using existing Message creation pattern.

**Rationale**:
- Automation and macros already create private notes via `conversation.messages.create!(content: ..., private: true)` (e.g. `AutomationRules::ActionService#add_private_note`, `Macros::ExecutionService#add_private_note`). Same pattern: create message with `private: true`, sender: Current.user, and `content_attributes: { handoff_summary: true }` or similar to mark as AI-generated (FR-009).
- Creating the note in the assignment request ensures atomicity from the user's perspective: "confirm transfer" does one round-trip and the note appears with the new assignee/team. No need for a separate "create handoff note" endpoint for the confirm step.

**Alternatives considered**:
- Frontend creates note via messages API then calls assignments: two requests, possible ordering issues; worse UX.
- Background job creates note after assignment: note might be delayed; spec says "insert it as a private note" at transfer time.

## 4. Graceful Degradation When LLM Unavailable

**Decision**: If handoff summary generation fails (LLM error, timeout, or Captain disabled), return a clear error or empty summary from the preview endpoint; allow assignment to proceed without summary when `handoff_summary` is not sent (user can leave note manually or skip). Do not block assignment when preview was never requested or failed.

**Rationale**:
- FR-006: "System MUST allow transfers to complete even if summary generation fails."
- Preview endpoint returns `{ summary: null, error: "..." }` or `{ summary: "" }`; frontend shows "Summary unavailable" and still offers "Transfer without summary" / "Confirm" so assignment can complete. Assignments API remains unchanged when `handoff_summary` is omitted.

## 5. OSS vs Enterprise Placement

**Decision**: Implement handoff summary in OSS using existing Captain/LLM task pattern (lib/captain or app/services). Gate availability on existing Captain/LLM configuration (e.g. captain_tasks_enabled?, api_key_configured?) so behavior is consistent with summarize/reply_suggestion. If product decision is to make this enterprise-only later, an enterprise override can restrict the endpoint or service.

**Rationale**:
- Captain::BaseTaskService and SummaryService live in lib/; Captain tasks controller is in enterprise but the service layer is OSS. Handoff summary can follow the same pattern; if only enterprise accounts have LLM configured, the feature effectively runs only there until OSS exposes LLM more broadly.
- No new tables or premium feature flags required for MVP; re-use existing Captain checks.

## 6. UI Flow (Simple)

**Decision**: Minimal UI: when agent chooses "Assign agent" or "Assign team", optionally trigger a "Generate handoff summary" action (or auto-trigger). Show result in a simple modal or inline panel with "Transfer" and "Cancel". On "Transfer", send assignment request with `handoff_summary` if present. No rich editor for the summary; read-only display with optional "Copy" or "Include in transfer" checkbox (default on when summary exists).

**Rationale**:
- Spec: "Don't concentrate on better UI. Just simple UI AI Generated UI is enough." So no custom editor, no formatting controls—display the generated text and one confirm action.
