class SharesController < ApplicationController
  before_action :set_share, only: [:show, :metadata_status]

  def show
  end

  def create
    media = Media.find(share_params[:media_id])
    to_user = current_user.friends.find(share_params[:to_user_id])
    Share.create!(
      from_user: current_user,
      to_user: to_user,
      media: media,
      message: share_params[:message]
    )
    redirect_to dashboard_path, notice: "Shared with #{to_user.name_or_email}!", status: :see_other
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Friend not found.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to dashboard_path, alert: e.message, status: :see_other
  end

  def metadata_status
    render json: {fetched: @share.media.metadata_fetched?}
  end

  private

  def set_share
    @share = current_user.received_shares.find(params[:id])
  end

  def share_params
    params.require(:share).permit(:media_id, :to_user_id, :message)
  end
end
