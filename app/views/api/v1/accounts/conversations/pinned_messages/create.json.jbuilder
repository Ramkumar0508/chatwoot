json.payload do
  json.partial! 'api/v1/accounts/conversations/pinned_messages/pinned_message', pinned_message: @pinned_message
end
