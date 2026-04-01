import * as types from '../mutation-types';
import ConversationAPI from '../../api/conversations';

const state = {
  records: {},
  uiFlags: {},
};

export const getters = {
  getPinnedMessageIds: $state => conversationId =>
    $state.records[Number(conversationId)]?.pinnedMessageIds || [],
  isMessagePinned: ($state, storeGetters) => (conversationId, messageId) =>
    storeGetters
      .getPinnedMessageIds(conversationId)
      .includes(Number(messageId)),
  getPinnedMessages: $state => conversationId =>
    $state.records[Number(conversationId)]?.pinnedMessages || [],
  getHasUnavailablePins: $state => conversationId =>
    !!$state.records[Number(conversationId)]?.hasUnavailablePins,
  isPinnedAccessDenied: $state => conversationId =>
    !!$state.records[Number(conversationId)]?.accessDenied,
};

export const actions = {
  fetch: async ({ commit }, conversationId) => {
    const id = Number(conversationId);
    commit(types.default.SET_PINNED_MESSAGES_UI_FLAG, {
      conversationId: id,
      isFetching: true,
    });
    try {
      const { data } = await ConversationAPI.getPinnedMessages(conversationId);
      const payload = data.payload || {};
      const pinnedMessages = payload.pinned_messages || [];
      const pinnedMessageIds = pinnedMessages.map(pm => pm.message_id);
      commit(types.default.SET_PINNED_MESSAGES_RECORD, {
        conversationId: id,
        pinnedMessages,
        pinnedMessageIds,
        hasUnavailablePins: payload.has_unavailable_pins || false,
        accessDenied: false,
      });
    } catch (error) {
      const status = error.response?.status;
      if (status === 401 || status === 403) {
        commit(types.default.SET_PINNED_MESSAGES_RECORD, {
          conversationId: id,
          pinnedMessages: [],
          pinnedMessageIds: [],
          hasUnavailablePins: false,
          accessDenied: true,
        });
      }
    } finally {
      commit(types.default.SET_PINNED_MESSAGES_UI_FLAG, {
        conversationId: id,
        isFetching: false,
      });
    }
  },

  pin: async ({ dispatch }, { conversationId, messageId }) => {
    await ConversationAPI.pinMessage(conversationId, messageId);
    await dispatch('fetch', conversationId);
  },

  unpin: async ({ dispatch }, { conversationId, messageId }) => {
    await ConversationAPI.unpinMessage(conversationId, messageId);
    await dispatch('fetch', conversationId);
  },

  clear({ commit }) {
    commit(types.default.CLEAR_PINNED_MESSAGES);
  },
};

export const mutations = {
  [types.default.SET_PINNED_MESSAGES_RECORD]($state, data) {
    const {
      conversationId,
      pinnedMessages,
      pinnedMessageIds,
      hasUnavailablePins,
      accessDenied,
    } = data;
    $state.records = {
      ...$state.records,
      [conversationId]: {
        pinnedMessages,
        pinnedMessageIds,
        hasUnavailablePins,
        accessDenied,
      },
    };
  },
  [types.default.SET_PINNED_MESSAGES_UI_FLAG](
    $state,
    { conversationId, isFetching }
  ) {
    $state.uiFlags = {
      ...$state.uiFlags,
      [conversationId]: {
        ...($state.uiFlags[conversationId] || {}),
        isFetching,
      },
    };
  },
  [types.default.CLEAR_PINNED_MESSAGES]($state) {
    $state.records = {};
    $state.uiFlags = {};
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
