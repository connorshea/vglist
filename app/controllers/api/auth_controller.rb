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

        token = JwtService.encode(user)
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
        render json: { errors: user.errors.full_messages }, status: :unprocessable_content
      end
    end

    def me
      user = current_user || jwt_user
      if user
        render json: {
          user: {
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            slug: user.slug
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

    # Decode JWT from Authorization header for the /me endpoint.
    def jwt_user
      auth_header = request.headers['Authorization']
      return nil unless auth_header&.start_with?('Bearer ')

      token = auth_header.sub(/^Bearer\s+/i, '')
      decoded = JwtService.decode(token)
      User.find(decoded.first['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      nil
    end
  end
end
