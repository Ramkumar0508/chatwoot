class MessageFinder
  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def conversation_messages
    @conversation.messages.includes(:attachments, :sender, sender: { avatar_attachment: [:blob] })
  end

  def messages
    return conversation_messages if @params[:filter_internal_messages].blank?

    conversation_messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def current_messages
    if @params[:around_message_id].present?
      messages_around(@params[:around_message_id].to_i)
    elsif @params[:after].present? && @params[:before].present?
      messages_between(@params[:after].to_i, @params[:before].to_i)
    elsif @params[:before].present?
      messages_before(@params[:before].to_i)
    elsif @params[:after].present?
      messages_after(@params[:after].to_i)
    else
      messages_latest
    end
  end

  def messages_around(message_id)
    before_limit = bounded_limit(@params[:before_limit], default: 20, max: 100)
    after_limit = bounded_limit(@params[:after_limit], default: 20, max: 100)

    anchor = messages.find(message_id)

    before_messages = messages.reorder('created_at desc').where('id < ?', anchor.id).limit(before_limit).reverse
    after_messages = messages.reorder('created_at asc').where('id > ?', anchor.id).limit(after_limit)

    before_messages + [anchor] + after_messages
  end

  def bounded_limit(value, default:, max:)
    int_value = value.to_i
    int_value = default if int_value <= 0
    [int_value, max].min
  end

  def messages_after(after_id)
    messages.reorder('created_at asc').where('id > ?', after_id).limit(100)
  end

  def messages_before(before_id)
    messages.reorder('created_at desc').where('id < ?', before_id).limit(20).reverse
  end

  def messages_between(after_id, before_id)
    messages.reorder('created_at asc').where('id >= ? AND id < ?', after_id, before_id).limit(1000)
  end

  def messages_latest
    messages.reorder('created_at desc').limit(20).reverse
  end
end
