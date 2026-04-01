# Implementation Plan: Pin Multiple Messages

**Branch**: `[004-pin-multiple-messages]` | **Date**: 2026-03-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-pin-multiple-messages/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add support for pinning multiple messages within a conversation and exposing pinned messages in a dedicated area so agents can jump to key context without scrolling. Implement as a persisted per-conversation pinned set, with API endpoints for list/pin/unpin and dashboard UI integration in the message context menu and conversation view. **Spec revision (2026-03-30)**: the pinned region must follow **FR-011–FR-018** in [spec.md](./spec.md) (compact collapsible UI, rich previews, smooth jump, overflow handling, subtle unpin, visual hierarchy, responsiveness, Chatwoot UI alignment).

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Ruby 3.4.4 + Rails 7.1; Vue 3 (Composition API)  
**Primary Dependencies**: Rails API controllers; Pundit policies; Vue 3 dashboard; Vite build tooling  
**Storage**: PostgreSQL (ActiveRecord)  
**Testing**: RSpec (backend); pnpm test (frontend)  
**Target Platform**: Web application (server + browser dashboard)  
**Project Type**: Monolith Rails app with JS dashboard + widget  
**Performance Goals**: Pinned area loads instantly on conversation open; pin/unpin feels immediate for agents  
**Constraints**: No N+1 queries; keep pinned list small (max 20) and query-efficient; no custom CSS (Tailwind only)  
**Scale/Scope**: Many conversations per account; pinned list scoped per conversation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Code Quality & Consistency**: Follow RuboCop + ESLint; Vue Composition API; Tailwind-only styling; no dead code
- [x] **Testing Standards**: Happy path first; avoid specs unless necessary; keep tests independently runnable if added
- [x] **User Experience Consistency**: Use `components-next/` for message UI; no bare strings; ensure accessibility for pinned UI
- [x] **Performance Requirements**: Add indexes for new tables; avoid N+1; validate queries; keep pinned fetch bounded
- [x] **Enterprise Compatibility**: Use extension points (`prepend_mod_with`) where needed; check `enterprise/` for overrides

## Project Structure

### Documentation (this feature)

```text
specs/004-pin-multiple-messages/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
app/
├── controllers/
│   └── api/v1/accounts/conversations/   # new pinned-messages endpoints live here
├── models/                              # new pinned message model
└── services/                            # pin/unpin orchestration and limits

app/javascript/dashboard/
├── api/                                 # add API calls for pin/unpin + list pinned
├── routes/dashboard/conversation/        # pinned panel in ConversationView
└── components-next/message/             # integrate pin/unpin actions into message UI

config/routes.rb                          # route additions under conversations scope
db/migrate/                               # new table + indexes
```

**Structure Decision**: Web application structure (Rails API + Vue dashboard). Backend adds a small persisted join model between `Conversation` and `Message` plus account scoping. Frontend adds a pinned panel in the conversation view and pin/unpin actions in the existing message context menu.

## Complexity Tracking

No constitution violations required for this feature.

## Phase 0: Outline & Research (output: `research.md`)

- Confirm current API patterns for conversation-scoped resources and message context menu actions.
- Decide data model shape for pinned messages (fields, indexes, deletion behavior).
- Decide API contract (endpoints, payloads, errors).
- Decide realtime update strategy (initially request/response; optionally broadcast).

## Phase 1: Design & Contracts (outputs: `data-model.md`, `contracts/*`, `quickstart.md`)

- Define the `PinnedMessage` entity and validations.
- Define API endpoints and response shapes for:
  - list pinned messages for a conversation
  - pin message
  - unpin message
- Define minimal UI contract for pinned panel behavior (open, jump-to-message, empty state).
- Provide quickstart steps for a developer to manually verify in the dashboard.

## Phase 2: Implementation Planning

- Break the feature into small backend-first slices (migration/model/service/controller) then frontend slices (API client/store/UI components).
- Add indexing and query plan validation notes.
