# frozen_string_literal: true

class Captain::HandoffSummaryService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    return limited_context_response if limited_context?

    result = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('handoff_summary') },
        { role: 'user', content: conversation.to_llm_text(include_contact_details: false) }
      ]
    )

    return { summary: nil, error: result[:error] } if result[:error].present?

    { summary: result[:message] }
  end

  private

  def event_name
    'handoff_summary'
  end

  def limited_context?
    return true if conversation.blank?

    customer_message_count = conversation.messages
                                         .where(sender_type: 'Contact')
                                         .where.not(message_type: [:activity, :template])
                                         .count

    customer_message_count.zero?
  end

  def limited_context_response
    { summary: nil, error: I18n.t('conversations.handoff_summary.limited_context') }
  end
end
