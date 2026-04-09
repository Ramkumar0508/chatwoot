<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import ConversationLabels from './labels/LabelBox.vue';
import { CONVERSATION_PRIORITY } from '../../../../shared/constants/messages';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    ConversationLabels,
    NextButton,
    Dialog,
    Button,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const { agentsList } = useAgentsList();
    return {
      agentsList,
    };
  },
  data() {
    return {
      transferModal: {
        visible: false,
        pending: null,
        summary: null,
        error: null,
        loading: false,
      },
      priorityOptions: [
        {
          id: null,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
          thumbnail: `/assets/images/dashboard/priority/none.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.URGENT,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.URGENT}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.HIGH,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.HIGH}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.MEDIUM,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.MEDIUM}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.LOW,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.LOW}.svg`,
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      teams: 'teams/getTeams',
    }),
    hasAnAssignedTeam() {
      return !!this.currentChat?.meta?.team;
    },
    teamsList() {
      if (this.hasAnAssignedTeam) {
        return [
          { id: 0, name: this.$t('TEAMS_SETTINGS.LIST.NONE') },
          ...this.teams,
        ];
      }
      return this.teams;
    },
    assignedAgent: {
      get() {
        return this.currentChat.meta.assignee;
      },
      set(agent) {
        const agentId = agent ? agent.id : null;
        this.$store.dispatch('setCurrentChatAssignee', {
          conversationId: this.currentChat.id,
          assignee: agent,
        });
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId,
            handoffSummary: null,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
          });
      },
    },
    assignedTeam: {
      get() {
        return this.currentChat.meta.team;
      },
      set(team) {
        const conversationId = this.currentChat.id;
        const teamId = team ? team.id : 0;
        this.$store.dispatch('setCurrentChatTeam', {
          team,
          conversationId,
          handoffSummary: null,
        });
        this.$store
          .dispatch('assignTeam', {
            conversationId,
            teamId,
            handoffSummary: null,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_TEAM'));
          });
      },
    },
    assignedPriority: {
      get() {
        const selectedOption = this.priorityOptions.find(
          opt => opt.id === this.currentChat.priority
        );

        return selectedOption || this.priorityOptions[0];
      },
      set(priorityItem) {
        const conversationId = this.currentChat.id;
        const oldValue = this.currentChat?.priority;
        const priority = priorityItem ? priorityItem.id : null;

        this.$store.dispatch('setCurrentChatPriority', {
          priority,
          conversationId,
        });
        this.$store
          .dispatch('assignPriority', { conversationId, priority })
          .then(() => {
            useTrack(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
              oldValue,
              newValue: priority,
              from: 'Conversation Sidebar',
            });
            useAlert(
              this.$t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
                priority: priorityItem.name,
                conversationId,
              })
            );
          });
      },
    },
    showSelfAssign() {
      if (!this.assignedAgent) {
        return true;
      }
      if (this.assignedAgent.id !== this.currentUser.id) {
        return true;
      }
      return false;
    },
  },
  methods: {
    onSelfAssign() {
      const {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        avatar_url,
      } = this.currentUser;
      const selfAssign = {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        thumbnail: avatar_url,
      };
      this.assignedAgent = selfAssign;
    },
    async onClickAssignAgent(selectedItem) {
      if (this.assignedAgent && this.assignedAgent.id === selectedItem.id) {
        this.assignedAgent = null;
        return;
      }
      this.transferModal.pending = { type: 'agent', agent: selectedItem };
      this.transferModal.visible = true;
      this.transferModal.loading = true;
      this.transferModal.summary = null;
      this.transferModal.error = null;
      this.$nextTick(() => this.$refs.handoffDialog?.open());
      try {
        const data = await this.$store.dispatch(
          'fetchHandoffSummaryPreview',
          this.currentChat.id
        );
        this.transferModal.summary = data.summary ?? null;
        this.transferModal.error = data.error ?? null;
      } catch (_) {
        this.transferModal.error = this.$t(
          'HANDOFF_SUMMARY.ERROR'
        );
      } finally {
        this.transferModal.loading = false;
      }
    },

    async onClickAssignTeam(selectedItemTeam) {
      if (
        selectedItemTeam.id === 0 ||
        (this.assignedTeam && this.assignedTeam.id === selectedItemTeam.id)
      ) {
        this.assignedTeam = null;
        return;
      }
      this.transferModal.pending = { type: 'team', team: selectedItemTeam };
      this.transferModal.visible = true;
      this.transferModal.loading = true;
      this.transferModal.summary = null;
      this.transferModal.error = null;
      this.$nextTick(() => this.$refs.handoffDialog?.open());
      try {
        const data = await this.$store.dispatch(
          'fetchHandoffSummaryPreview',
          this.currentChat.id
        );
        this.transferModal.summary = data.summary ?? null;
        this.transferModal.error = data.error ?? null;
      } catch (_) {
        this.transferModal.error = this.$t(
          'HANDOFF_SUMMARY.ERROR'
        );
      } finally {
        this.transferModal.loading = false;
      }
    },

    closeTransferModal() {
      this.transferModal.visible = false;
      this.transferModal.pending = null;
      this.transferModal.summary = null;
      this.transferModal.error = null;
    },

    confirmTransfer(withSummary = true) {
      const { pending } = this.transferModal;
      if (!pending) return;
      const handoffSummary =
        withSummary && this.transferModal.summary
          ? this.transferModal.summary
          : null;
      if (pending.type === 'agent') {
        this.$store.dispatch('setCurrentChatAssignee', {
          conversationId: this.currentChat.id,
          assignee: pending.agent,
        });
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId: pending.agent.id,
            handoffSummary,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
            this.closeTransferModal();
          });
      } else {
        this.$store.dispatch('setCurrentChatTeam', {
          team: pending.team,
          conversationId: this.currentChat.id,
        });
        this.$store
          .dispatch('assignTeam', {
            conversationId: this.currentChat.id,
            teamId: pending.team.id,
            handoffSummary,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_TEAM'));
            this.closeTransferModal();
          });
      }
    },

    onClickAssignPriority(selectedPriorityItem) {
      const isSamePriority =
        this.assignedPriority &&
        this.assignedPriority.id === selectedPriorityItem.id;

      this.assignedPriority = isSamePriority ? null : selectedPriorityItem;
    },
  },
};
</script>

