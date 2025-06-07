module Api
  module V1
    class AuthController < ApplicationController
      include JwtAuthenticatable

      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!, only: [ :google_sign_in ]

      def google_sign_in
        # Validate token presence
        begin
          auth_params = params.require(:auth)
        rescue ActionController::ParameterMissing
          return render json: { error: "Missing auth parameter" }, status: :bad_request
        end

        token = auth_params[:id_token]
        unless token.present?
          return render json: { error: "Missing ID token" }, status: :bad_request
        end

        # Validate Google client ID is configured
        unless ENV["GOOGLE_CLIENT_ID"].present?
          Rails.logger.error "Google Client ID not configured"
          return render json: { error: "Authentication service unavailable" }, status: :internal_server_error
        end

        validator = GoogleIDToken::Validator.new

        begin
          # Validate the Google ID token
          payload = validator.check(token, ENV["GOOGLE_CLIENT_ID"])

          # Validate required fields are present
          unless payload["sub"].present? && payload["email"].present? && payload["name"].present?
            Rails.logger.error "Invalid Google token payload: missing required fields"
            return render json: { error: "Invalid token payload" }, status: :unauthorized
          end

          # Check if email is verified by Google
          unless payload["email_verified"]
            Rails.logger.warn "Unverified email attempted sign in: #{payload['email']}"
            return render json: { error: "Email not verified with Google" }, status: :unauthorized
          end

          # Find or create user
          user = User.from_google_token!(payload)

          # Generate JWT token
          token = generate_jwt_token(user)

          Rails.logger.info "Successful Google sign in for user: #{user.email}"

          render json: {
            token: token,
            user: {
              id: user.id,
              email: user.email,
              name: user.name,
              avatar_url: user.avatar_url
            }
          }, status: :ok

        rescue GoogleIDToken::ValidationError => e
          Rails.logger.error "Google token validation failed: #{e.message}"
          render json: { error: "Invalid or expired token" }, status: :unauthorized

        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "User creation/update failed: #{e.record.errors.full_messages.join(', ')}"
          render json: {
            error: "User validation failed",
            details: e.record.errors.full_messages
          }, status: :unprocessable_entity

        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.error "Database constraint violation: #{e.message}"
          render json: { error: "User creation failed due to duplicate data" }, status: :conflict

        rescue JWT::EncodeError => e
          Rails.logger.error "JWT encoding failed: #{e.message}"
          render json: { error: "Token generation failed" }, status: :internal_server_error

        rescue StandardError => e
          Rails.logger.error "Unexpected error during Google sign in: #{e.class} - #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: "Authentication failed" }, status: :internal_server_error
        end
      end

      # Method to verify and decode JWT tokens (for other controllers to use)
      def verify_jwt_token(token)
        begin
          decoded = JWT.decode(token, ENV["JWT_SECRET_KEY"], true, { algorithm: "HS256" })
          payload = decoded.first

          # Check if token is expired (extra safety check)
          if payload["exp"] && payload["exp"] < Time.current.to_i
            return { error: "Token expired" }
          end

          user = User.find_by(id: payload["user_id"])
          return { error: "User not found" } unless user

          { user: user }

        rescue JWT::ExpiredSignature
          { error: "Token expired" }
        rescue JWT::DecodeError => e
          Rails.logger.error "JWT decode failed: #{e.message}"
          { error: "Invalid token" }
        rescue StandardError => e
          Rails.logger.error "Token verification failed: #{e.message}"
          { error: "Token verification failed" }
        end
      end

      private

      def token_params
        params.require(:auth).permit(:id_token)
      end

      def generate_jwt_token(user)
        # Validate JWT secret is configured
        unless ENV["JWT_SECRET_KEY"].present?
          raise JWT::EncodeError, "JWT secret key not configured"
        end

        # Validate user object
        unless user&.persisted? && user.id.present?
          raise ArgumentError, "Invalid user object for token generation"
        end

        payload = {
          user_id: user.id,
          email: user.email, # Include email for easier debugging/logging
          iat: Time.current.to_i, # Issued at time
          exp: 2.years.from_now.to_i # Expiration time
        }

        JWT.encode(payload, ENV["JWT_SECRET_KEY"], "HS256")
      end
    end
  end
end
