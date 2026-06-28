class MediaController < ApplicationController
  def create
    media = Media.find_or_create_from_url(params[:url], added_by: current_user)
    share = Share.create!(
      from_user: current_user,
      to_user: current_user,
      media: media
    )
    redirect_to share_path(share), status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to dashboard_path, alert: e.message, status: :see_other
  rescue URI::InvalidURIError
    redirect_to dashboard_path, alert: "That doesn't look like a valid URL.", status: :see_other
  end
end
