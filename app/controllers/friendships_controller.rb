class FriendshipsController < ApplicationController
  def index
    @incoming_requests = current_user.incoming_friend_requests
    @outgoing_requests = current_user.outgoing_friend_requests
    @friends = current_user.friends
  end

  def create
    email = params[:email].to_s.strip.downcase
    friend = User.find_by(email: email)

    if friend.nil?
      redirect_to friendships_path, alert: "No account found with that email address.", status: :see_other
    elsif friend == current_user
      redirect_to friendships_path, alert: "You can't add yourself.", status: :see_other
    elsif Friendship.between(current_user, friend)
      redirect_to friendships_path, alert: "You're already connected (or have a pending request).", status: :see_other
    else
      Friendship.create!(user: current_user, friend: friend)
      redirect_to friendships_path, notice: "Friend request sent to #{friend.name_or_email}.", status: :see_other
    end
  end

  def update
    friendship = Friendship.pending.find_by!(friend: current_user, id: params[:id])
    friendship.update!(status: "accepted")
    redirect_to friendships_path, notice: "You're now connected with #{friendship.user.name_or_email}.", status: :see_other
  rescue ActiveRecord::RecordNotFound
    redirect_to friendships_path, alert: "Request not found.", status: :see_other
  end

  def destroy
    friendship = Friendship.involving(current_user).find(params[:id])
    friendship.destroy!
    redirect_to friendships_path, notice: "Connection removed.", status: :see_other
  rescue ActiveRecord::RecordNotFound
    redirect_to friendships_path, alert: "Not found.", status: :see_other
  end
end
