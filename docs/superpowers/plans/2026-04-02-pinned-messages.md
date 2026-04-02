# Pinned messages (dashboard) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let dashboard agents pin multiple messages per conversation (including private notes), browse them in a collapsible strip above the thread, jump to the message, and unpin—synced via ActionCable for other inbox members.

**Architecture:** `conversation_message_pins` join table; nested REST under `Api::V1::Accounts::Conversations`; `Conversation`/`Message` `dependent: :destroy` for hard deletes; **soft-deleted messages** (API `destroy` rewrites content) require explicit pin removal in that code path; `ActionCableListener` broadcasts agent-only tokens (inbox members + admins, **no** contact tokens); Vuex holds pins per conversation; `MessagesView.vue` hosts the strip above `MessageList.vue`; `MessageContextMenu.vue` exposes Pin/Unpin.

**Tech stack:** Rails 7.1, PostgreSQL, Pundit (`ConversationPolicy#show?` matches `Conversations::BaseController`), Jbuilder, Wisper-style `Rails.configuration.dispatcher`, `ActionCableBroadcastJob`, Vue 3 + Vuex + `app/javascript/dashboard/helper/actionCable.js`, Tailwind-only UI.

**Spec:** `docs/superpowers/specs/2026-04-02-pinned-messages-design.md`

---

## File structure (create / modify)

| File | Role |
|------|------|
| `db/migrate/*_create_conversation_message_pins.rb` | Table + indexes |
| `app/models/conversation_message_pin.rb` | Model, validations, `belongs_to` |
| `app/models/conversation.rb` | `has_many :conversation_message_pins, dependent: :destroy` |
| `app/models/message.rb` | `has_many :conversation_message_pins, dependent: :destroy` |
| `app/models/user.rb` | `has_many :conversation_message_pins, foreign_key: :pinned_by_id` (optional inverse) |
| `app/services/conversation_message_pins/create_service.rb` | Validate eligibility, cap, create, dispatch event |
| `app/services/conversation_message_pins/destroy_service.rb` | Nested lookup, destroy, dispatch event |
| `app/presenters/conversation_message_pin_presenter.rb` (or helper module) | `push_event_data`, `text_preview` (plain, 200 chars) using patterns aligned with `Message#content_for_llm` / strip HTML |
| `app/controllers/api/v1/accounts/conversations/pins_controller.rb` | `index`, `create`, `destroy` |
| `app/views/api/v1/accounts/conversations/pins/*.json.jbuilder` | Index + create JSON |
| `config/routes.rb` | `resources :pins, only: [:index, :create, :destroy], module: :conversations` under `resources :conversations` |
| `lib/events/types.rb` | `MESSAGE_PIN_CREATED`, `MESSAGE_PIN_DESTROYED` (or single event with operation—pick one and stay consistent) |
| `app/listeners/action_cable_listener.rb` | `message_pin_created`, `message_pin_destroyed` → `user_tokens` only (no `contact_tokens`) |
| `app/javascript/dashboard/helper/actionCable.js` | Map new event(s) → store dispatch |
| `app/javascript/dashboard/api/inbox/conversation.js` (or existing messages API module) | `getPins`, `createPin`, `destroyPin`—match existing axios patterns |
| `app/javascript/dashboard/store/modules/conversations/` | State/actions/mutations for pins + merge from Cable |
| `app/javascript/dashboard/components/widgets/conversation/PinnedMessagesStrip.vue` | Collapsible strip UI |
| `app/javascript/dashboard/components/widgets/conversation/MessagesView.vue` | Mount strip above `MessageList`; pass conversation id; hook `onScrollToMessage` / highlight |
| `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue` | Pin / Unpin entries, props for `pinned` / `pinId` |
| `app/javascript/dashboard/components-next/message/Message.vue` | Pass through menu props; optional `data-message-id` already via list |
| `app/javascript/dashboard/i18n/locale/en/conversation.json` (or nested key file) | Copy for strip + menu + errors |
| `config/locales/en.yml` | API error strings if using `I18n.t` in controllers |
| `app/controllers/api/v1/accounts/conversations/messages_controller.rb` | Inside `destroy` transaction, `conversation_message_pins` for that message |
| `spec/requests/api/v1/accounts/conversations/pins_spec.rb` (path may mirror project) | Request specs per spec |
| `enterprise/app/listeners/enterprise/action_cable_listener.rb` | Only if Enterprise prepends listener—keep parity |

