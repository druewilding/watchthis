class WelcomeController < ApplicationController
  def index
  end

  def ping
    render plain: "#{Rails.application.class.module_parent_name} #{Rails::VERSION::STRING}"
  end
end
