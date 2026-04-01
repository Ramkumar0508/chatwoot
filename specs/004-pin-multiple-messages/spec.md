# Feature Specification: Pin Multiple Messages

**Feature Branch**: `[004-pin-multiple-messages]`  
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Status**: Draft  
**Input**: User description: "Agents should be able to pin multiple messages in a conversation inside Chatwoot. Pinned messages should be easily accessible without scrolling through the entire thread."  
**Revision (2026-03-30)**: `/speckit.specify` — Redesign pinned messages UI for a clean, accessible, contextually integrated experience (compact collapsible region, rich previews, smooth jump-to-message, scalable list/carousel, subtle actions, visual hierarchy, responsiveness, support-tool aesthetic aligned with Chatwoot conversation patterns).

## User Scenarios & Testing _(mandatory)_

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Pin multiple messages (Priority: P1)

An authorized staff member opens a conversation and pins multiple messages. The pinned messages appear in a dedicated pinned area so the staff member can access key context quickly, without scrolling through the full message thread.

**Why this priority**: Pinning the right context is a core work-efficiency need for support staff; enabling multiple pins prevents losing important context that’s spread across the thread.

**Independent Test**: Can be fully tested by pinning two distinct messages in an existing conversation and verifying the pinned area lists both messages and provides a direct way to open each one.

**Acceptance Scenarios**:

1. **Given** a conversation containing multiple messages, **When** an authorized staff member pins two different messages, **Then** the pinned area displays both pinned messages (without duplicates).
2. **Given** the pinned area is visible, **When** the staff member selects a pinned message item, **Then** the conversation view jumps to the corresponding message so the staff member can continue from that point.
3. **Given** a conversation where messages are already pinned, **When** the staff member revisits the conversation, **Then** the pinned area still displays the same pinned messages.

---

### User Story 2 - Unpin and manage pins (Priority: P2)

An authorized staff member can remove messages from the pinned area (unpin) and the pinned area updates immediately to reflect the current set of pinned messages.

**Why this priority**: Staff need to keep pinned context current; unpinning ensures the pinned area does not become stale or confusing during ongoing conversation work.

**Independent Test**: Can be fully tested by pinning multiple messages, then unpinning one (or more) and verifying the pinned area updates accordingly.

**Acceptance Scenarios**:

1. **Given** a conversation with at least one pinned message, **When** the staff member unpins that message, **Then** the pinned area no longer lists it and the original message remains in the thread.
2. **Given** a conversation where the maximum pinned count has been reached, **When** the staff member attempts to pin an additional message, **Then** the system blocks the action and instructs the staff member to unpin an existing message.
3. **Given** a conversation where a pinned message becomes unavailable, **When** the staff member revisits the conversation, **Then** the pinned area omits the unavailable message and shows a non-blocking notice.

---

### User Story 3 - Permissions and pinned visibility (Priority: P3)

Only users with pin/unpin authorization can modify the pinned list. Users without permission cannot see or use pin controls, while users with authorization can view and use the pinned list in the conversation.

**Why this priority**: Pinned context may contain sensitive information; enforcing permissions prevents unauthorized users from modifying or relying on pinned context.

**Independent Test**: Can be tested by attempting pin/unpin actions as different user types/roles and verifying that unauthorized users cannot modify pinned state.

**Acceptance Scenarios**:

1. **Given** a user without pin/unpin authorization but with access to the conversation, **When** they open the conversation, **Then** pin controls are not available and the pinned area is not editable.
2. **Given** a user without access to the conversation, **When** they attempt to access pinned details or perform a pin/unpin action, **Then** the action is denied.
3. **Given** two authorized staff members can view the same conversation, **When** one staff member pins or unpins messages, **Then** the other staff member sees the same updated pinned set.

---

### User Story 4 - Pinned area UI (compact, discoverable, integrated) (Priority: P2)

