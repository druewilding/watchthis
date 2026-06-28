class DashboardController < ApplicationController
  def index
    @inbox_items = current_user.inbox&.list_items&.includes(:media, :share)&.order(created_at: :desc) || []
  end
end