---

### Task 1: Database and model

**Files:**

- Create: `db/migrate/XXXXXX_create_conversation_message_pins.rb`
- Create: `app/models/conversation_message_pin.rb`
- Modify: `app/models/conversation.rb`, `app/models/message.rb`, `app/models/user.rb` (inverse optional)

- [ ] **Step 1:** Add migration: `account_id`, `conversation_id`, `message_id`, `pinned_by_id`, `pinned_at` (default `-> { Time.current }`), FKs, **unique index** `(conversation_id, message_id)`, index on `conversation_id`. Follow `db/schema.rb` style for FK targets.

- [ ] **Step 2:** Run `bundle exec rails db:migrate`

  Expected: migration applies cleanly.

- [ ] **Step 3:** Model: validations `presence` of associations; `belongs_to :account, :conversation, :message, :pinned_by, class_name: 'User'`; ensure `pinned_by_id` matches `Current.user` on create in service (not necessarily DB constraint).

- [ ] **Step 4:** Add `has_many :conversation_message_pins, dependent: :destroy` on `Conversation` and `Message`.

- [ ] **Step 5:** Commit

```bash
git add db/migrate app/models
git commit -m "feat(conversations): add conversation_message_pins model"
```

---

### Task 2: Pin services (business rules + soft delete)

**Files:**

- Create: `app/services/conversation_message_pins/create_service.rb`
- Create: `app/services/conversation_message_pins/destroy_service.rb`
- Modify: `app/controllers/api/v1/accounts/conversations/messages_controller.rb` (`destroy`)

- [ ] **Step 1:** `CreateService`: inputs `conversation`, `message`, `user`. Rules: message must belong to conversation; **`message.activity?` → raise/return error**; cap **`ConversationMessagePin::MAX_PINS` (constant `50`)**; uniqueness handled by DB/rescue `RecordNotUnique`. Create pin with `account_id` from conversation.

- [ ] **Step 2:** `DestroyService`: find pin via `conversation.conversation_message_pins.find_by(id: pin_id)` — **never** global `ConversationMessagePin.find`.

- [ ] **Step 3:** In `MessagesController#destroy`, after marking message deleted (existing transaction), **`message.conversation_message_pins.destroy_all`** (or delete in same transaction).

- [ ] **Step 4:** (Optional) Model spec uniqueness — skip if time-boxed; request specs cover behavior.

- [ ] **Step 5:** Commit

```bash
git add app/services app/controllers/api/v1/accounts/conversations/messages_controller.rb
git commit -m "feat(conversations): pin create/destroy services and cleanup on message delete"
```

---

### Task 3: Preview helper + presenter

**Files:**

- Create: `app/presenters/conversation_message_pin_presenter.rb` (or `app/helpers` module used from jbuilder)

- [ ] **Step 1:** Implement `text_preview(message)`:

  - Plain text: strip HTML/tags from `message.content` (e.g. `ActionController::Base.helpers.strip_tags` or project helper).
  - If blank content but attachments, use a short literal consistent with product (e.g. `[Attachment]`—align with `Message#content_for_llm` spirit).
  - **Truncate to 200** with ellipsis.

- [ ] **Step 2:** `as_json` / `push_event_data` hash: `id`, `conversation_id`, `message_id`, `pinned_at`, `pinned_by` (minimal `user.push_event_data` or `{ id:, name:, avatar_url: }` per existing patterns), `text_preview`.

- [ ] **Step 3:** **Private notes:** For index/Cable, if `message.private?` and current user should not see it, **omit** pin or redact preview—mirror how the dashboard decides private-note visibility for inbox members (typically all inbox members see private notes; document assumption in code comment if identical to thread).

- [ ] **Step 4:** Commit

```bash
git add app/presenters
git commit -m "feat(conversations): pin JSON preview presenter"
```

---

### Task 4: API controller, routes, Jbuilder

**Files:**