An authorized staff member sees pinned messages in a **compact, collapsible** region that sits at the **top or side** of the conversation workspace so important context is easy to spot without competing with the live chat. Each pinned item shows **who sent it**, a **short snippet**, and **when it was sent**. Choosing an item **smoothly scrolls** to that message in the thread. When many messages are pinned, the region **stacks** them cleanly and offers a **scrollable list or carousel** so the main chat stays calm. **Unpin** is available through **subtle, hover, or contextual** actions rather than a wall of permanent buttons. Visual treatment uses a **clear pinned indicator**, **soft highlight or accent**, and **avoids heavy borders or large cards**. Layout remains **usable on smaller screens** and **consistent with Chatwoot’s conversation UI** (density, typography, tokens).

**Why this priority**: Core pin/unpin behavior (P1–P3) can work without polish; this story makes the feature **professionally usable** for agents—fast recognition, lower cognitive load, and a modern support-tool feel.

**Independent Test**: Can be tested with a conversation that has several pins: verify the region is collapsible, previews show sender/snippet/time, jump-to-message is smooth, overflow is handled (scroll or carousel), unpin is reachable without visual clutter, and narrow viewports remain usable.

**Acceptance Scenarios**:

1. **Given** at least one pinned message, **When** the staff member opens the conversation, **Then** the pinned region is visible in a compact strip or rail (top or side per product layout) with a **pinned indicator** and **subtle** emphasis—not a heavy card frame.
2. **Given** the pinned region is expanded, **When** the staff member views a pinned item, **Then** they see **sender name**, **truncated message snippet**, and **timestamp** (or equivalent relative time if that matches conversation patterns).
3. **Given** a pinned item is shown, **When** the staff member activates it (click or keyboard equivalent), **Then** the thread **smoothly scrolls** (or animates) to the original message so context is obvious.
4. **Given** more pinned messages than fit in the allotted space, **When** the staff member uses the pinned region, **Then** they can reach all pins via a **scrollable list** or **carousel** (one pattern chosen consistently) without pushing the chat off-screen.
5. **Given** pin/unpin permission, **When** the staff member focuses or hovers a pinned item (or opens its context), **Then** they can **unpin** via a **subtle, accessible** control—not a permanent row of primary buttons for every item.
6. **Given** a narrow or small viewport, **When** the staff member uses the conversation, **Then** the pinned region **reflows or collapses** predictably and remains **discoverable** without dominating the viewport.

---

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- Attempting to pin the same message more than once does not create duplicate pinned entries.
- If a pinned message becomes unavailable (for example, deleted or otherwise missing), the pinned area omits the unavailable message and shows a non-blocking notice.
- When a conversation contains fewer messages than would be required to reach the maximum pinned count, pinning behaves normally for the available messages.
- If multiple staff members modify pins around the same time, the pinned area consistently reflects the resulting pinned set (no duplicate pinned entries).
- If pin/unpin fails, the pinned area does not end up in an inconsistent state (it either reflects the requested change or remains unchanged with a clear error message).
- When the pinned region is **collapsed**, the conversation still signals that pins exist (e.g., count or icon) so agents do not assume there are no pins.
- **Carousel** (if used): keyboard and focus order allow moving between pinned items and activating jump-to-message without trapping focus.
- **Very long** sender names or snippets truncate gracefully without breaking layout.

## Requirements _(mandatory)_

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST allow authorized staff users to pin multiple messages within a single conversation.
- **FR-002**: System MUST display the pinned messages in a dedicated, easily discoverable area when viewing the conversation thread.
- **FR-003**: System MUST allow authorized staff users to navigate directly from a pinned item to its corresponding position in the conversation thread.
- **FR-004**: System MUST persist pinned message selections for the conversation so that pinned items remain pinned when the conversation is revisited.
- **FR-005**: System MUST prevent duplicate pinned entries for the same message (a pinned list contains unique messages).
- **FR-006**: System MUST allow authorized staff users to unpin pinned messages and update the pinned area immediately to reflect the current pinned set.
- **FR-007**: System MUST enforce a per-conversation maximum pinned count of 20 messages. When the limit is reached, pinning an additional message is blocked with a clear instruction to unpin.
- **FR-008**: System MUST enforce permissions: users without pin/unpin authorization cannot pin/unpin and cannot modify the pinned list (and pin controls are not available to them).
- **FR-009**: System MUST handle pinned message availability changes gracefully by removing unavailable pinned messages from the pinned area and providing a non-blocking notice.
- **FR-010**: System MUST share the pinned list across all authorized staff members who can view the conversation (a staff member sees the same pinned set as other authorized staff).

