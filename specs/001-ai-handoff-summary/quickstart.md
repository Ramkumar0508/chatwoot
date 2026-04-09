# Quickstart: AI-Powered Conversation Handoff Summary

**Feature**: 001-ai-handoff-summary  
**Date**: 2026-03-14

## What This Feature Does

When an agent transfers a conversation to another agent or team, they can optionally generate an AI handoff summary (customer intent, sentiment, key issues, suggested next steps). The summary is shown before the transfer is completed; on confirm, it is added as a private note and the assignment is applied.

## Prerequisites

- Chatwoot running with Captain/LLM configured (API key and endpoint).
- Account has conversations and agents/teams for assignment.
- User has permission to assign conversations (existing assignment permissions).

## How to Test (Manual)

1. **Open a conversation** in the dashboard that has some message history.
2. **Trigger transfer** (e.g. use "Assign agent" or "Assign team" in the conversation sidebar or action menu).
3. **Generate summary** (if UI offers it): e.g. click "Generate handoff summary" or have it auto-requested. Wait for the preview to load.
4. **Review** the structured summary (intent, sentiment, issues, next steps).
5. **Confirm transfer**: Choose assignee/team and confirm. The summary should appear as a private note and the conversation should be assigned.
6. **Verify**: Open the conversation and confirm a private note with the summary content and an indication that it is AI-generated. Check that the conversation is assigned to the selected agent or team.

## Edge Cases to Verify

- **LLM unavailable**: Disable or misconfigure Captain/LLM; trigger handoff summary. Expect an error or empty summary; transfer without summary should still be possible.
- **Short conversation**: Use a conversation with 1–2 messages; generate summary. Expect a brief summary or a “limited context” message; transfer should still complete.
- **Cancel**: After preview is shown, cancel the transfer. No private note should be created; conversation should remain with the current assignee/team.

## Implementation Notes (for developers)

- **Preview**: `POST .../conversations/:id/handoff_summary` returns `{ summary }` or `{ summary, error }`. No persistence.
- **Assign with summary**: `POST .../conversations/:id/assignments` with optional `handoff_summary` in body. Backend creates the private note then assigns.
- **Service**: Handoff summary text is produced by a service (e.g. `Conversations::HandoffSummaryService` or `Captain::HandoffSummaryService`) using existing conversation-to-LLM formatting and a handoff-specific prompt.