- Modify: `config/routes.rb` (inside `scope module: :conversations` block ~line 131)
- Create: `app/controllers/api/v1/accounts/conversations/pins_controller.rb`
- Create: `app/views/api/v1/accounts/conversations/pins/index.json.jbuilder`
- Create: `app/views/api/v1/accounts/conversations/pins/create.json.jbuilder` (or reuse partial)
- Modify: `config/locales/en.yml` for error keys

- [ ] **Step 1:** Route:

```ruby
resources :pins, only: [:index, :create, :destroy], module: :conversations
```

  (Exact placement next to `resources :messages`.)

- [ ] **Step 2:** Controller inherits `Api::V1::Accounts::Conversations::BaseController` so `@conversation` is set and **`authorize @conversation, :show?`** applies.

- [ ] **Step 3:** `index`: `@pins = @conversation.conversation_message_pins.includes(:message, :pinned_by).order(pinned_at: :desc)`; map through presenter; filter private-note pins per presenter rules.

- [ ] **Step 4:** `create`: `params.require(:message_id)`; load `message = @conversation.messages.find(params[:message_id])`; `CreateService.new(...).perform`; render create jbuilder or errors `422`/`403`.

- [ ] **Step 5:** `destroy`: `pin = @conversation.conversation_message_pins.find(params[:id])` → `destroy` → `head :ok` or `204`.

- [ ] **Step 6:** Commit

```bash
git add config/routes.rb app/controllers app/views config/locales/en.yml
git commit -m "feat(api): conversation pins index create destroy"
```

---

### Task 5: Events + ActionCable

**Files:**

- Modify: `lib/events/types.rb`
- Modify: `app/listeners/action_cable_listener.rb`
- Modify: `app/services/conversation_message_pins/create_service.rb` and `destroy_service.rb` (dispatch after commit)

- [ ] **Step 1:** Add constants, e.g. `MESSAGE_PIN_CREATED = 'message.pin_created'`, `MESSAGE_PIN_DESTROYED = 'message.pin_destroyed'`.

- [ ] **Step 2:** After successful create/destroy, `Rails.configuration.dispatcher.dispatch(EVENT, Time.zone.now, pin:, conversation:, account:)` (include only what listener needs).

- [ ] **Step 3:** Listener methods `message_pin_created`, `message_pin_destroyed`: tokens = `user_tokens(account, conversation.inbox.members)` only (dashboard agents; **do not** broadcast to contacts).

- [ ] **Step 4:** Payload includes `account_id`, serialized pin data (use presenter), `conversation_id` as `display_id` if frontend expects `id` like other events—**match `message.created` shape** for `conversation` keys.

- [ ] **Step 5:** Check `enterprise/app/listeners/enterprise/action_cable_listener.rb`; extend if Enterprise overrides broadcasts.

- [ ] **Step 6:** Commit

```bash
git add lib/events/types.rb app/listeners/action_cable_listener.rb app/services
git commit -m "feat(cable): broadcast conversation message pin events"
```

---

### Task 6: Request specs

**Files:**

- Create: `spec/requests/api/v1/accounts/conversations/pins_spec.rb` (adjust path to match existing `spec/requests` layout)

- [ ] **Step 1:** Cover: index success; create success; create duplicate → `422` or `409`; create activity message → `422`; create over cap → `422`; destroy success; destroy pin from **other** conversation → `404`; unauthorized user → `403`/`401` per app; index **omits** private-note pin when testing a user without access (construct fixture that proves redaction path, or document skip if identical RBAC).

- [ ] **Step 2:** Run `bundle exec rspec spec/requests/api/v1/accounts/conversations/pins_spec.rb`

  Expected: all pass.

- [ ] **Step 3:** Commit

```bash
git add spec/requests
git commit -m "test(api): conversation pins request specs"
```

---

### Task 7: Frontend API + Vuex + ActionCable

**Files:**

- Modify: existing conversation API module under `app/javascript/dashboard/api/`
- Modify: `app/javascript/dashboard/store/modules/conversations/actions.js` (and related getters/mutations)
- Modify: `app/javascript/dashboard/helper/actionCable.js`

