class ListItemsController < ApplicationController
  before_action :set_list_item

  def update
    if params[:status] == "watched"
      @list_item.share&.mark_watched!
      @list_item.update!(status: "watched", watched_at: Time.current) unless @list_item.share
    end
    redirect_to dashboard_path, status: :see_other, notice: "Marked as watched."
  end

  def destroy
    @list_item.destroy!
    redirect_to dashboard_path, status: :see_other, notice: "Removed from list."
  end

  private

  def set_list_item
    list = current_user.lists.find(params[:list_id])
    @list_item = list.list_items.find(params[:id])
  end
end
