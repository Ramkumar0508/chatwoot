# Quickstart: Pin Multiple Messages

**Date**: 2026-03-30  
**Feature**: [spec.md](./spec.md)

## Goal

Verify that agents can pin/unpin multiple messages in a conversation and access them from a pinned area without scrolling.

## Prerequisites

- Chatwoot dev environment running (Rails + dashboard)
- A test account, inbox, and at least one conversation with multiple messages

## Manual test flow

1. Open the dashboard and navigate to a conversation with multiple messages.
2. Pin two different messages from the message actions menu.
3. Confirm a pinned area appears and lists both pinned messages.
4. Click a pinned item and confirm the conversation scrolls/jumps to that message.
5. Unpin one message and confirm the pinned area updates.
6. Attempt to pin more than 20 messages and confirm the UI blocks the action with a clear instruction to unpin.
7. Delete a pinned message (using the existing message delete action) and confirm:
   - The pinned area omits the deleted/unavailable message
   - A non-blocking notice indicates some pins are unavailable
8. Open the same conversation in another session/user (authorized) and confirm the pinned list is the same.

## Expected outcomes

- Pin/unpin is idempotent (no duplicates)
- Pinned state persists after refresh and revisit
- No permission leakage (only authorized agents can pin/unpin)

