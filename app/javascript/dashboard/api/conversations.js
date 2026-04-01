/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  getPinnedMessages(conversationId) {
    return axios.get(`${this.url}/${conversationId}/pinned_messages`);
  }

  pinMessage(conversationId, messageId) {
    return axios.post(`${this.url}/${conversationId}/pinned_messages`, {
      message_id: messageId,
    });
  }

  unpinMessage(conversationId, messageId) {
    return axios.delete(
      `${this.url}/${conversationId}/pinned_messages/${messageId}`
    );
  }
}

export default new ConversationApi();
