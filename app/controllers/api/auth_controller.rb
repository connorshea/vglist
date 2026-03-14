module Api
  class AuthController < ApplicationController
    skip_before_action :sign_out_banned_users, only: [:sign_in]
    skip_after_action :verify_authorized

    def sign_in
      user = User.find_by(email: params[:email])

      if user&.valid_password?(params[:password])
        if user.banned?
          render json: { error: "Your account has been banned." }, status: :forbidden
          return
        end

        unless user.confirmed?
          render json: { error: "You must confirm your email address before signing in." }, status: :unauthorized
          return
        end

        token = generate_jwt(user)
        render json: {
          token: token,
          user: {
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            slug: user.slug
          }
        }
      else
        render json: { error: "Invalid email or password." }, status: :unauthorized
      end
    end

    def sign_up
      user = User.new(sign_up_params)

      if user.save
        # User needs to confirm their email before they can sign in.
        render json: {
          message: "Account created successfully. Please check your email to confirm your account."
        }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def me
      if current_user
        render json: {
          user: {
            id: current_user.id,
            username: current_user.username,
            email: current_user.email,
            role: current_user.role,
            slug: current_user.slug
          }
        }
      else
        render json: { error: "Not authenticated." }, status: :unauthorized
      end
    end

    private

    def sign_up_params
      params.permit(:username, :email, :password, :password_confirmation)
    end

    def generate_jwt(user)
      payload = {
        user_id: user.id,
        exp: 30.days.from_now.to_i,
        iat: Time.current.to_i
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    end
  end
end
