<script setup>
import { computed, watch, ref, useId } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { messageStamp } from 'shared/helpers/timeHelper';

const store = useStore();
const { t } = useI18n();
const router = useRouter();
const panelId = useId();

const currentChat = computed(() => store.getters.getSelectedChat);
const conversationId = computed(() => currentChat.value?.id);

const pinnedMessages = computed(() =>
  conversationId.value
    ? store.getters['pinnedMessages/getPinnedMessages'](conversationId.value)
    : []
);
const pinnedCount = computed(() => pinnedMessages.value.length);

const hasUnavailablePins = computed(() =>
  conversationId.value
    ? store.getters['pinnedMessages/getHasUnavailablePins'](
        conversationId.value
      )
    : false
);
const accessDenied = computed(() =>
  conversationId.value
    ? store.getters['pinnedMessages/isPinnedAccessDenied'](conversationId.value)
    : false
);

const visible = computed(() => conversationId.value && !accessDenied.value);

const expanded = ref(false);
const viewAllDialogRef = ref(null);
const previewLimit = 3;

function toggleExpanded() {
  expanded.value = !expanded.value;
}

watch(
  conversationId,
  id => {
    if (id) {
      store.dispatch('pinnedMessages/fetch', id);
    }
  },
  { immediate: true }
);

function previewText(pm) {
  const msg = pm.message;
  if (!msg) return t('CONVERSATION.NO_CONTENT');
  const text = msg.content ?? '';
  const trimmed = text.trim();
  if (!trimmed) return t('CONVERSATION.NO_CONTENT');
  return trimmed.length > 120 ? `${trimmed.slice(0, 120)}…` : trimmed;
}

function senderLabel(pm) {
  const msg = pm.message;
  if (!msg) return t('CONVERSATION.NO_CONTENT');
  const name = msg.sender?.name;
  if (name) return name;
  return t('CONVERSATION.PINNED_MESSAGES.UNKNOWN_SENDER');
}

function formattedTime(pm) {
  const created = pm.message?.created_at;
  if (created == null) return '';
  return messageStamp(created, 'h:mm a');
}

async function openPinnedMessage(messageId) {
  if (!conversationId.value) return;
  try {
    await store.dispatch('fetchMessagesAround', {
      conversationId: conversationId.value,
      messageId,
    });
  } catch {
    // If anchor load fails, fall back to best-effort scroll behavior.
  }

  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
  const route = router.currentRoute.value;
  router.replace({
    ...route,
    query: { ...route.query, messageId: String(messageId) },
  });
  viewAllDialogRef.value?.close();
}

function openViewAll() {
  viewAllDialogRef.value?.open();
}

async function handleUnpin(messageId) {
  if (!conversationId.value) return;
  try {
    await store.dispatch('pinnedMessages/unpin', {
      conversationId: conversationId.value,
      messageId,
    });
  } catch {
    useAlert(t('CONVERSATION.PINNED_MESSAGES.UNPIN_FAILED'));
  }
}
</script>

