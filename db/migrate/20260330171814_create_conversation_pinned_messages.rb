class CreateConversationPinnedMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_pinned_messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.references :pinned_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :conversation_pinned_messages,
              [:conversation_id, :message_id],
              unique: true,
              name: 'index_conversation_pinned_messages_on_conv_and_message'
    add_index :conversation_pinned_messages,
              [:account_id, :conversation_id],
              name: 'index_conversation_pinned_messages_on_account_and_conversation'
  end
end
