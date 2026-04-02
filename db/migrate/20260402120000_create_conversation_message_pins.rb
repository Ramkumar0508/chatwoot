# frozen_string_literal: true

class CreateConversationMessagePins < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_message_pins do |t|
      t.integer :account_id, null: false
      t.integer :conversation_id, null: false
      t.integer :message_id, null: false
      t.integer :pinned_by_id
      t.datetime :pinned_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    # Custom index names: default Rails names exceed PostgreSQL's 63-character identifier limit.
    add_index :conversation_message_pins, %i[conversation_id message_id], unique: true,
                                                                          name: 'idx_conv_message_pins_on_conv_id_and_msg_id'
    add_index :conversation_message_pins, :conversation_id, name: 'idx_conv_message_pins_on_conv_id'

    add_foreign_key :conversation_message_pins, :accounts, column: :account_id
    add_foreign_key :conversation_message_pins, :conversations, column: :conversation_id
    add_foreign_key :conversation_message_pins, :messages, column: :message_id
    # pinned_by_id is optional. ON DELETE NULLIFY matches User-side associations that use
    # dependent: :nullify for agent references; db/schema.rb lists few explicit FKs, so this
    # documents and enforces behavior at the DB layer when a user row is removed.
    add_foreign_key :conversation_message_pins, :users, column: :pinned_by_id, on_delete: :nullify
  end
end
