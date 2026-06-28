class SharesController < ApplicationController
  before_action :set_share

  def show
  end

  private

  def set_share
    @share = current_user.received_shares.find(params[:id])
  end
end