### UX / Presentation Requirements (pinned region)

- **FR-011**: Interface MUST present pinned messages in a **compact, collapsible** section integrated at the **top or side** of the conversation workspace (consistent with dashboard layout), so pins are **discoverable** without distracting from the live thread.
- **FR-012**: Each pinned list item MUST display at minimum: **sender display name** (or equivalent sender label used elsewhere in the thread), **short message snippet** (truncated consistently), and **timestamp** (absolute or relative—**consistent with** other message previews in the dashboard).
- **FR-013**: Activating a pinned item MUST **scroll or move the view** to the corresponding message in the thread with **smooth** motion (or an equivalent non-jarring transition), and the target message SHOULD be visually identifiable immediately after navigation.
- **FR-014**: When multiple pins exist, the UI MUST **stack** them cleanly; when the list exceeds the visible area, the UI MUST provide a **bounded-height scrollable list** or a **carousel** (single chosen pattern per implementation) so the pinned area does not grow without limit.
- **FR-015**: **Unpin** MUST be available to authorized users via **hover, focus, or contextual** affordances (not a permanent dense row of buttons on every item); controls MUST meet **accessible** contrast and target sizes.
- **FR-016**: Visual design MUST include a **pinned indicator** (icon or glyph) and **soft highlight or accent** using existing design tokens; MUST **avoid** heavy outlines, oversized cards, or noisy chrome that increases clutter.
- **FR-017**: Layout MUST be **responsive**: on smaller widths, the pinned region remains usable (e.g., collapse by default, tighter rows, or stacked layout) without obscuring message composition or the main transcript.
- **FR-018**: Spacing, typography, and interactive patterns MUST **align with Chatwoot conversation UI** conventions (support-tool aesthetic: calm, dense-but-readable, professional).

### Key Entities _(include if feature involves data)_

- **Conversation**: The container representing a customer support thread with a message timeline that staff can view.
- **Message**: An individual communication item within a conversation thread; each message can potentially be pinned.
- **Pinned Message**: The association between a conversation and a chosen message indicating that the message is pinned for that conversation.
- **User (Staff)**: A user role that may have permission to pin/unpin messages and view the pinned area.

## Success Criteria _(mandatory)_

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: In a controlled usability test with representative staff, at least 90% of participants can locate a pinned message and jump to it within 10 seconds of opening a conversation (without scrolling through the full thread).
- **SC-002**: For conversations with at least 50 messages, the median time-to-locate a relevant message via the pinned area improves by at least 40% compared to a baseline flow without pinned access.
- **SC-003**: Pinned selections persist: in at least 99% of test sessions, the pinned area displays the same pinned messages after a staff member revisits the conversation.
- **SC-004**: Correctness and clarity: in at least 95% of pin/unpin attempts under test, the pinned area state matches the requested action (pin adds a unique item; unpin removes it; limit shows an instruction).
- **SC-005**: **Recognition**: In moderated usability sessions, at least **90%** of agents **correctly identify** that the conversation has pinned context **within 5 seconds** of opening the view (collapsed or expanded), without hunting the full thread.
- **SC-006**: **Efficiency**: Median time to **open a pinned preview and reach** the original message in-thread is **under 15 seconds** for conversations with 50+ messages, including overflow (scroll/carousel) cases.
- **SC-007**: **Subjective quality**: In a short post-task survey, at least **80%** of agents rate the pinned region as **“easy to use”** or better, and **clutter** ratings skew **low** versus a baseline “list-only” pinned strip.
