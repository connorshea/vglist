# frozen_string_literal: true

module Api
  # Uploads a new avatar for the signed-in user. The SPA crops the image to a
  # square in the browser and posts it here as multipart form data.
  #
  # This is a REST endpoint rather than a GraphQL mutation because
  # graphql-request can't send multipart bodies, and ActiveStorage direct
  # uploads are disabled (see config/routes.rb). It authenticates with the
  # same JWT bearer token the SPA uses for GraphQL.
  class AvatarsController < ApplicationController
    # The Disk service (development and test) needs the request host to build
    # the returned avatar URL.
    include ActiveStorage::SetCurrent

    before_action :require_current_user

    def create
      authorize current_user, :update?

      file = params[:avatar]
      unless file.is_a?(ActionDispatch::Http::UploadedFile)
        render json: { errors: ["No avatar image was uploaded."] }, status: :unprocessable_content
        return
      end

      current_user.avatar = file

      if current_user.save
        # Resized right away rather than in the background (see
        # ReadyVariant), so the response has the new avatar at its proper size.
        render json: { avatar_url: current_user.avatar.variant(:large).processed.url }, status: :created
      else
        errors = current_user.errors.full_messages_for(:avatar).presence || current_user.errors.full_messages
        render json: { errors: errors }, status: :unprocessable_content
      end
    end

    private

    def require_current_user
      render json: { error: "Not authenticated." }, status: :unauthorized if current_user.nil?
    end
  end
end
