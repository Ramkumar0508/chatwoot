# Implementation Plan: AI-Powered Conversation Handoff Summary

**Branch**: `001-ai-handoff-summary` | **Date**: 2026-03-14 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/001-ai-handoff-summary/spec.md`

## Summary

When an agent initiates a conversation transfer (to another agent or team), the system will generate a structured handoff summary via the existing LLM/Captain infrastructure. The summary will include customer intent, sentiment, key issues, and suggested next steps. The agent can review the summary before confirming; on confirm, the summary is inserted as a private note and the assignment is applied. The implementation reuses existing assignment API and private-note patterns; adds a handoff-summary preview endpoint and optional handoff_summary payload on assignment; and follows Captain/BaseTaskService pattern for LLM calls with a handoff-specific prompt.

## Technical Context

**Language/Version**: Ruby 3.4.4, Rails 7.1  
**Primary Dependencies**: Existing Captain/LLM stack (lib/captain/base_task_service.rb, Captain::SummaryService), Conversations::AssignmentService, Message (private notes)  
**Storage**: PostgreSQL (no new tables; handoff summary stored as Message with private: true and content_attributes flag for AI-generated)  
**Testing**: RSpec (backend), existing Vue/store tests for dashboard  
**Target Platform**: Chatwoot dashboard (Vue 3) and API (Rails)  
**Project Type**: Web application (Rails API + Vue frontend)  
**Performance Goals**: Summary generation within a few seconds (SC-001: transfer with summary in under 10s); graceful degradation if LLM unavailable  
**Constraints**: Summary generation must not block transfer (FR-006); use existing LLM token limits and conversation formatter (LlmFormatter::ConversationLlmFormatter)  
**Scale/Scope**: Single conversation transfer flow; one summary per transfer; simple UI (modal or inline preview)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|----------|--------|--------|
| I. Code Quality & Consistency | RuboCop, ESLint, Vue Composition API, Tailwind only, i18n (en.yml / en.json) | Compliant |
| II. Testing Standards | Pragmatic tests; avoid writing specs unless requested; use with_modified_env where needed | Compliant |
| III. User Experience Consistency | components-next for new UI; replaceInstallationName for branding; private note clearly labeled AI-generated | Compliant |
| IV. Performance Requirements | LLM call can be async or with short timeout; no N+1; assignment flow unchanged for latency | Compliant |
| Quality Gates | Lint, tests, Enterprise overlay check (assignments/conversations) | Pass |

No constitution violations. Enterprise overlay: assignment and Captain tasks have enterprise extensions; handoff summary will add OSS service and optionally enterprise override if needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-ai-handoff-summary/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 API contracts
└── tasks.md             # Phase 2 output (/speckit.tasks - not created by plan)
```

### Source Code (repository root)

```text
app/
├── controllers/api/v1/accounts/conversations/
│   ├── assignments_controller.rb     # Extend: accept handoff_summary, create note then assign
│   └── handoff_summary_controller.rb # New: preview endpoint (optional, or in captain/tasks)
├── services/
│   ├── conversations/
│   │   ├── assignment_service.rb     # Extend or hook: create private note when handoff_summary present
│   │   └── handoff_summary_service.rb # New: generate structured summary via LLM
│   └── llm_formatter/
│       └── conversation_llm_formatter.rb # Existing: used for conversation text for LLM
lib/
├── captain/
│   ├── base_task_service.rb         # Existing: pattern for HandoffSummaryService
│   └── handoff_summary_service.rb   # New (or under app/services): handoff prompt + LLM call
config/
├── routes.rb                         # Add handoff_summary preview route if new controller
└── locales/ (en.yml)                 # i18n for handoff summary UI

app/javascript/dashboard/
├── api/inbox/conversation.js         # Add getHandoffSummaryPreview, extend assignAgent/assignTeam if needed
├── store/modules/conversations/actions.js  # Optional: action for preview + assign with summary
└── routes/dashboard/conversation/
    └── ConversationAction.vue       # Or dedicated transfer modal: trigger preview, show summary, confirm → assign with summary

enterprise/ (if handoff summary is enterprise-gated)
└── app/controllers/api/v1/accounts/conversations/
    └── handoff_summary_controller.rb # Optional enterprise override
```

**Structure Decision**: Chatwoot is a single Rails app with Vue dashboard. Handoff summary adds a new service (reusing Captain/LLM pattern), optional preview endpoint, and extends the existing assignments flow. No new databases or background job required for MVP (sync LLM call with short timeout); async job can be Phase 2 if needed.

## Complexity Tracking

No constitution violations requiring justification. No complexity table entries.
