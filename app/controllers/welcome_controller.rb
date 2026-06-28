class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :ping]

  def index
  end

  def ping
    render plain: "#{Rails.application.class.module_parent_name} #{Rails::VERSION::STRING}"
  end
end
