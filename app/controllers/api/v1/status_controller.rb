module Api
  module V1
    class StatusController < ApplicationController
      skip_before_action :authenticate_user!

      def show
        render json: {status: "OK", message: "API is running"}
      end
    end
  end
end
