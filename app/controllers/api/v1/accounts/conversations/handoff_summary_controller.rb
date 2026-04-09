# frozen_string_literal: true

class Api::V1::Accounts::Conversations::HandoffSummaryController < Api::V1::Accounts::Conversations::BaseController
  def create
    result = Captain::HandoffSummaryService.new(
      account: Current.account,
      conversation_display_id: @conversation.display_id
    ).perform

    if result[:error].present?
      render json: { summary: result[:summary], error: result[:error] }, status: :ok
    else
      render json: { summary: result[:summary] }
    end
  end
end
