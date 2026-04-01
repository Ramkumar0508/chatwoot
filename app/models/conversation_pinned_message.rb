# == Schema Information
#
# Table name: conversation_pinned_messages
#
#  id              :bigint           not null, primary key
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  message_id      :bigint           not null
#  pinned_by_id    :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_conversation_pinned_messages_on_account_and_conversation  (account_id,conversation_id)
#  index_conversation_pinned_messages_on_conv_and_message          (conversation_id,message_id) UNIQUE
#
class ConversationPinnedMessage < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :message
  belongs_to :pinned_by, class_name: 'User', optional: true

  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :message_id, presence: true
  validates :message_id, uniqueness: { scope: :conversation_id }
  validate :message_belongs_to_conversation
  validate :account_matches_conversation

  scope :for_conversation, ->(conversation) { where(conversation_id: conversation.id) }

  private

  def message_belongs_to_conversation
    return if message.blank? || conversation.blank?
    return if message.conversation_id == conversation.id

    errors.add(:message_id, 'must belong to the conversation')
  end

  def account_matches_conversation
    return if account.blank? || conversation.blank?
    return if account_id == conversation.account_id

    errors.add(:account_id, 'must match conversation account')
  end
end
