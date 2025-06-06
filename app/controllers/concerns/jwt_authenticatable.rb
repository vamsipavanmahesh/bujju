module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    
    unless token
      return render json: { error: 'Missing authorization token' }, status: :unauthorized
    end

    unless ENV['JWT_SECRET_KEY'].present?
      Rails.logger.error 'JWT secret key not configured'
      return render json: { error: 'Authentication service unavailable' }, status: :internal_server_error
    end

    begin
      decoded_payload = JWT.decode(token, ENV['JWT_SECRET_KEY'], true, { algorithm: 'HS256' })[0]
      
      # Validate required fields in payload
      unless decoded_payload['user_id'].present?
        Rails.logger.error 'JWT payload missing user_id'
        return render json: { error: 'Invalid token format' }, status: :unauthorized
      end

      # Check token expiration (additional safety check)
      if decoded_payload['exp'] && decoded_payload['exp'] < Time.current.to_i
        return render json: { error: 'Token expired' }, status: :unauthorized
      end

      @current_user = User.find(decoded_payload['user_id'])
      
      # Optional: Check if user is still active/enabled
      unless @current_user.active?
        Rails.logger.warn "Inactive user attempted access: #{@current_user.email}"
        return render json: { error: 'Account inactive' }, status: :unauthorized
      end

    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      render json: { error: 'Invalid token' }, status: :unauthorized
      
    rescue JWT::ExpiredSignature
      render json: { error: 'Token expired' }, status: :unauthorized
      
    rescue JWT::InvalidIssuerError, JWT::InvalidAudError, JWT::InvalidSubError => e
      Rails.logger.error "JWT validation error: #{e.message}"
      render json: { error: 'Invalid token' }, status: :unauthorized
      
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "User not found for token with user_id: #{decoded_payload&.dig('user_id')}"
      render json: { error: 'User not found' }, status: :unauthorized
      
    rescue StandardError => e
      Rails.logger.error "Authentication error: #{e.class} - #{e.message}"
      render json: { error: 'Authentication failed' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def current_user_id
    @current_user&.id
  end

  # Helper method to check if user is authenticated without raising errors
  def user_signed_in?
    @current_user.present?
  end

  # Method to skip authentication for specific actions
  def skip_authentication
    skip_before_action :authenticate_user!
  end

  private

  def extract_token_from_header
    header = request.headers['Authorization']
    return nil unless header.present?
    
    # Handle both "Bearer token" and "token" formats
    if header.match(/\ABearer\s+(.+)\z/i)
      $1
    elsif header.match(/\A[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\z/)
      # Direct JWT token format
      header
    else
      # Try splitting by space and taking last part (backward compatibility)
      parts = header.split(' ')
      parts.length == 2 ? parts.last : nil
    end
  end
end
