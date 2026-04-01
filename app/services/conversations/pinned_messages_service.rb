class Conversations::PinnedMessagesService
  MAX_PINS = 20

  def initialize(conversation, user)
    @conversation = conversation
    @user = user
  end

  def list
    pins = ConversationPinnedMessage
           .includes(message: [:attachments, { sender: { avatar_attachment: :blob } }])
           .where(conversation_id: @conversation.id)
           .order(created_at: :asc)

    has_unavailable = pins.any? { |pin| message_deleted?(pin.message) }
    visible = pins.reject { |pin| message_deleted?(pin.message) }

    { visible_pins: visible, has_unavailable_pins: has_unavailable }
  end

  def pin(message_id)
    message = @conversation.messages.find_by(id: message_id)
    return message_not_found unless message

    existing = find_pin(message.id)
    return { existing: true, record: existing } if existing

    return limit_reached if at_pin_limit?

    { record: create_pin_record!(message) }
  rescue ActiveRecord::RecordNotUnique
    existing = find_pin(message_id)
    return message_not_found unless existing

    { existing: true, record: existing }
  rescue ActiveRecord::RecordInvalid => e
    { error: e.record.errors.full_messages.join(', ') }
  end

  def unpin(message_id)
    pin = find_pin(message_id)
    pin&.destroy
    :ok
  end

  private

  def find_pin(message_id)
    ConversationPinnedMessage.find_by(conversation_id: @conversation.id, message_id: message_id)
  end

  def message_not_found
    { error: I18n.t('errors.pinned_messages.message_not_found') }
  end

  def limit_reached
    { error: I18n.t('errors.pinned_messages.limit_reached') }
  end

  def at_pin_limit?
    ConversationPinnedMessage.where(conversation_id: @conversation.id).count >= MAX_PINS
  end

  def create_pin_record!(message)
    ConversationPinnedMessage.create!(
      account_id: @conversation.account_id,
      conversation_id: @conversation.id,
      message_id: message.id,
      pinned_by_id: user_id_for_pin
    )
  end

  def message_deleted?(message)
    message.content_attributes&.dig(:deleted) == true ||
      message.content_attributes&.dig('deleted') == true
  end

  def user_id_for_pin
    @user.is_a?(User) ? @user.id : nil
  end
end
