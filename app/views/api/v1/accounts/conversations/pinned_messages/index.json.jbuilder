json.payload do
  json.pinned_messages do
    json.array! @pinned_messages do |pinned_message|
      json.partial! 'api/v1/accounts/conversations/pinned_messages/pinned_message', pinned_message: pinned_message
    end
  end
  json.has_unavailable_pins @has_unavailable_pins
end
