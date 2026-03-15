# Feature Specification: AI-Powered Conversation Handoff Summary

**Feature Branch**: `001-ai-handoff-summary`  
**Created**: 2026-03-14  
**Status**: Draft  
**Input**: User description: "When an agent is about to transfer a conversation to another agent or team, auto-generate a structured handoff summary using an LLM — including customer intent, sentiment, key issues discussed, and suggested next steps — and insert it as a private note."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate Handoff Summary on Transfer (Priority: P1)

As an agent transferring a conversation to another agent or team, I want the system to automatically generate a structured summary of the conversation so that the receiving agent can quickly understand the context without reading the entire conversation history.

**Why this priority**: This is the core feature. Without the ability to generate and insert a summary during transfer, the feature has no value. This directly addresses the pain point of agents spending time reading through conversation history during handoffs.

**Independent Test**: Can be fully tested by initiating a conversation transfer and verifying that a private note with the summary appears. Delivers immediate value by reducing handoff friction.

**Acceptance Scenarios**:

1. **Given** an agent has an active conversation with message history, **When** the agent initiates a transfer to another agent, **Then** the system generates a structured summary and inserts it as a private note visible only to agents.

2. **Given** an agent initiates a transfer to a team, **When** the transfer is confirmed, **Then** the generated summary appears as a private note before the conversation is reassigned.

3. **Given** a conversation with multiple back-and-forth exchanges, **When** a summary is generated, **Then** the summary includes: customer intent, sentiment assessment, key issues discussed, and suggested next steps.

---

### User Story 2 - Review Summary Before Transfer Completion (Priority: P2)

As an agent, I want to review the AI-generated summary before completing the transfer so that I can verify it captures the essential context accurately.

**Why this priority**: Agents need confidence that the summary accurately represents the conversation. This provides a safety net without blocking the core functionality.

**Independent Test**: Can be tested by triggering a transfer, viewing the generated summary in the transfer flow, and then completing or canceling the transfer.

**Acceptance Scenarios**:

1. **Given** an agent clicks the transfer button, **When** the system generates the summary, **Then** the agent can see the summary before confirming the transfer.

2. **Given** the agent reviews the summary and finds it acceptable, **When** they confirm the transfer, **Then** the summary is inserted as a private note and the transfer completes.

3. **Given** the agent reviews the summary, **When** they cancel the transfer, **Then** no summary is inserted and the conversation remains with the original agent.

---

### User Story 3 - Handle Conversations Without Sufficient Context (Priority: P3)

As an agent transferring a very short conversation (e.g., only 1-2 messages), I want the system to handle this gracefully so that I'm not blocked from completing the transfer.

**Why this priority**: Edge case handling ensures the feature works reliably across all conversation lengths. Lower priority because most conversations have enough context.

**Independent Test**: Can be tested by attempting to transfer a conversation with minimal messages and verifying the system either generates a brief summary or gracefully indicates insufficient context.

**Acceptance Scenarios**:

1. **Given** a conversation with only 1-2 messages, **When** an agent initiates transfer, **Then** the system generates a brief summary based on available information or displays a message indicating limited context.

2. **Given** a conversation with no customer messages (only agent-initiated), **When** transfer is initiated, **Then** the system indicates no customer context is available and allows the agent to proceed with an optional manual note.

---

### Edge Cases

- What happens when the LLM service is temporarily unavailable? The transfer should still complete, with an indication that the summary could not be generated.
- What happens when the conversation contains only attachments with no text? The system should indicate that the conversation contains non-text content and provide a minimal summary.
- What happens when the conversation is in a language not supported by the LLM? The system should attempt to generate a summary or indicate the language limitation.
- What happens when multiple transfers occur in sequence? Each transfer should generate a new summary reflecting the current state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST generate a structured handoff summary when an agent initiates a conversation transfer to another agent or team.
- **FR-002**: The generated summary MUST be inserted as a private note (visible only to agents, not customers).
- **FR-003**: The summary MUST include the following sections: customer intent, sentiment assessment, key issues discussed, and suggested next steps.
- **FR-004**: System MUST display the generated summary to the transferring agent before the transfer is completed.
- **FR-005**: Agents MUST be able to complete the transfer after reviewing the summary (no mandatory editing required).
- **FR-006**: System MUST allow transfers to complete even if summary generation fails (graceful degradation).
- **FR-007**: The summary generation MUST NOT significantly delay the transfer workflow (summary should appear within a few seconds).
- **FR-008**: System MUST use the existing conversation message history as input for summary generation.
- **FR-009**: The private note containing the summary MUST be clearly labeled as AI-generated.

### Key Entities

- **Handoff Summary**: A structured text block containing customer intent, sentiment, key issues, and next steps. Associated with a conversation transfer event. Stored as a private note message.
- **Transfer Event**: The action of reassigning a conversation from one agent to another agent or team. Triggers summary generation.
- **Private Note**: An existing message type visible only to agents. Used to store the generated summary.

## Assumptions

- The account has LLM/AI capabilities enabled (Captain or equivalent AI service configured).
- Conversation transfers to agents and teams already exist in the system.
- Private notes functionality already exists in conversations.
- The LLM service can process conversation history and return structured summaries.
- Summary generation targets conversations with at least 3+ messages for meaningful context.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Agents can complete a conversation transfer with an AI-generated summary in under 10 seconds (including summary generation time).
- **SC-002**: 90% of generated summaries accurately capture the primary customer intent as validated by the transferring agent (no cancellation or re-transfer due to poor summary).
- **SC-003**: Receiving agents spend 50% less time reviewing conversation history before responding to transferred conversations.
- **SC-004**: Summary generation succeeds for 95% of transfer attempts (graceful fallback for the remaining 5%).
- **SC-005**: Zero customer-visible impact—summaries appear only as private notes, never exposed to customers.
