# Quickstart: Pinned messages UX improvements

**Feature**: [spec.md](./spec.md)

## Prerequisites

- `bundle install && pnpm install`
- Rails + Vite dev server (`pnpm dev` or `overmind start -f Procfile.dev`)
- Account with dashboard access; a conversation with **many** messages and **several** pinned messages

## Manual verification

1. **Sticky + collapsed default**
   - Open a long conversation with pins.
   - Confirm the **pinned strip stays visible** at the top while scrolling the message list.
   - Confirm the strip is **collapsed by default** (expand control visible).

2. **Preview + full list**
   - Create more pins than fit the preview.
   - Confirm **count / “view all”** shows and **no pin is hidden without a path** to open.

3. **Open pin in middle of history**
   - Pin a message deep in the thread.
   - From the pinned UI, open that pin.
   - Confirm the view shows **anchor + neighbors** without loading the entire thread first (network tab: single `around` request or documented client strategy).
   - Scroll **up** and **down**; confirm **incremental** loads.

4. **Failure + Retry**
   - Simulate offline / failed request (DevTools offline or block URL).
   - Confirm **inline** error with **Retry** in the conversation area (FR-008).

5. **Keyboard**
   - Tab to pinned list, activate a pin; confirm focus moves to the **anchor message** (FR-010).

6. **Return to latest**
   - After viewing anchor context, scroll **toward newer** messages until latest; confirm **no** dedicated “jump to latest” button is required (per spec).
