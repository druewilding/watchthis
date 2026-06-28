module Api
  module V1
    class StatusController < ApplicationController
      def show
        render json: {status: "OK", message: "API is running"}
      end
    end
  end
end