<template>
  <div>
    <div>
      <ContactDetailsItem
        compact
        :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
      >
        <template #button>
          <NextButton
            v-if="showSelfAssign"
            link
            xs
            icon="i-lucide-arrow-right"
            class="!gap-1"
            :label="$t('CONVERSATION_SIDEBAR.SELF_ASSIGN')"
            @click="onSelfAssign"
          />
        </template>
      </ContactDetailsItem>
      <MultiselectDropdown
        :options="agentsList"
        :selected-item="assignedAgent"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        @select="onClickAssignAgent"
      />
    </div>
    <div>
      <ContactDetailsItem
        compact
        :title="$t('CONVERSATION_SIDEBAR.TEAM_LABEL')"
      />
      <MultiselectDropdown
        :options="teamsList"
        :selected-item="assignedTeam"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
        "
        @select="onClickAssignTeam"
      />
    </div>
    <div>
      <ContactDetailsItem compact :title="$t('CONVERSATION.PRIORITY.TITLE')" />
      <MultiselectDropdown
        :options="priorityOptions"
        :selected-item="assignedPriority"
        :multiselector-title="$t('CONVERSATION.PRIORITY.TITLE')"
        :multiselector-placeholder="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SELECT_PLACEHOLDER')
        "
        :no-search-result="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.NO_RESULTS')
        "
        :input-placeholder="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.INPUT_PLACEHOLDER')
        "
        @select="onClickAssignPriority"
      />
    </div>
    <ContactDetailsItem
      compact
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
    />
    <ConversationLabels :conversation-id="conversationId" />

    <Dialog
      v-if="transferModal.visible"
      ref="handoffDialog"
      type="edit"
      width="lg"
      overflow-y-auto
      :title="$t('HANDOFF_SUMMARY.TITLE')"
      :show-confirm-button="false"
      :show-cancel-button="false"
      @close="closeTransferModal"
    >
      <div class="flex flex-col gap-3 text-sm">
        <p
          v-if="transferModal.loading"
          class="text-n-slate-11"
        >
          {{ $t('HANDOFF_SUMMARY.GENERATING') }}
        </p>
        <p
          v-else-if="transferModal.error"
          class="text-n-ruby-11"
        >
          {{ transferModal.error }}
        </p>
        <div
          v-else-if="transferModal.summary"
          class="rounded-md bg-n-slate-2 p-3 text-n-slate-12 whitespace-pre-wrap max-h-48 overflow-y-auto"
        >
          {{ transferModal.summary }}
        </div>
        <p
          v-else
          class="text-n-slate-11"
        >
          {{ $t('HANDOFF_SUMMARY.LIMITED_CONTEXT') }}
        </p>
      </div>
      <template #footer>
        <div class="flex w-full gap-3 justify-end">
          <Button
            variant="faded"
            color="slate"
            :label="$t('HANDOFF_SUMMARY.CANCEL')"
            @click="closeTransferModal"
          />
          <Button
            color="blue"
            :label="$t('HANDOFF_SUMMARY.CONFIRM_TRANSFER')"
            :disabled="transferModal.loading"
            @click="confirmTransfer(true)"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>
