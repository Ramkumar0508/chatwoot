class Api::V1::Accounts::Conversations::PinnedMessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :authorize_pin_access!

  def index
    result = Conversations::PinnedMessagesService.new(@conversation, Current.user).list
    @pinned_messages = result[:visible_pins]
    @has_unavailable_pins = result[:has_unavailable_pins]
  end

  def create
    result = Conversations::PinnedMessagesService.new(@conversation, Current.user).pin(pin_params[:message_id])
    if result[:error]
      render_could_not_create_error(result[:error])
      return
    end

    @pinned_message = result[:record]
    if result[:existing]
      render :create, status: :ok
    else
      render :create, status: :created
    end
  end

  def destroy
    Conversations::PinnedMessagesService.new(@conversation, Current.user).unpin(params[:message_id])
    render json: { success: true }
  end

  private

  def pin_params
    params.permit(:message_id)
  end

  def authorize_pin_access!
    authorize @conversation, :modify_message_pins?
  end
end
