class SharesController < ApplicationController
  before_action :set_share

  def show
  end

  def metadata_status
    render json: {fetched: @share.media.metadata_fetched?}
  end

  private

  def set_share
    @share = current_user.received_shares.find(params[:id])
  end
end
