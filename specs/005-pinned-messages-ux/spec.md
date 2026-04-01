# Feature Specification: Pinned messages UX improvements

**Feature Branch**: `005-pinned-messages-ux`  
**Created**: 2026-03-30  
**Status**: Draft  
**Input**: User description: "Already implemented the pinned message in our app which is good and working fine. Need to improve the user experience. Current: Only able to see the pinned message after scrolling all messages at the top. Need: make it sticky at the top and make it visible always. Since it is collapsible hope it is fine, so that we can easily access the pinned message. In this case, when selecting top or middle pinned message, do not scroll all messages and then jump to that message; instead, load the message before and after the pinned message. Based on scroll up/down load the message."

## Clarifications

### Session 2026-03-30

- Q: When opening a pinned message, how does the agent return to the latest messages? → A: No dedicated shortcut; return is by scrolling.
- Q: What should be the default state of the sticky pinned area when opening a conversation that has pinned messages? → A: Collapsed by default (compact header or handle remains visible).
- Q: If loading older or newer messages around a pinned message fails, what should the product do? → A: Show an inline error in the conversation area with a Retry action.
- Q: When there are many pinned messages that do not all fit in the sticky area, which pattern should the product standardize on? → A: Show a limited preview and a control to open the full pinned list.
- Q: After opening a pinned message and showing it with surrounding context, where should keyboard focus land? → A: On the pinned message (or its focusable container in the thread).

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Sticky, always-accessible pinned area (Priority: P1)

Agents need to see and use pinned messages without scrolling the full conversation history to the top. The pinned content stays reachable via a sticky area at the top of the conversation view: **by default it is collapsed** (compact header or handle visible), and the agent can expand it when they need the full list, so it does not permanently block the reading area.

**Why this priority**: If pinned items are hard to reach, the feature fails its primary purpose (quick reference). This directly fixes the reported pain.

**Independent Test**: Open a long conversation with pinned messages; verify pinned content remains reachable from the default reading position without manually scrolling to the oldest part of the thread.

**Acceptance Scenarios**:

1. **Given** a conversation with at least one pinned message and a long message history, **When** the agent opens the conversation, **Then** the sticky pinned area appears in its **collapsed** default state with a visible affordance to expand it.
2. **Given** a conversation with pinned messages, **When** the agent scrolls through recent messages, **Then** the pinned-message area (collapsed or expanded) remains available at the top of the conversation view without scrolling the full backlog to find pins.
3. **Given** the pinned area supports collapse, **When** the agent collapses it, **Then** a clear affordance remains to expand it again without losing access to pinned content.
4. **Given** multiple pinned messages, **When** the agent expands the sticky area, **Then** they can review the list of pins without scrolling the entire message list to find pins.
5. **Given** more pinned messages than fit in the sticky preview, **When** the agent views the sticky area, **Then** they see a **limited preview** and a clear control to open the **full** pinned list so no pins are silently hidden.

---

### User Story 2 - Contextual loading when opening a pinned message (Priority: P2)

When the agent selects a pinned message that sits earlier in the thread (not only the latest messages), the product should open that location by showing the pinned message with immediate context (messages before and after it), instead of forcing a long scroll through every intervening message or a disruptive jump after loading everything.

**Why this priority**: Reduces time-to-reference and cognitive load when pins are deep in history; complements sticky pins for end-to-end usability.

**Independent Test**: Pin a message in the middle of a long thread; from the pinned list, open that pin and confirm the view centers on that pin with neighbors visible, then verify more history loads only as the user scrolls toward older or newer messages.

**Acceptance Scenarios**:

1. **Given** a pinned message that is not among the most recently loaded messages, **When** the agent selects that pin from the pinned list, **Then** the view shows that pinned message with messages immediately before and after it without requiring the agent to scroll through the entire intervening history first.
2. **Given** the agent is viewing a pinned message in context, **When** they scroll toward older messages, **Then** additional older messages load incrementally.
3. **Given** the agent is viewing a pinned message in context, **When** they scroll toward newer messages, **Then** additional newer messages load incrementally until they reach the end of the loaded range or the latest messages as appropriate.
4. **Given** the agent wants to return to the latest messages after viewing a pinned message in context, **When** they scroll toward newer messages, **Then** they can reach the latest messages without requiring a separate “jump to latest” control.
5. **Given** incremental loading of older or newer messages fails (for example due to network error), **When** the failure occurs, **Then** the product shows an **inline** message in the conversation area with a **Retry** action so the agent can recover without leaving the view.
6. **Given** the agent opens a pinned message from the pinned list, **When** the pinned message is shown with surrounding context, **Then** keyboard focus moves to the pinned message (or its focusable container) so the agent remains oriented.

