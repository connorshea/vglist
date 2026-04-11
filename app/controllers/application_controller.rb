# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization

  # If the user has been banned, sign them out.
  before_action :sign_out_banned_users
  # Send context with error messages to Sentry.
  before_action :set_sentry_context
  # Set PaperTrail whodunnit to the current user.
  before_action :set_paper_trail_whodunnit

  # Make sure pundit is implemented on everything, except index pages since
  # those should be accessible without an authorization.
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # Sign out the current user if they've been banned.
  def sign_out_banned_users
    return unless current_user&.banned?

    sign_out
    render json: { error: "Your account has been banned." }, status: :forbidden
  end

  private

  def user_not_authorized
    render json: { error: "You are not authorized to perform this action." }, status: :forbidden
  end

  # Send user id and username to Sentry on-error.
  def set_sentry_context
    Sentry.set_user(id: current_user&.id, username: current_user&.username)
  end

  # Set whodunnit to the user's username.
  def user_for_paper_trail
    current_user&.username
  end

  # Set whodunnit_id to the user's numeric ID.
  def info_for_paper_trail
    { whodunnit_id: current_user&.id }
  end
end
