module Api
  class HealthController < ApplicationController
    skip_before_action :sign_out_banned_users
    skip_after_action :verify_authorized

    def show
      render json: { status: "ok" }
    end
  end
end
