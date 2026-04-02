# == Schema Information
#
# Table name: conversation_message_pins
#
#  id              :bigint           not null, primary key
#  account_id      :integer          not null
#  conversation_id :integer          not null
#  message_id      :integer          not null
#  pinned_by_id    :integer
#  pinned_at       :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  idx_conv_message_pins_on_conv_id               (conversation_id)
#  idx_conv_message_pins_on_conv_id_and_msg_id    (conversation_id,message_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (message_id => messages.id)
#  fk_rails_...  (pinned_by_id => users.id) ON DELETE => nullify
#
class ConversationMessagePin < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :message
  belongs_to :pinned_by, class_name: 'User', optional: true, inverse_of: :conversation_message_pins

  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :message_id, presence: true
end