- [ ] **Step 1:** Add API methods calling `/api/v1/accounts/:accountId/conversations/:conversationId/pins`.

- [ ] **Step 2:** Vuex: e.g. `state.conversationPins = { [conversationId]: [] }`; actions `fetchConversationPins`, `addConversationPin`, `removeConversationPin`; mutation merge from Cable.

- [ ] **Step 3:** `actionCable.js`: register `'message.pin_created': this.onMessagePinCreated` (and destroyed); dispatch Vuex merges; guard with `isAValidEvent`.

- [ ] **Step 4:** On conversation select change, dispatch `fetchConversationPins` (same place other conversation fetches happen).

- [ ] **Step 5:** Commit

```bash
git add app/javascript/dashboard/api app/javascript/dashboard/store app/javascript/dashboard/helper/actionCable.js
git commit -m "feat(dashboard): pins API, store, and cable handlers"
```

---

### Task 8: Pinned strip + MessagesView integration

**Files:**

- Create: `app/javascript/dashboard/components/widgets/conversation/PinnedMessagesStrip.vue`
- Modify: `app/javascript/dashboard/components/widgets/conversation/MessagesView.vue`

- [ ] **Step 1:** `PinnedMessagesStrip.vue` with `<script setup>`, Tailwind only: collapsed bar showing count; chevron to expand; list rows with preview, "Jump", "Unpin"; loading/empty when none (hide strip when count 0).

- [ ] **Step 2:** Mount strip **above** `<MessageList` in `MessagesView.vue` template; pass `conversationId`, `inboxId` if needed for permissions.

- [ ] **Step 3:** Jump: `emitter.emit(...)` or call existing `onScrollToMessage({ messageId })` pattern from `MessagesView.vue` (see `messageId` query and `document.getElementById('message' + messageId)`).

- [ ] **Step 4:** After scroll, add temporary highlight class on the element (Tailwind `ring` / `bg`); `setTimeout` remove (~2s).

- [ ] **Step 5:** i18n keys in `app/javascript/dashboard/i18n/locale/en/*.json`.

- [ ] **Step 6:** Run `pnpm eslint` on touched files.

- [ ] **Step 7:** Commit

```bash
git add app/javascript/dashboard/components/widgets/conversation
git commit -m "feat(dashboard): pinned messages strip and jump-to"
```

---

### Task 9: Context menu Pin / Unpin

**Files:**

- Modify: `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue`
- Modify: `app/javascript/dashboard/components-next/message/Message.vue`
- Possibly: `app/javascript/dashboard/components-next/message/MessageList.vue` (pass pin state)

- [ ] **Step 1:** Vuex getter or prop: **is message pinned** + `pinId` for current conversation (derive from `conversationPins` by `message_id`).

- [ ] **Step 2:** Menu: show **Pin** if eligible (`message_type !== 'activity'` and not private-only restriction—private allowed); **Unpin** if pinned. Call API + optimistic Vuex update; handle errors with `useAlert` / existing toast.

- [ ] **Step 3:** Ensure activity messages do not show Pin (align with backend).

- [ ] **Step 4:** Commit

```bash
git add app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue app/javascript/dashboard/components-next/message
git commit -m "feat(dashboard): pin and unpin from message context menu"
```

---

### Task 10: Final verification

- [ ] **Step 1:** `bundle exec rubocop -a` on changed Ruby paths.

- [ ] **Step 2:** `pnpm eslint` / `pnpm eslint:fix` on changed JS/Vue.

- [ ] **Step 3:** `bundle exec rspec spec/requests/api/v1/accounts/conversations/pins_spec.rb`

- [ ] **Step 4:** Manual smoke: two browser sessions, pin/unpin, jump, soft-delete message removes pin from strip.

- [ ] **Step 5:** Commit any fixes.

---

## Plan review

After implementation, use **verification-before-completion** skill before claiming done.

**Execution handoff (choose one):**

1. **Subagent-driven** — one subagent per task above, review between tasks (@superpowers:subagent-driven-development).  
2. **Inline** — run tasks in this session with checkpoints (@superpowers:executing-plans).

---

**Related:** @superpowers:brainstorming (spec), @superpowers:verification-before-completion (before merge).
