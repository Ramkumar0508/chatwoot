json.id pinned_message.id
json.message_id pinned_message.message_id
json.conversation_id pinned_message.conversation.display_id
json.created_at pinned_message.created_at.to_i
json.pinned_by_id pinned_message.pinned_by_id
json.message do
  json.partial! 'api/v1/models/message', message: pinned_message.message
end