---

### Edge Cases

- Many pinned messages: the sticky area shows a **limited preview** and a control to open the **full** pinned list; the agent can always discover that additional pins exist and open any pin from the full list.
- Collapsed pinned area: opening a specific pin from a menu or list should still navigate to contextual view even if the strip was collapsed.
- Pinned message at the very start or end of the thread: scrolling in the direction where no messages exist should behave predictably (no empty jumps, clear end state).
- Conversation with only one screen of messages: behavior should remain smooth and not duplicate or flash content.
- Rapid switching between different pinned messages: the view should settle on the correct anchor without showing stale content from the previous selection.
- Returning to latest messages: if the agent is far back in history due to opening a pin, the only way back is scrolling; the experience should remain predictable and not feel like they are “stuck”.
- Failed incremental load: the agent sees a clear inline error with a way to retry, rather than a silent failure or only a toast with no recovery path in context.
- Keyboard focus after opening pin: focus lands on the pinned message (or its container) to support efficient keyboard navigation and reduce disorientation.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The product MUST present pinned messages in a way that stays accessible while the agent reads and scrolls the conversation, without requiring a manual scroll through the full message backlog solely to reach pinned items at the top of the chronological list.
- **FR-002**: The product MUST allow the agent to reduce visual prominence of the pinned area (for example via collapse) while keeping a predictable way to expand or access full pinned content.
- **FR-007**: For conversations that have pinned messages, the sticky pinned area MUST default to **collapsed** on open, while still presenting a visible compact header or handle so the agent knows pins exist and can expand the area.
- **FR-003**: When the agent chooses a pinned message from the pinned list (or equivalent entry point), the product MUST bring that message into view with adjacent context (messages before and after) as the initial focus.
- **FR-004**: The product MUST load additional messages toward older or newer parts of the thread based on the agent’s scroll direction after opening a pinned message, rather than requiring a single bulk load of the entire conversation history up front.
- **FR-005**: The product MUST avoid unnecessary full-thread traversal solely as a prerequisite to showing the selected pinned message and its neighbors.
- **FR-006**: The product MUST NOT require a dedicated “jump to latest” control to return from a pinned-message context view; returning to latest MUST be achievable via scrolling toward newer messages.
- **FR-008**: When loading older or newer messages in the pinned-message context view fails, the product MUST show an **inline** error in the conversation area and MUST offer a **Retry** action.
- **FR-009**: When the number of pinned messages exceeds what fits in the sticky preview, the product MUST show a **limited preview** and MUST provide a control that opens the **full** pinned list so every pin remains reachable.
- **FR-010**: When the agent opens a pinned message from the pinned list and the view shows that pin with surrounding context, the product MUST move keyboard focus to the pinned message (or its focusable container in the thread).

### Key Entities _(include if feature involves data)_

- **Pinned message reference**: The message marked as pinned within a conversation; used as an anchor for contextual viewing.
- **Conversation message thread**: Ordered messages in a conversation; the product loads segments around an anchor on demand.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: In usability testing or guided evaluation, agents reach any pinned message from the default conversation view in under 10 seconds without manually scrolling through the full history (excluding network failure cases).
- **SC-002**: When opening a pinned message that is not in the most recent screen of messages, the pinned message and at least one message before and after it are visible without the agent first scrolling through all intervening messages.
- **SC-003**: At least 90% of representative “open pinned message” tasks in long threads complete without the agent reporting confusion about where the conversation jumped or whether content is loading (qualitative survey or structured observation).
- **SC-004**: Scroll-based loading after opening a pin does not block interaction with the visible message region for more than a brief, perceptible loading state under normal operating conditions (assessed against product-wide performance expectations for the conversation view).

## Assumptions

- “Sticky at the top” means fixed within the conversation panel layout (or equivalent always-on placement), not necessarily OS-level window stickiness.
- The sticky pinned area defaults to **collapsed** when the conversation is opened; the product does not require remembering expand/collapse per user or per conversation unless a future spec adds that.
- Initial amount of context around a pin is “enough for the agent to orient,” typically filling most of the visible message area plus a small buffer; exact counts may follow existing conversation loading patterns.
- This specification builds on pinned messages already being implemented; it does not redefine pin limits, permissions, or notification rules unless extended in a future spec.
- How many pins appear in the “limited preview” may follow product layout constraints; the requirement is that overflow is never silently hidden (see **FR-009**).
