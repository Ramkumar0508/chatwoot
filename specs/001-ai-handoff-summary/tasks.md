# Tasks: AI-Powered Conversation Handoff Summary

**Input**: Design documents from `specs/001-ai-handoff-summary/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in the feature specification; no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Backend**: `app/`, `lib/`, `config/` at repository root
- **Frontend**: `app/javascript/dashboard/`
- **Routes**: `config/routes.rb`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prompt and i18n placeholders for handoff summary feature

- [ ] T001 Add handoff summary LLM prompt with structured sections (customer intent, sentiment, key issues, suggested next steps) in lib/integrations/openai/openai_prompts/handoff_summary.liquid
- [ ] T002 [P] Add i18n keys for handoff summary UI (labels, errors, limited-context message) in config/locales/en.yml and app/javascript/dashboard/i18n/locale/en/conversation.json

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Backend service and preview endpoint that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Implement HandoffSummaryService (conversation to LLM text, handoff prompt, return structured summary or error) in lib/captain/handoff_summary_service.rb following Captain::BaseTaskService pattern
- [ ] T004 Add POST handoff_summary route under account conversations in config/routes.rb
- [ ] T005 Create handoff summary preview controller that calls HandoffSummaryService and returns { summary, error } per contract in app/controllers/api/v1/accounts/conversations/handoff_summary_controller.rb

**Checkpoint**: Preview endpoint and service ready; assignment extension and frontend can proceed

---

## Phase 3: User Story 1 - Generate Handoff Summary on Transfer (Priority: P1) 🎯 MVP

**Goal**: When an agent transfers a conversation, the system can generate a summary and insert it as a private note on confirm.

**Independent Test**: Initiate transfer with handoff_summary provided; verify private note with summary and content_attributes handoff_summary: true is created and assignment completes.

### Implementation for User Story 1

- [ ] T006 [US1] Extend AssignmentsController to permit handoff_summary param and pass it to assignment flow in app/controllers/api/v1/accounts/conversations/assignments_controller.rb
- [ ] T007 [US1] When handoff_summary present create private note (Message with private: true, content_attributes: { handoff_summary: true }, sender: Current.user) then perform assignment in app/services/conversations/assignment_service.rb

**Checkpoint**: Backend supports transfer with handoff summary; API contract for assignments extended

---

## Phase 4: User Story 2 - Review Summary Before Transfer Completion (Priority: P2)

**Goal**: Agent sees the generated summary before confirming transfer and can confirm or cancel.

**Independent Test**: Open transfer flow, trigger summary preview, see summary in UI, confirm transfer and verify note appears; or cancel and verify no note and no assignment change.

### Implementation for User Story 2

- [ ] T008 [US2] Add getHandoffSummaryPreview(conversationId) and extend assignAgent/assignTeam to accept optional handoffSummary param in app/javascript/dashboard/api/inbox/conversation.js
- [ ] T009 [US2] Add store action to fetch handoff summary preview (call new API) in app/javascript/dashboard/store/modules/conversations/actions.js
- [ ] T010 [US2] In transfer flow (ConversationAction.vue or assign agent/team UI) show handoff summary preview and on confirm call assignAgent/assignTeam with handoff_summary in app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue

**Checkpoint**: Agent can review summary and complete or cancel transfer with summary

---

## Phase 5: User Story 3 - Handle Conversations Without Sufficient Context (Priority: P3)

**Goal**: Short or no-customer-message conversations get a brief summary or clear “limited context” message; transfer still completes.

**Independent Test**: Transfer conversation with 1–2 messages or no customer messages; verify brief summary or limited-context message and transfer completes.

### Implementation for User Story 3

- [ ] T011 [US3] In HandoffSummaryService handle short conversations and no customer messages: return brief summary or error/message for limited context in lib/captain/handoff_summary_service.rb
- [ ] T012 [US3] In handoff summary UI show limited-context or empty-summary message using i18n when summary is empty or error in app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue

**Checkpoint**: Edge cases handled; transfer never blocked

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: i18n completeness and validation

- [ ] T013 [P] Verify all handoff summary copy is in en.yml and en.json (no bare strings) in config/locales and app/javascript/dashboard/i18n
- [ ] T014 Run quickstart.md validation (manual): open conversation, trigger transfer with summary, confirm and cancel flows, short-conversation case

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies – can start immediately
- **Foundational (Phase 2)**: Depends on Setup (prompt and i18n keys) – BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational – backend only
- **User Story 2 (Phase 4)**: Depends on Foundational; uses US1 assignment API extension
- **User Story 3 (Phase 5)**: Depends on Foundational; extends same service and UI
- **Polish (Phase 6)**: Depends on US1–US3 complete

### User Story Dependencies

- **US1 (P1)**: After Foundational; no dependency on US2/US3
- **US2 (P2)**: After Foundational; needs US1 so assignment accepts handoff_summary
- **US3 (P3)**: After Foundational; can parallel with US2; extends HandoffSummaryService and same UI as US2

### Within Each User Story

- US1: Permit param (T006) then create note in assignment flow (T007)
- US2: API + store (T008, T009) then UI integration (T010)
- US3: Service behavior (T011) then UI message (T012)

### Parallel Opportunities

- T001 and T002 can run in parallel (Phase 1)
- T003, T004, T005: T004 and T005 can run in parallel after T003 (route + controller)
- T008 and T009 can run in parallel (Phase 4)
- T011 and T012 can run in parallel (Phase 5)
- T013 is [P] in Polish

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup  
2. Complete Phase 2: Foundational  
3. Complete Phase 3: User Story 1  
4. **STOP and VALIDATE**: Call preview endpoint and assignment with handoff_summary via API/curl; verify private note  
5. Deploy/demo backend capability

### Incremental Delivery

1. Setup + Foundational → Preview API and service ready  
2. Add US1 → Backend transfer-with-summary complete (MVP)  
3. Add US2 → Full UI: preview, review, confirm/cancel  
4. Add US3 → Short-conversation and limited-context handling  
5. Polish → i18n and quickstart validation

### Parallel Team Strategy

- One developer: Phases 1 → 2 → 3 → 4 → 5 → 6 in order  
- Two developers: After Foundational, Dev A: US1 + US3 backend (T006, T007, T011); Dev B: US2 + US3 frontend (T008–T010, T012)

---

## Notes

- No new DB tables or migrations; handoff summary is stored as a Message (private note)
- Enterprise: If handoff summary is gated by Captain/LLM, reuse existing captain_tasks_enabled? checks; consider enterprise override for handoff_summary_controller if product requires
- Follow constitution: Tailwind only, Composition API, i18n for all user-facing strings