<template>
  <div v-show="visible" class="w-full flex-shrink-0">
    <div
      class="rounded-lg bg-n-alpha-2/90 dark:bg-n-solid-2/70 border border-n-weak/70 overflow-hidden"
    >
      <button
        type="button"
        class="flex w-full items-center gap-2 px-2.5 py-2 text-left min-h-10 hover:bg-n-alpha-2 transition-colors"
        :aria-expanded="expanded"
        :aria-controls="panelId"
        @click="toggleExpanded"
      >
        <span
          class="inline-flex size-7 shrink-0 items-center justify-center rounded-md bg-n-brand/10 text-n-brand"
        >
          <Icon icon="i-lucide-pin" class="size-4" />
        </span>
        <span class="flex min-w-0 flex-1 flex-col gap-0.5">
          <span class="text-xs font-semibold text-n-slate-12">
            {{ $t('CONVERSATION.PINNED_MESSAGES.TITLE') }}
          </span>
          <span
            v-if="!expanded && pinnedCount > 0"
            class="text-xs text-n-slate-11"
          >
            {{
              $t('CONVERSATION.PINNED_MESSAGES.PIN_COUNT', {
                count: pinnedCount,
              })
            }}
          </span>
        </span>
        <span class="inline-flex size-8 shrink-0 items-center justify-center">
          <Icon
            :icon="expanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
            class="size-4 text-n-slate-11"
          />
        </span>
      </button>

      <div v-show="expanded" :id="panelId" class="border-t border-n-weak/60">
        <p
          v-if="hasUnavailablePins"
          class="text-xs text-n-amber-11 px-2.5 pt-2 pb-1"
        >
          {{ $t('CONVERSATION.PINNED_MESSAGES.UNAVAILABLE_NOTICE') }}
        </p>
        <div
          v-if="pinnedMessages.length"
          class="max-h-48 overflow-y-auto overflow-x-hidden px-1.5 pb-2 pt-1"
        >
          <ul class="flex flex-col gap-0.5" role="list">
            <li
              v-for="pm in pinnedMessages.slice(0, previewLimit)"
              :key="pm.id"
              class="group relative rounded-md"
            >
              <div
                class="flex items-stretch gap-0.5 rounded-md hover:bg-n-alpha-2 focus-within:bg-n-alpha-2"
              >
                <button
                  type="button"
                  class="flex min-w-0 flex-1 flex-col gap-0.5 rounded-md px-2 py-1.5 text-left"
                  @click="openPinnedMessage(pm.message_id)"
                >
                  <div class="flex items-start justify-between gap-2">
                    <span class="truncate text-xs font-medium text-n-slate-12">
                      {{ senderLabel(pm) }}
                    </span>
                    <span class="shrink-0 text-xs text-n-slate-11 tabular-nums">
                      {{ formattedTime(pm) }}
                    </span>
                  </div>
                  <p class="line-clamp-2 text-xs text-n-slate-11">
                    {{ previewText(pm) }}
                  </p>
                </button>
                <button
                  type="button"
                  class="flex w-9 shrink-0 items-center justify-center rounded-md text-n-slate-11 opacity-0 transition-opacity hover:bg-n-alpha-2 hover:text-n-slate-12 hover:opacity-100 focus:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-brand group-hover:opacity-100"
                  :aria-label="$t('CONVERSATION.CONTEXT_MENU.UNPIN')"
                  @click.stop="handleUnpin(pm.message_id)"
                >
                  <Icon icon="i-lucide-pin-off" class="size-4" />
                </button>
              </div>
            </li>
          </ul>
          <div
            v-if="pinnedCount > previewLimit"
            class="flex items-center justify-between gap-2 px-1.5 pt-2"
          >
            <p class="text-xs text-n-slate-11">
              {{
                $t('CONVERSATION.PINNED_MESSAGES.PIN_COUNT', {
                  count: pinnedCount,
                })
              }}
            </p>
            <button
              type="button"
              class="text-xs font-medium text-n-brand hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-brand rounded"
              @click="openViewAll"
            >
              {{ $t('CONVERSATION.PINNED_MESSAGES.VIEW_ALL') }}
            </button>
          </div>
        </div>
        <p v-else class="text-xs text-n-slate-11 px-2.5 py-2">
          {{ $t('CONVERSATION.PINNED_MESSAGES.EMPTY') }}
        </p>
      </div>
    </div>

    <Dialog
      v-if="pinnedMessages.length"
      ref="viewAllDialogRef"
      width="lg"
      overflow-y-auto
      :title="$t('CONVERSATION.PINNED_MESSAGES.TITLE')"
      :show-confirm-button="false"
      :show-cancel-button="true"
      @close="() => {}"
    >
      <div class="flex flex-col gap-2">
        <p
          v-if="hasUnavailablePins"
          class="text-xs text-n-amber-11"
        >
          {{ $t('CONVERSATION.PINNED_MESSAGES.UNAVAILABLE_NOTICE') }}
        </p>
        <ul class="flex flex-col gap-1" role="list">
          <li
            v-for="pm in pinnedMessages"
            :key="pm.id"
            class="group relative rounded-md"
          >
            <div
              class="flex items-stretch gap-0.5 rounded-md hover:bg-n-alpha-2 focus-within:bg-n-alpha-2"
            >
              <button
                type="button"
                class="flex min-w-0 flex-1 flex-col gap-0.5 rounded-md px-2 py-1.5 text-left"
                @click="openPinnedMessage(pm.message_id)"
              >
                <div class="flex items-start justify-between gap-2">
                  <span class="truncate text-xs font-medium text-n-slate-12">
                    {{ senderLabel(pm) }}
                  </span>
                  <span
                    class="shrink-0 text-xs text-n-slate-11 tabular-nums"
                  >
                    {{ formattedTime(pm) }}
                  </span>
                </div>
                <p class="line-clamp-2 text-xs text-n-slate-11">
                  {{ previewText(pm) }}
                </p>
              </button>
              <button
                type="button"
                class="flex w-9 shrink-0 items-center justify-center rounded-md text-n-slate-11 opacity-0 transition-opacity hover:bg-n-alpha-2 hover:text-n-slate-12 hover:opacity-100 focus:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-brand group-hover:opacity-100"
                :aria-label="$t('CONVERSATION.CONTEXT_MENU.UNPIN')"
                @click.stop="handleUnpin(pm.message_id)"
              >
                <Icon icon="i-lucide-pin-off" class="size-4" />
              </button>
            </div>
          </li>
        </ul>
      </div>
    </Dialog>
  </div>
</template>
